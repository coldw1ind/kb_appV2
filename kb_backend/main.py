import pydantic
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from database import get_connection

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

    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO users (username, email, password_hash, employee_role, bar) VALUES (%s, %s, %s, %s, %s)",
            (data.username, data.email, data.password, data.employee_role, data.bar),
        )
        conn.commit()
        cur.close()
        conn.close()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

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


