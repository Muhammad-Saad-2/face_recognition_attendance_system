from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship

class CourseBase(SQLModel):
    name: str = Field(index=True)
    code: str = Field(index=True, unique=True)
    faculty_id: Optional[int] = Field(default=None, foreign_key="faculty.id")

class Course(CourseBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    
    # Relationships
    faculty: Optional["Faculty"] = Relationship(back_populates="courses")
    attendances: List["Attendance"] = Relationship(back_populates="course")

class CourseCreate(CourseBase):
    pass

class CourseRead(CourseBase):
    id: int
