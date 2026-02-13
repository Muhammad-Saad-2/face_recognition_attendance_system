from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.api import deps
from app.core.database import get_session
from app.models.department import Department, DepartmentCreate, DepartmentRead
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=List[DepartmentRead])
def read_departments(
    session: Session = Depends(get_session),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve departments.
    """
    departments = session.exec(select(Department).offset(skip).limit(limit)).all()
    return departments

@router.post("/", response_model=DepartmentRead)
def create_department(
    *,
    session: Session = Depends(get_session),
    department_in: DepartmentCreate,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new department.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    department = Department.from_orm(department_in)
    session.add(department)
    session.commit()
    session.refresh(department)
    return department
