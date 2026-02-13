from fastapi import APIRouter
from app.api.v1.endpoints import students, attendance, auth, departments, courses, faculties, reports

api_router = APIRouter()

api_router.include_router(auth.router, tags=["auth"])
api_router.include_router(students.router, tags=["students"])
api_router.include_router(attendance.router, tags=["attendance"])
api_router.include_router(departments.router, prefix="/departments", tags=["departments"])
api_router.include_router(courses.router, prefix="/courses", tags=["courses"])
api_router.include_router(faculties.router, prefix="/faculties", tags=["faculties"])
api_router.include_router(reports.router, prefix="/reports", tags=["reports"])
