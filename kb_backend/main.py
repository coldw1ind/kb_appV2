import pydantic
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from database import get_connection

app = FastAPI(title="App API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#HelloWorld
class UsersData(BaseModel):
    username: str
    email: EmailStr
    password: str
    employee_role: str

@app.get("/")
def root():
    return {"message": "API is working"}

@app.post("/register")
def register_user(data: UsersData):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        "INSERT INTO users (username, email, password_hash, employee_role) VALUES (%s, %s, %s, %s)",
        (data.username, data.email, data.password, data.employee_role)
    )

    conn.commit()
    cur.close()
    conn.close()

    return {"message": "User registered successfully"}

class LoginData(BaseModel):
    email: EmailStr
    password: str

@app.post("/login")
def login_user(data: LoginData):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        "SELECT id, email, password_hash FROM users WHERE email = %s",
        (str(data.email).lower(),)
    )

    user = cur.fetchone()
    
    stored_password = user["password_hash"] if isinstance(user, dict) else user[2]

    if stored_password != data.password:
        raise HTTPException(status_code=401, detail="Invalid Credentials")

    return {
        "message":"Вход выполнен"
    }

    
    cur.close()
    conn.close()

@app.get("/employees")
def get_employees():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        "SELECT id, username, email, employee_role FROM users ORDER BY id"
    )

    rows = cur.fetchall()
    employees = []
    for row in rows:
        if isinstance(row, dict):
            employees.append(row)
        else:
            employees.append({
                "id": row[0],
                "username": row[1],
                "email": row[2],
                "employee_role": row[3],
            })
    return {"employees": employees}
    cur.close()
    conn.close()

@app.get("/shifts")
def get_shifts():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT s.id, s.shift_date, s.start_time, s.end_time, s.role, u.username
        FROM shifts s JOIN users u ON u.id = s.user_id ORDER BY s.shift_date, s.start_time
        """
    )
    rows = cur.fetchall()
    shifts = []
    for row in rows:
        if isinstance(row, dict):
            d = row["shift_date"]
            shifts.append({
                "id": row["id"],
                "date": d.isoformat() if hasattr(d, "isoformat") else str(d),
                "time": f"{row['start_time']} - {row['end_time']}",
                "role": row["role"],
                "name": row["username"],
            })
        else:
            d = row[1]
            shifts.append({
                "id": row[0],
                "date": d.isoformat() if hasattr(d, "isoformat") else str(d),
                "time": f"{row[2]} – {row[3]}",
                "role": row[4],
                "name": row[5],
            })
    return {"shifts": shifts}

    cur.close()
    conn.close()

class AchievementData(BaseModel):
    user_id: int
    type: str
    value: float


@app.get("/achievements")
def get_achievements(user_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT id, user_id, type, value, created_at
            FROM achievements
            WHERE user_id = %s
            ORDER BY created_at DESC
            """,
            (user_id,),
        )
        rows = cur.fetchall()
        items = []
        for row in rows:
            if isinstance(row, dict):
                created = row["created_at"]
                items.append({
                    "id": row["id"],
                    "user_id": row["user_id"],
                    "type": row["type"],
                    "value": row["value"],
                    "created_at": created.isoformat() if hasattr(created, "isoformat") else str(created),
                })
            else:
                created = row[4]
                items.append({
                    "id": row[0],
                    "user_id": row[1],
                    "type": row[2],
                    "value": row[3],
                    "created_at": created.isoformat() if hasattr(created, "isoformat") else str(created),
                })
        return {"achievements": items}
    finally:
        cur.close()
        conn.close()


@app.post("/achievements")
def add_achievement(data: AchievementData):
    if data.type not in ("sales_percent", "revenue", "tips"):
        raise HTTPException(status_code=400, detail="Unknown type")
    if data.value <= 0:
        raise HTTPException(status_code=400, detail="Value must be > 0")
    if data.type == "sales_percent" and data.value > 100:
        raise HTTPException(status_code=400, detail="Percent too high")

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO achievements (user_id, type, value)
            VALUES (%s, %s, %s)
            RETURNING id, created_at
            """,
            (data.user_id, data.type, data.value),
        )
        row = cur.fetchone()
        conn.commit()
        new_id = row["id"] if isinstance(row, dict) else row[0]
        created = row["created_at"] if isinstance(row, dict) else row[1]
        return {
            "id": new_id,
            "created_at": created.isoformat() if hasattr(created, "isoformat") else str(created),
        }
    finally:
        cur.close()
        conn.close()


@app.delete("/achievements/{achievement_id}")
def delete_achievement(achievement_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM achievements WHERE id = %s", (achievement_id,))
        conn.commit()
        return {"ok": True}
    finally:
        cur.close()
        conn.close()

@app.get("/courses")
def get_courses(user_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT
              c.id,
              c.title,
              c.category,
              c.lessons_total,
              COALESCE(p.lessons_done, 0) AS lessons_done
            FROM courses c
            LEFT JOIN course_progress p
              ON p.course_id = c.id AND p.user_id = %s
            ORDER BY c.sort_order, c.id
            """,
            (user_id,),
        )
        rows = cur.fetchall()
        courses = []
        for row in rows:
            if isinstance(row, dict):
                total = row["lessons_total"]
                done = row["lessons_done"]
                courses.append({
                    "id": row["id"],
                    "title": row["title"],
                    "category": row["category"],
                    "lessons_total": total,
                    "lessons_done": done,
                })
            else:
                total = row[3]
                done = row[4]
                courses.append({
                    "id": row[0],
                    "title": row[1],
                    "category": row[2],
                    "lessons_total": total,
                    "lessons_done": done,
                })
        return {"courses": courses}
    finally:
        cur.close()
        conn.close()