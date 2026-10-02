# pyright: reportMissingImports=false
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from database import get_connection
from datetime import date

app = FastAPI(title="App API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

BARS = [
    "Дачный пр., 17к2",
    "Клочков пер., 6",
    "Коломяжский пр., 15к2",
    "пл. Стачек, 7",
    "ул. Марата, 7",
    "Владимирский пр., 17",
    "ул. Садовая, 35",
    "ул. Садовая, 41",
    "пр. Просвещения, 25",
    "Средний пр. В.О., 28",
    "пр. Чернышевского, 11",
    "ул. Бухарестская, 74",
    "2-я Красноармейская, 9/3",
    "Невский пр., 8",
    "пр. Науки, 23к2",
    "Гаккелевская ул., 34",
]


class UsersData(BaseModel):
    username: str
    email: EmailStr
    password: str
    employee_role: str
    bar: str


class LoginData(BaseModel):
    email: EmailStr
    password: str


class AchievementData(BaseModel):
    user_id: int
    type: str
    value: float


@app.get("/")
def root():
    return {"message": "API is working"}


@app.get("/bars")
def get_bars():
    return BARS


@app.post("/register")
def register_user(data: UsersData):
    if data.bar not in BARS:
        raise HTTPException(status_code=400, detail="Неизвестный бар")

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO users (username, email, password_hash, employee_role, bar)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (data.username, data.email, data.password, data.employee_role, data.bar),
        )
        conn.commit()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        cur.close()
        conn.close()

    return {"message": "User registered successfully"}


@app.post("/login")
def login_user(data: LoginData):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT id, username, email, password_hash, employee_role, bar
            FROM users
            WHERE email = %s
            """,
            (str(data.email).lower(),),
        )
        user = cur.fetchone()
        if user is None:
            raise HTTPException(status_code=401, detail="Invalid Credentials")

        if isinstance(user, dict):
            stored = user["password_hash"]
            payload = {
                "id": user["id"],
                "username": user["username"],
                "email": user["email"],
                "employee_role": user["employee_role"],
                "bar": user.get("bar"),
            }
        else:
            stored = user[3]
            payload = {
                "id": user[0],
                "username": user[1],
                "email": user[2],
                "employee_role": user[4],
                "bar": user[5] if len(user) > 5 else None,
            }

        if stored != data.password:
            raise HTTPException(status_code=401, detail="Invalid Credentials")

        return {
            "message": "Вход выполнен",
            "user": payload,
        }
    finally:
        cur.close()
        conn.close()


@app.get("/employees")
def get_employees():
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT id, username, email, employee_role, bar
            FROM users
            ORDER BY id
            """
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
                    "bar": row[4] if len(row) > 4 else None,
                })
        return {"employees": employees}
    finally:
        cur.close()
        conn.close()


@app.get("/shifts")
def get_shifts():
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT s.id, s.shift_date, s.start_time, s.end_time, s.role, u.username
            FROM shifts s
            JOIN users u ON u.id = s.user_id
            ORDER BY s.shift_date, s.start_time
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
                    "time": f"{row['start_time']} – {row['end_time']}",
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
    finally:
        cur.close()
        conn.close()


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
                courses.append({
                    "id": row["id"],
                    "title": row["title"],
                    "category": row["category"],
                    "lessons_total": row["lessons_total"],
                    "lessons_done": row["lessons_done"],
                })
            else:
                courses.append({
                    "id": row[0],
                    "title": row[1],
                    "category": row[2],
                    "lessons_total": row[3],
                    "lessons_done": row[4],
                })
        return {"courses": courses}
    finally:
        cur.close()
        conn.close()

class PeriodData(BaseModel):
    title: str
    start_date: date
    end_date: date
    created_by: int


class WishData(BaseModel):
    period_id: int
    user_id: int
    wish_date: date
    wish_type: str
    comment: str | None = None


@app.get("/periods/current")
def get_current_period():
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT id, title, start_date, end_date, status
            FROM schedule_periods
            WHERE status != 'published'
            ORDER BY id DESC
            LIMIT 1
            """
        )
        row = cur.fetchone()
        if row is None:
            return {"period": None}
        if isinstance(row, dict):
            return {"period": {
                "id": row["id"],
                "title": row["title"],
                "start_date": str(row["start_date"]),
                "end_date": str(row["end_date"]),
                "status": row["status"],
            }}
        return {"period": {
            "id": row[0],
            "title": row[1],
            "start_date": str(row[2]),
            "end_date": str(row[3]),
            "status": row[4],
        }}
    finally:
        cur.close()
        conn.close()


@app.post("/wishes")
def save_wish(data: WishData):
    if data.wish_type not in ("want", "can", "off"):
        raise HTTPException(status_code=400, detail="Unknown wish_type")

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO shift_wishes (period_id, user_id, wish_date, wish_type, comment)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (period_id, user_id, wish_date)
            DO UPDATE SET wish_type = EXCLUDED.wish_type, comment = EXCLUDED.comment
            """,
            (data.period_id, data.user_id, data.wish_date, data.wish_type, data.comment),
        )
        conn.commit()
        return {"ok": True}
    finally:
        cur.close()
        conn.close()


@app.get("/wishes")
def get_wishes(period_id: int, user_id: int | None = None):
    conn = get_connection()
    cur = conn.cursor()
    try:
        if user_id is None:
            cur.execute(
                """
                SELECT w.id, w.user_id, u.username, w.wish_date, w.wish_type, w.comment
                FROM shift_wishes w
                JOIN users u ON u.id = w.user_id
                WHERE w.period_id = %s
                ORDER BY w.wish_date, u.username
                """,
                (period_id,),
            )
        else:
            cur.execute(
                """
                SELECT w.id, w.user_id, u.username, w.wish_date, w.wish_type, w.comment
                FROM shift_wishes w
                JOIN users u ON u.id = w.user_id
                WHERE w.period_id = %s AND w.user_id = %s
                ORDER BY w.wish_date
                """,
                (period_id, user_id),
            )
        rows = cur.fetchall()
        wishes = []
        for row in rows:
            if isinstance(row, dict):
                wishes.append({
                    "id": row["id"],
                    "user_id": row["user_id"],
                    "username": row["username"],
                    "wish_date": str(row["wish_date"]),
                    "wish_type": row["wish_type"],
                    "comment": row["comment"],
                })
            else:
                wishes.append({
                    "id": row[0],
                    "user_id": row[1],
                    "username": row[2],
                    "wish_date": str(row[3]),
                    "wish_type": row[4],
                    "comment": row[5],
                })
        return {"wishes": wishes}
    finally:
        cur.close()
        conn.close()

class DraftShiftData(BaseModel):
    period_id: int
    user_id: int
    shift_date: date
    start_time: str
    end_time: str
    role: str


@app.post("/draft-shifts")
def add_draft_shift(data: DraftShiftData):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO draft_shifts
              (period_id, user_id, shift_date, start_time, end_time, role)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                data.period_id,
                data.user_id,
                data.shift_date,
                data.start_time,
                data.end_time,
                data.role,
            ),
        )
        conn.commit()
        return {"ok": True}
    finally:
        cur.close()
        conn.close()


@app.get("/draft-shifts")
def get_draft_shifts(period_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT d.id, d.user_id, u.username, d.shift_date,
                   d.start_time, d.end_time, d.role
            FROM draft_shifts d
            JOIN users u ON u.id = d.user_id
            WHERE d.period_id = %s
            ORDER BY d.shift_date, d.start_time
            """,
            (period_id,),
        )
        rows = cur.fetchall()
        items = []
        for row in rows:
            if isinstance(row, dict):
                items.append({
                    "id": row["id"],
                    "user_id": row["user_id"],
                    "username": row["username"],
                    "shift_date": str(row["shift_date"]),
                    "time": f"{row['start_time']} – {row['end_time']}",
                    "role": row["role"],
                })
            else:
                items.append({
                    "id": row[0],
                    "user_id": row[1],
                    "username": row[2],
                    "shift_date": str(row[3]),
                    "time": f"{row[4]} – {row[5]}",
                    "role": row[6],
                })
        return {"draft_shifts": items}
    finally:
        cur.close()
        conn.close()


@app.post("/periods/{period_id}/send-to-director")
def send_to_director(period_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            UPDATE schedule_periods
            SET status = 'director_review'
            WHERE id = %s
            """,
            (period_id,),
        )
        conn.commit()
        return {"ok": True, "status": "director_review"}
    finally:
        cur.close()
        conn.close()

@app.post("/periods/{period_id}/publish")
def publish_period(period_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO shifts (user_id, shift_date, start_time, end_time, role)
            SELECT user_id, shift_date, start_time, end_time, role
            FROM draft_shifts
            WHERE period_id = %s
            """,
            (period_id,),
        )
        cur.execute(
            """
            UPDATE schedule_periods
            SET status = 'published',
                published_at = NOW()
            WHERE id = %s
            """,
            (period_id,),
        )
        conn.commit()
        return {"ok": True, "status": "published"}
    finally:
        cur.close()
        conn.close()