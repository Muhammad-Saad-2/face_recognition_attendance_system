from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.api import deps
from app.core.database import get_session
from app.models.course import Course, CourseCreate, CourseRead
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=List[CourseRead])
def read_courses(
    session: Session = Depends(get_session),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve courses.
    """
    courses = session.exec(select(Course).offset(skip).limit(limit)).all()
    return courses

@router.post("/", response_model=CourseRead)
def create_course(
    *,
    session: Session = Depends(get_session),
    course_in: CourseCreate,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new course.
    """
    if current_user.role not in ["admin", "faculty"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    course = Course.from_orm(course_in)
    session.add(course)
    session.commit()
    session.refresh(course)
    return course
