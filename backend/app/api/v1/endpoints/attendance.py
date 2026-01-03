from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from fastapi.responses import FileResponse
from sqlmodel import Session, select
import shutil
import os
from openpyxl import Workbook
from tempfile import NamedTemporaryFile
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
        recognized_ids = face_service.recognize_faces(session, temp_path)
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
            attendance_service.log_attendance(session, student)
            # Explicitly convert to dict to ensure serialization works
            recognized_students.append({
                "name": student.name,
                "student_id": student.student_id,
                "program": student.program,
                "major": student.major
            })

    return {
        "message": "Attendance marked",
        "recognized_count": len(recognized_students),
        "students": recognized_students
    }

@router.get("/get_attendance_records")
async def get_attendance_records(session: Session = Depends(get_session)):
    try:
        records = attendance_service.get_attendance_records(session)
        return {"records": records}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching records: {str(e)}")

@router.get("/download_attendance")
async def download_attendance(session: Session = Depends(get_session)):
    try:
        records = attendance_service.get_attendance_records(session)
        
        wb = Workbook()
        ws = wb.active
        ws.title = "Attendance"
        ws.append(["Name", "Student ID", "Program", "Major", "Date", "Time", "Status"])
        
        for record in records:
            ws.append([
                record.name,
                record.student_id,
                record.program,
                record.major,
                record.date,
                record.time,
                record.status
            ])
            
        with NamedTemporaryFile(delete=False, suffix=".xlsx") as tmp:
            wb.save(tmp.name)
            tmp_path = tmp.name
            
        return FileResponse(
            tmp_path, 
            media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 
            filename=f"attendance_report_{os.urandom(4).hex()}.xlsx"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating report: {str(e)}")
