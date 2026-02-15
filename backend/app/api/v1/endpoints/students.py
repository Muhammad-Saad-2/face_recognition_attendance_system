import os
import shutil
from fastapi import APIRouter, Depends, HTTPException, Query, Form, File, UploadFile
from sqlmodel import Session, select
from typing import Any, List, Optional
from app.core.database import get_session
from app.models.student import Student, StudentRead, StudentUpdate
from app.api import deps
from app.api.deps import get_current_user
from app.api.permissions import can_manage_students
from app.services.face_recognition_service import FaceRecognitionService

router = APIRouter()
face_service = FaceRecognitionService()

@router.get("/", response_model=List[StudentRead])
def read_students(
    session: Session = Depends(get_session),
    skip: int = 0,
    limit: int = 100,
    current_user: Any = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve students.
    """
    students = session.exec(select(Student).offset(skip).limit(limit)).all()
    return students

@router.get("/{student_id}", response_model=StudentRead)
def read_student_by_id(
    student_id: str,
    session: Session = Depends(get_session),
    current_user: Any = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get student by student_id.
    """
    statement = select(Student).where(Student.student_id == student_id)
    student = session.exec(statement).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student

@router.put("/{student_id}", response_model=Student, dependencies=[Depends(can_manage_students)])
async def update_student(
    student_id: str,
    student_in: StudentUpdate,
    session: Session = Depends(get_session),
) -> Any:
    """
    Update a student.
    """
    statement = select(Student).where(Student.student_id == student_id)
    student = session.exec(statement).first()
    if not student:
        # Try finding by ID if not found by student_id
        try:
             s_id = int(student_id)
             student = session.get(Student, s_id)
        except:
             pass
        if not student:
             raise HTTPException(status_code=404, detail="Student not found")
    
    update_data = student_in.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(student, key, value)
    
    session.add(student)
    session.commit()
    session.refresh(student)
    return student

@router.delete("/{student_id}", dependencies=[Depends(can_manage_students)])
async def delete_student(
    student_id: str,
    session: Session = Depends(get_session),
) -> Any:
    """
    Delete a student.
    """
    statement = select(Student).where(Student.student_id == student_id)
    student = session.exec(statement).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Delete student's images directory
    if os.path.exists(face_service.images_dir):
        student_images_dir = os.path.join(face_service.images_dir, student_id)
        if os.path.exists(student_images_dir):
            shutil.rmtree(student_images_dir)

    session.delete(student)
    session.commit()
    return {"message": "Student deleted"}

@router.post("/register")
async def register_student(
    name: str = Form(...),
    student_id: str = Form(...),
    program: str = Form(...),
    major: str = Form(...),
    images: List[UploadFile] = File(...),
    session: Session = Depends(get_session)
):
    # 1. Check if student already exists in DB
    statement = select(Student).where(Student.student_id == student_id)
    existing_student = session.exec(statement).first()
    if existing_student:
        raise HTTPException(status_code=400, detail="Student ID already registered")

    # 2. Process Images & Get Encodings
    try:
        student_encodings = face_service.process_student_images(student_id, images)
    except Exception as e:
         raise HTTPException(status_code=500, detail=f"Error processing images: {str(e)}")
    
    if not student_encodings:
        raise HTTPException(status_code=400, detail="No faces detected in uploaded images")

    # 3. Create Student Object
    new_student = Student(name=name, student_id=student_id, program=program, major=major)

    # 4. Save encodings and student to DB
    face_service.add_student_encodings(session, new_student, student_encodings)

    return {"message": "Student registered successfully", "student": new_student}
