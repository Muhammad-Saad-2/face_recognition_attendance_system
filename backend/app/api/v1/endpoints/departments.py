from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.api import deps
from app.core.database import get_session
from app.models.department import Department, DepartmentCreate, DepartmentRead, DepartmentUpdate
from app.models.user import User
from app.api.permissions import can_manage_academic

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

@router.get("/{dept_id}", response_model=DepartmentRead)
def read_department(
    dept_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get department by ID.
    """
    department = session.get(Department, dept_id)
    if not department:
        raise HTTPException(status_code=404, detail="Department not found")
    return department

@router.put("/{dept_id}", response_model=DepartmentRead, dependencies=[Depends(can_manage_academic)])
def update_department(
    dept_id: int,
    department_in: DepartmentUpdate,
    session: Session = Depends(get_session),
) -> Any:
    """
    Update a department.
    """
    department = session.get(Department, dept_id)
    if not department:
        raise HTTPException(status_code=404, detail="Department not found")
    
    update_data = department_in.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(department, key, value)
    
    session.add(department)
    session.commit()
    session.refresh(department)
    return department

@router.delete("/{dept_id}", dependencies=[Depends(can_manage_academic)])
def delete_department(
    dept_id: int,
    session: Session = Depends(get_session),
) -> Any:
    """
    Delete a department.
    """
    department = session.get(Department, dept_id)
    if not department:
        raise HTTPException(status_code=404, detail="Department not found")
    
    session.delete(department)
    session.commit()
    return {"message": "Department deleted"}

@router.post("/", response_model=DepartmentRead, dependencies=[Depends(can_manage_academic)])
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
    
    # Auto-generate unique_id
    if not department_in.unique_id:
        # Find max unique_id that is a number
        all_ids = session.exec(select(Department.unique_id)).all()
        max_id = 1000
        for uid in all_ids:
            if uid and uid.isdigit():
                try:
                    uid_int = int(uid)
                    if uid_int > max_id:
                        max_id = uid_int
                except ValueError:
                    pass
        
        department_in.unique_id = str(max_id + 1)

    department = Department.from_orm(department_in)
    session.add(department)
    session.commit()
    session.refresh(department)
    return department
