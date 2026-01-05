from datetime import datetime, timezone, timedelta
from sqlmodel import Session, select
from app.models.student import Student
from app.models.attendance import Attendance

class AttendanceService:
    def log_attendance(self, session: Session, student: Student):
        # Use UTC+5 (Pakistan Standard Time)
        tz = timezone(timedelta(hours=5))
        now = datetime.now(tz)
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
