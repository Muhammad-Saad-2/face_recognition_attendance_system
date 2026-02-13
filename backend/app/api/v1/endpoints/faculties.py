from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.api import deps
from app.core.database import get_session
from app.models.faculty import Faculty, FacultyCreate, FacultyRead
from app.models.user import User

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
