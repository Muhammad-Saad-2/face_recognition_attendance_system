from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import date, time

class Attendance(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    student_id: str = Field(index=True)
    name: str
    program: str
    major: str
    date: date
    time: time
    status: str = "Present"
