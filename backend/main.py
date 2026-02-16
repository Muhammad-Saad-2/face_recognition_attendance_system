from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from app.core.config import settings
from app.core.database import create_db_and_tables
from app.api.v1.router import api_router

# Auto-seed data on startup
try:
    from fix_schema_on_startup import fix_and_seed
except ImportError:
    fix_and_seed = None

app = FastAPI(title=settings.PROJECT_NAME)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def on_startup():
    if fix_and_seed:
        print("🌱 Running schema check and auto-seeding...")
        fix_and_seed()
    else:
        create_db_and_tables()

@app.get("/")
def read_root():
    return {"status": "online", "message": "Face Recognition Attendance System API is running", "docs": "/docs"}

app.include_router(api_router, prefix=settings.API_V1_STR)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
