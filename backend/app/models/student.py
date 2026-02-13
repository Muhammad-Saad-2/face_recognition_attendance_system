from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship
from sqlalchemy import Column, JSON
from datetime import datetime

class StudentBase(SQLModel):
    name: str
    student_id: str = Field(index=True, unique=True)
    program: str
    major: str
    department_id: Optional[int] = Field(default=None, foreign_key="department.id")

class Student(StudentBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    # Store encodings as a list of lists of floats
    encodings: List[List[float]] = Field(default=[], sa_column=Column(JSON))
    
    # Relationships
    department: Optional["Department"] = Relationship(back_populates="students")
    attendances: List["Attendance"] = Relationship(back_populates="student")

class StudentCreate(StudentBase):
    pass

class StudentRead(StudentBase):
    id: int
    created_at: datetime

