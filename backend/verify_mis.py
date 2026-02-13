import sys
from pathlib import Path

# Add backend to path
sys.path.append(str(Path(__file__).resolve().parent))

from app.core.database import create_db_and_tables, engine
from sqlmodel import Session, select
from app.models.student import Student
from app.models.attendance import Attendance
from app.models.department import Department
from app.models.course import Course
from app.models.faculty import Faculty
from app.models.user import User
from app.core.security import get_password_hash

def verify_setup():
    print("🚀 Starting verification...")
    
    # 1. Create tables
    print("🛠️ Creating tables...")
    create_db_and_tables()
    print("✅ Tables created successfully.")
    
    # 2. Add sample data
    with Session(engine) as session:
        # Check if admin already exists
        admin_stmt = select(User).where(User.username == "admin")
        if not session.exec(admin_stmt).first():
            print("👤 Creating admin user...")
            admin = User(
                username="admin",
                email="admin@example.com",
                role="admin",
                hashed_password=get_password_hash("admin123")
            )
            session.add(admin)
            session.commit()
            print("✅ Admin user created.")
        
        # Check if department exists
        dept_stmt = select(Department).where(Department.code == "CS")
        if not session.exec(dept_stmt).first():
            print("🏢 Creating sample department...")
            dept = Department(name="Computer Science", code="CS")
            session.add(dept)
            session.commit()
            session.refresh(dept)
            print(f"✅ Department created: {dept.name}")
            
    print("🏁 Verification complete!")

if __name__ == "__main__":
    verify_setup()
