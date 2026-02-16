from sqlmodel import Session, text
from app.core.database import engine
from app.models.department import Department
from app.models.program import Program
from app.models.faculty import Faculty
from app.models.student import Student
from app.models.course import Course
from app.models.attendance import Attendance
# Re-use the seeding logic
from seed_full_academic_data import seed_data as run_seeding

def force_schema_reset():
    print("⚠️  FORCING SCHEMA RESET WITH RAW SQL ⚠️")
    
    with Session(engine) as session:
        # 1. Drop all tables
        print("🗑️  Dropping tables...")
        session.exec(text("DROP TABLE IF EXISTS attendance CASCADE"))
        session.exec(text("DROP TABLE IF EXISTS student CASCADE"))
        session.exec(text("DROP TABLE IF EXISTS course CASCADE"))
        session.exec(text("DROP TABLE IF EXISTS faculty CASCADE"))
        session.exec(text("DROP TABLE IF EXISTS program CASCADE"))
        session.exec(text("DROP TABLE IF EXISTS department CASCADE"))
        session.commit()

        # 2. Create tables manually with desired order
        print("🔨 Creating tables manually...")
        
        # Department
        session.exec(text("""
            CREATE TABLE department (
                id SERIAL PRIMARY KEY,
                name VARCHAR NOT NULL,
                code VARCHAR NOT NULL,
                unique_id VARCHAR
            );
            CREATE UNIQUE INDEX ix_department_name ON department (name);
            CREATE UNIQUE INDEX ix_department_code ON department (code);
            CREATE UNIQUE INDEX ix_department_unique_id ON department (unique_id);
        """))
        
        # Program
        session.exec(text("""
            CREATE TABLE program (
                id SERIAL PRIMARY KEY,
                name VARCHAR NOT NULL,
                code VARCHAR NOT NULL,
                unique_id VARCHAR,
                description VARCHAR,
                department_id VARCHAR REFERENCES department(unique_id)
            );
            CREATE UNIQUE INDEX ix_program_name ON program (name);
            CREATE UNIQUE INDEX ix_program_code ON program (code);
            CREATE UNIQUE INDEX ix_program_unique_id ON program (unique_id);
        """))

        # Faculty
        session.exec(text("""
            CREATE TABLE faculty (
                id SERIAL PRIMARY KEY,
                name VARCHAR NOT NULL,
                email VARCHAR NOT NULL,
                faculty_id VARCHAR,
                department_id VARCHAR REFERENCES department(unique_id)
            );
            CREATE INDEX ix_faculty_name ON faculty (name);
            CREATE UNIQUE INDEX ix_faculty_email ON faculty (email);
            CREATE INDEX ix_faculty_faculty_id ON faculty (faculty_id);
        """))
        
        # Re-create other tables using SQLModel metadata (automatic) 
        # But we need to make sure they don't try to recreate the ones we just made.
        # SQLModel `create_db_and_tables` would normally do this. 
        # Since we manually created the core ones, we can just run the standard create for the rest?
        # Actually, `create_db_and_tables` calls `SQLModel.metadata.create_all(engine)`.
        # SQLAlchemy checks existence before creating.
        
        session.commit()
        print("✅ Tables created with ID first.")

    # Now run standard create for the rest (Student, Course, Attendance, User)
    from app.core.database import create_db_and_tables
    create_db_and_tables()

    # Now run the seeding function
    print("\n🌱 Starting Seeding...")
    run_seeding()
    print("\n🚀 RESET AND RE-SEED COMPLETE!")

if __name__ == "__main__":
    force_schema_reset()
