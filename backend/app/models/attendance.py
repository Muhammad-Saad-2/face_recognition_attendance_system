from sqlmodel import SQLModel, Field, Relationship
from typing import Optional
from datetime import date, time

class Attendance(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    student_id: str = Field(index=True) # Mobile app sends this string ID
    
    # Real foreign keys for DB relationships
    student_db_id: Optional[int] = Field(default=None, foreign_key="student.id")
    course_id: Optional[int] = Field(default=None, foreign_key="course.id")
    
    name: str
    program: str
    major: str
    batch: str = Field(default="Unknown")
    date: date
    time: time
    status: str = "Present"
    
    # Relationships
    student: Optional["Student"] = Relationship(back_populates="attendances")
    course: Optional["Course"] = Relationship(back_populates="attendances")

class AttendanceCreate(SQLModel):
    student_id: str
    course_id: Optional[int] = None
    date: date
    time: time
    status: str = "Present"

class AttendanceUpdate(SQLModel):
    status: Optional[str] = None
    date: Optional[date] = None
    time: Optional[time] = None

class AttendanceRead(SQLModel):
    id: int
    student_id: str
    name: str
    program: str
    major: str
    date: date
    time: time
    status: str
