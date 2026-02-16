from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship

class DepartmentBase(SQLModel):
    name: str = Field(index=True, unique=True)
    code: str = Field(index=True, unique=True)
    unique_id: Optional[str] = Field(default=None, index=True, unique=True)

class Department(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True)
    code: str = Field(index=True, unique=True)
    unique_id: str = Field(index=True, unique=True)
    
    # Relationships
    students: List["Student"] = Relationship(back_populates="department")
    faculty: List["Faculty"] = Relationship(back_populates="department")
    programs: List["Program"] = Relationship(back_populates="department")
    courses: List["Course"] = Relationship(back_populates="department")

class DepartmentCreate(DepartmentBase):
    pass

class DepartmentUpdate(SQLModel):
    name: Optional[str] = None
    code: Optional[str] = None

class DepartmentRead(DepartmentBase):
    id: int
