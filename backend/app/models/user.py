from typing import Optional
from sqlmodel import Field, SQLModel
from enum import Enum

class UserRole(str, Enum):
    ADMIN = "admin"
    FACULTY = "faculty"
    STUDENT = "student"

class UserBase(SQLModel):
    username: str = Field(index=True, unique=True)
    email: str = Field(index=True, unique=True)
    full_name: str = Field(index=True)
    role: str = Field(default="admin")
    is_super_admin: bool = Field(default=False)
    is_active: bool = Field(default=True)

class User(UserBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    hashed_password: str

class UserCreate(UserBase):
    password: str

class UserRead(UserBase):
    id: int
