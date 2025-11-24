from fastapi import APIRouter
from app.api.v1.endpoints import students, attendance

api_router = APIRouter()

api_router.include_router(students.router, tags=["students"])
api_router.include_router(attendance.router, tags=["attendance"])
