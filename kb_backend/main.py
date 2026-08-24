import pydantic
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
from kb_backend.database import get_connection

app = FastAPI(title="App API")

class UsersData(BaseModel):
    username: str
    email: EmailStr
    password: str
    role: str

@app.post("/register")
def register_user(data: UsersData):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        "INSERT INTO users (username, email, password, role) VALUES (%s, %s, %s, %s)",
        (data.username, data.email, data.password, data.role)
    )

    conn.commit()
    cur.close()
    conn.close()

