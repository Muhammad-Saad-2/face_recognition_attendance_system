from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from fastapi.responses import FileResponse
from sqlmodel import Session, select
import shutil
import os
import time
import cv2
import base64
from openpyxl import Workbook
from tempfile import NamedTemporaryFile
from typing import Any, List
from app.api import deps
from app.core.database import get_session
from app.models.attendance import Attendance, AttendanceCreate, AttendanceRead, AttendanceUpdate
from app.models.user import User
from app.api.permissions import can_manage_attendance
from app.models.student import Student
from app.services.face_recognition_service import FaceRecognitionService
from app.services.attendance_service import AttendanceService


router = APIRouter()
face_service = FaceRecognitionService()
attendance_service = AttendanceService()

@router.post("/mark")
async def mark_attendance(
    image: UploadFile = File(...),
    session: Session = Depends(get_session)
):
    # 1. Save uploaded image temporarily
    timestamp = int(time.time())
    debug_filename = f"debug_{timestamp}_{image.filename}"
    os.makedirs("debug_images", exist_ok=True)
    debug_path = os.path.join("debug_images", debug_filename)
    
    # Save for debugging
    with open(debug_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)
    
    # Reset file pointer for processing
    image.file.seek(0)
    
    temp_path = f"temp_{image.filename}"
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)
    
    # 2. Detect Faces
    try:
        recognized_faces = face_service.recognize_faces(session, temp_path)
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        raise HTTPException(status_code=500, detail=f"Error recognizing faces: {str(e)}")
    
    # Read image for drawing boxes
    img = cv2.imread(temp_path)
    
    # Clean up temp file
    if os.path.exists(temp_path):
        os.remove(temp_path)

    if not recognized_faces:
        return {"message": "No registered students recognized"}

    recognized_students = []

    for face_data in recognized_faces:
        student_id = face_data["student_id"]
        facial_area = face_data["facial_area"]
        
        # Draw bounding box
        if facial_area:
            x = int(facial_area['x'])
            y = int(facial_area['y'])
            w = int(facial_area['w'])
            h = int(facial_area['h'])
            cv2.rectangle(img, (x, y), (x+w, y+h), (0, 255, 0), 2)
            
            # Add label
            cv2.putText(img, student_id, (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

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

    # Encode image to base64
    _, buffer = cv2.imencode('.jpg', img)
    img_base64 = base64.b64encode(buffer).decode('utf-8')

    return {
        "message": "Attendance marked",
        "recognized_count": len(recognized_students),
        "students": recognized_students,
        "image_with_box": img_base64
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
        
        ws.column_dimensions['A'].width = 20
        ws.column_dimensions['B'].width = 15
        ws.column_dimensions['C'].width = 15
        ws.column_dimensions['D'].width = 20
        ws.column_dimensions['E'].width = 15
        ws.column_dimensions['F'].width = 15
        ws.column_dimensions['G'].width = 10

        for record in records:
            ws.append([
                record.name,
                record.student_id,
                record.program,
                record.major,
                str(record.date),
                str(record.time).split('.')[0], # Remove microseconds if present
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

@router.post("/manual", response_model=AttendanceRead, dependencies=[Depends(can_manage_attendance)])
def create_attendance_manual(
    *,
    session: Session = Depends(get_session),
    attendance_in: AttendanceCreate,
) -> Any:
    """
    Manually mark attendance for a student (Admin only).
    """
    statement = select(Student).where(Student.student_id == attendance_in.student_id)
    student = session.exec(statement).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    attendance = Attendance(
        student_id=attendance_in.student_id,
        student_db_id=student.id,
        course_id=attendance_in.course_id,
        name=student.name,
        program=student.program,
        major=student.major,
        date=attendance_in.date,
        time=attendance_in.time,
        status=attendance_in.status
    )
    session.add(attendance)
    session.commit()
    session.refresh(attendance)
    return attendance

@router.put("/{attendance_id}", response_model=AttendanceRead, dependencies=[Depends(can_manage_attendance)])
def update_attendance(
    *,
    session: Session = Depends(get_session),
    attendance_id: int,
    attendance_in: AttendanceUpdate,
) -> Any:
    """
    Update an attendance record (Admin only).
    """
    record = session.get(Attendance, attendance_id)
    if not record:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    update_data = attendance_in.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(record, key, value)
    
    session.add(record)
    session.commit()
    session.refresh(record)
    return record

@router.delete("/{attendance_id}", dependencies=[Depends(can_manage_attendance)])
def delete_attendance(
    *,
    session: Session = Depends(get_session),
    attendance_id: int,
) -> Any:
    """
    Delete an attendance record (Admin only).
    """
    record = session.get(Attendance, attendance_id)
    if not record:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    session.delete(record)
    session.commit()
    return {"message": "Attendance record deleted"}
