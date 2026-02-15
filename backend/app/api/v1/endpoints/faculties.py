from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select

from app.core.database import get_session
from app.models.faculty import Faculty, FacultyCreate, FacultyRead, FacultyUpdate
from app.models.user import User
from app.api.permissions import can_manage_faculty

router = APIRouter()

@router.get("/", response_model=List[FacultyRead])
def read_faculty(
    session: Session = Depends(get_session),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve faculty members.
    """
    faculties = session.exec(select(Faculty).offset(skip).limit(limit)).all()
    return faculties

@router.get("/{faculty_id}", response_model=FacultyRead)
def read_faculty_by_id(
    faculty_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get faculty member by ID.
    """
    faculty = session.get(Faculty, faculty_id)
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")
    return faculty

@router.put("/{faculty_id}", response_model=Faculty, dependencies=[Depends(can_manage_faculty)])
async def update_faculty(faculty_id: int, faculty_data: FacultyUpdate, session: Session = Depends(get_session)):
    """
    Update a faculty member.
    """
    faculty = session.get(Faculty, faculty_id)
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty not found")
    
    update_data = faculty_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(faculty, key, value)
    
    session.add(faculty)
    session.commit()
    session.refresh(faculty)
    return faculty

@router.delete("/{faculty_id}", dependencies=[Depends(can_manage_faculty)])
async def delete_faculty(faculty_id: int, session: Session = Depends(get_session)):
    """
    Delete a faculty member.
    """
    faculty = session.get(Faculty, faculty_id)
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty member not found")
    
    session.delete(faculty)
    session.commit()
    return {"message": "Faculty member deleted"}

@router.post("/", response_model=FacultyRead)
def create_faculty(
    *,
    session: Session = Depends(get_session),
    faculty_in: FacultyCreate,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new faculty member.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    faculty = Faculty.from_orm(faculty_in)
    session.add(faculty)
    session.commit()
    session.refresh(faculty)
    return faculty
