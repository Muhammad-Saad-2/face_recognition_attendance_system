from fastapi import APIRouter, Depends, HTTPException, Form, File, UploadFile
from sqlmodel import Session, select
from typing import List
from app.core.database import get_session
from app.models.student import Student
from app.services.face_recognition_service import FaceRecognitionService

router = APIRouter()
face_service = FaceRecognitionService()

@router.post("/register_student")
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
