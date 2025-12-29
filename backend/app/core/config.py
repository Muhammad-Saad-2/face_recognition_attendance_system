import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = "Face Recognition Attendance System"
    API_V1_STR: str = "/api/v1"
    
    # Base Directory (backend/)
    BASE_DIR: Path = Path(__file__).resolve().parent.parent.parent
    
    # Database
    POSTGRESQL_URL: str = os.getenv("POSTGRESQL_URL")
    if POSTGRESQL_URL and POSTGRESQL_URL.startswith("postgres://"):
        POSTGRESQL_URL = POSTGRESQL_URL.replace("postgres://", "postgresql://", 1)
  
        
    # Files
    # Store data in a 'data' folder to keep root clean, or just in root as before
    # Using absolute paths ensures they work regardless of where uvicorn is run
    ENCODINGS_FILE: str = str(BASE_DIR / "encodings_vgg.pkl")
    ATTENDANCE_FILE: str = str(BASE_DIR / "attendance.xlsx")
    IMAGES_DIR: str = str(BASE_DIR / "images")

settings = Settings()
