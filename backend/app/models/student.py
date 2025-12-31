from typing import Optional, List
from sqlmodel import Field, SQLModel
from sqlalchemy import Column, JSON
from datetime import datetime

class StudentBase(SQLModel):
    name: str
    student_id: str = Field(index=True, unique=True)
    program: str
    major: str

class Student(StudentBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    # Store encodings as a list of lists of floats
    encodings: List[List[float]] = Field(default=[], sa_column=Column(JSON))

class StudentCreate(StudentBase):
    pass

class StudentRead(StudentBase):
    id: int
    created_at: datetime

