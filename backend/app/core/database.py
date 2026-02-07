from sqlmodel import SQLModel, create_engine, Session
from app.core.config import settings

# Import models here to ensure they are registered with SQLModel.metadata
from app.models.student import Student
from app.models.attendance import Attendance

# pool_pre_ping=True helps recover from lost connections (e.g. SSL closed unexpectedly)
# pool_recycle=300 recycles connections every 5 minutes to prevent stale connections
engine = create_engine(
    settings.POSTGRESQL_URL, 
    echo=True, 
    pool_pre_ping=True, 
    pool_recycle=300
)

def get_session():
    with Session(engine) as session:
        yield session

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)
