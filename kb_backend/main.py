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


