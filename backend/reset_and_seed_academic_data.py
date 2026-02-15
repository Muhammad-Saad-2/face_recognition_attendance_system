from sqlmodel import Session, select
from sqlalchemy import text
from app.core.database import engine
from app.models.department import Department
from app.models.program import Program
from app.models.faculty import Faculty
from app.models.student import Student
from app.models.course import Course
from app.models.attendance import Attendance
from sqlalchemy.exc import IntegrityError

# Re-use the seeding logic
from seed_full_academic_data import seed_data as run_seeding

def reset_and_seed():
    print("⚠️  STARTING FULL ACADEMIC DATA RESET AND RESEED ⚠️")
    
    with Session(engine) as session:
        # Delete in order of dependencies (Children first)
        
        # 1. Delete Attendance (depends on Student)
        # 2. Delete Student (depends on Program, Department)
        # 3. Delete Course (depends on Faculty, Department)
        # 4. Delete Faculty (depends on Department)
        # 5. Delete Program (depends on Department)
        # 6. Delete Department
        
        try:
            print("🗑️  Deleting existing data...")
            
            # Use raw SQL for speed and to avoid fetching objects
            # Disable triggers if needed, but standard delete should work if order is correct
            
            session.exec(text("DELETE FROM attendance"))
            print("   - Deleted Attendance")
            
            session.exec(text("DELETE FROM student"))
            print("   - Deleted Students")
            
            session.exec(text("DELETE FROM course"))
            print("   - Deleted Courses")
            
            session.exec(text("DELETE FROM faculty"))
            print("   - Deleted Faculty")
            
            session.exec(text("DELETE FROM program"))
            print("   - Deleted Programs")
            
            session.exec(text("DELETE FROM department"))
            print("   - Deleted Departments")
            
            session.commit()
            print("✅ Data wiped successfully.")
            
        except IntegrityError as e:
            session.rollback()
            print(f"❌ Error deleting data. Foreign key constraint? {e}")
            return
        except Exception as e:
            session.rollback()
            print(f"❌ Unexpected error: {e}")
            return

    # Now run the seeding function
    print("\n🌱 Starting Seeding...")
    run_seeding()
    print("\n🚀 RESET AND RE-SEED COMPLETE!")

if __name__ == "__main__":
    reset_and_seed()
