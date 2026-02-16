from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship

class FacultyBase(SQLModel):
    name: str = Field(index=True)
    email: str = Field(index=True, unique=True)
    faculty_id: Optional[str] = Field(default=None, index=True)
    department_id: Optional[int] = Field(default=None, foreign_key="department.id")

class Faculty(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    email: str = Field(index=True, unique=True)
    faculty_id: Optional[str] = Field(default=None, index=True)
    department_id: Optional[int] = Field(default=None, foreign_key="department.id")
    
    # Relationships
    department: Optional["Department"] = Relationship(back_populates="faculty")
    courses: List["Course"] = Relationship(back_populates="faculty")

class FacultyCreate(FacultyBase):
    pass

class FacultyUpdate(SQLModel):
    name: Optional[str] = None
    email: Optional[str] = None
    faculty_id: Optional[str] = None
    department_id: Optional[int] = None

class FacultyRead(FacultyBase):
    id: int
