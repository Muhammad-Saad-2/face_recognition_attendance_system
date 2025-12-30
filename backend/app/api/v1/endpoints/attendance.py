from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from fastapi.responses import FileResponse
from sqlmodel import Session, select
import shutil
import os
from app.core.database import get_session
from app.models.student import Student
from app.services.face_recognition_service import FaceRecognitionService
from app.services.attendance_service import AttendanceService

router = APIRouter()
face_service = FaceRecognitionService()
attendance_service = AttendanceService()

@router.post("/mark_attendance")
async def mark_attendance(
    image: UploadFile = File(...),
    session: Session = Depends(get_session)
):
    # 1. Save uploaded image temporarily
    temp_path = f"temp_{image.filename}"
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)
    
    # 2. Detect Faces
    try:
        recognized_ids = face_service.recognize_faces(temp_path)
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        raise HTTPException(status_code=500, detail=f"Error recognizing faces: {str(e)}")
    
    # Clean up temp file
    if os.path.exists(temp_path):
        os.remove(temp_path)

    if not recognized_ids:
        return {"message": "No registered students recognized"}

    recognized_students = []

    for student_id in recognized_ids:
        # Fetch student details from DB
        statement = select(Student).where(Student.student_id == student_id)
        student = session.exec(statement).first()
        
        if student:
            attendance_service.log_attendance(student)
            recognized_students.append(student)

    return {
        "message": "Attendance marked",
        "recognized_count": len(recognized_students),
        "students": recognized_students
    }

@router.get("/get_attendance_records")
async def get_attendance_records():
    try:
        records = attendance_service.get_attendance_records()
        return {"records": records}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching records: {str(e)}")

@router.get("/download_attendance")
async def download_attendance():
    file_path = attendance_service.file_path
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Attendance file not found")
    return FileResponse(file_path, media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename="attendance.xlsx")
