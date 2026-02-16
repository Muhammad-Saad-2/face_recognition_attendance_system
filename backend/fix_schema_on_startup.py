from sqlalchemy import inspect, text
from sqlmodel import Session
from app.core.database import engine, create_db_and_tables
from seed_full_academic_data import seed_data

def fix_and_seed():
    print("🔧 Checking Database Schema state...")
    
    inspector = inspect(engine)
    
    # Check Course table
    if inspector.has_table("course"):
        columns = inspector.get_columns("course")
        dept_col = next((c for c in columns if c["name"] == "department_id"), None)
        
        if dept_col:
            # Check type. SQLAlchemy type can be Integer() or String() or VARCHAR(). 
            # We convert to string to check.
            col_type = str(dept_col["type"]).lower()
            print(f"🧐 Found Course.department_id type: {col_type}")
            
            if "int" in col_type:
                print("⚠️  Detected OLD Schema (Integer FK). Dropping Course table to force update...")
                with Session(engine) as session:
                    session.exec(text("DROP TABLE course CASCADE"))
                    session.commit()
                print("✅ Course table dropped.")
            else:
                print("✅ Schema looks correct (String FK).")
        else:
            print("⚠️  department_id column missing in Course table? Dropping to recreate...")
            with Session(engine) as session:
                session.exec(text("DROP TABLE course CASCADE"))
                session.commit()
    
    # Run creation (will recreate Course if dropped)
    create_db_and_tables()
    
    # Run Seeding
    seed_data()

if __name__ == "__main__":
    fix_and_seed()
