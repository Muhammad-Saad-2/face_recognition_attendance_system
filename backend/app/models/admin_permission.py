from sqlmodel import SQLModel, Field, Relationship
from typing import Optional

class AdminPermission(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    
    # Permission Flags
    can_manage_students: bool = Field(default=False)
    can_manage_faculty: bool = Field(default=False)
    can_manage_courses: bool = Field(default=False)
    can_manage_attendance: bool = Field(default=False)
    can_manage_academic: bool = Field(default=False) # Depts, Programs, Semesters

