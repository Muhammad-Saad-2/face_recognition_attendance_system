from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from datetime import date

from app.api import deps
from app.core.database import get_session
from app.models.attendance import Attendance
from app.models.user import User

router = APIRouter()

@router.get("/daily", response_model=List[Attendance])
def get_daily_report(
    *,
    session: Session = Depends(get_session),
    report_date: date = date.today(),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get attendance report for a specific date.
    """
    statement = select(Attendance).where(Attendance.date == report_date)
    results = session.exec(statement).all()
    return results

@router.get("/student/{student_id}", response_model=List[Attendance])
def get_student_report(
    *,
    session: Session = Depends(get_session),
    student_id: str,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get attendance report for a specific student.
    """
    # Permission check: Student can only see their own report
    if current_user.role == "student" and current_user.username != student_id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    statement = select(Attendance).where(Attendance.student_id == student_id)
    results = session.exec(statement).all()
    return results
