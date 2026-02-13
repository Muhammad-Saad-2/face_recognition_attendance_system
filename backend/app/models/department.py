from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship

class DepartmentBase(SQLModel):
    name: str = Field(index=True, unique=True)
    code: str = Field(index=True, unique=True)

class Department(DepartmentBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    
    # Relationships
    students: List["Student"] = Relationship(back_populates="department")
    faculty: List["Faculty"] = Relationship(back_populates="department")

class DepartmentCreate(DepartmentBase):
    pass

class DepartmentRead(DepartmentBase):
    id: int
