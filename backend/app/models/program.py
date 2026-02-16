from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship

class ProgramBase(SQLModel):
    name: str = Field(index=True, unique=True)
    code: str = Field(index=True, unique=True)
    unique_id: Optional[str] = Field(default=None, index=True, unique=True)
    description: Optional[str] = None
    department_id: Optional[str] = Field(default=None, foreign_key="department.unique_id")

class Program(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True)
    code: str = Field(index=True, unique=True)
    unique_id: Optional[str] = Field(default=None, index=True, unique=True)
    description: Optional[str] = None
    department_id: Optional[str] = Field(default=None, foreign_key="department.unique_id")
    
    # Relationships
    department: Optional["Department"] = Relationship(back_populates="programs")
    # courses: List["Course"] = Relationship(back_populates="program")

class ProgramCreate(ProgramBase):
    pass

class ProgramUpdate(SQLModel):
    name: Optional[str] = None
    code: Optional[str] = None
    description: Optional[str] = None
    department_id: Optional[int] = None

class ProgramRead(ProgramBase):
    id: int
