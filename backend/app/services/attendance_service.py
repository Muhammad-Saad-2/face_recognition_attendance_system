from datetime import datetime
from sqlmodel import Session, select
from app.models.student import Student
from app.models.attendance import Attendance

class AttendanceService:
    def log_attendance(self, session: Session, student: Student):
        now = datetime.now()
        attendance = Attendance(
            student_id=student.student_id,
            name=student.name,
            program=student.program,
            major=student.major,
            date=now.date(),
            time=now.time(),
            status="Present"
        )
        session.add(attendance)
        session.commit()
        session.refresh(attendance)
        return attendance

    def get_attendance_records(self, session: Session):
        statement = select(Attendance).order_by(Attendance.date.desc(), Attendance.time.desc())
        results = session.exec(statement).all()
        return results
