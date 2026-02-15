import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("POSTGRESQL_URL").replace("postgres://", "postgresql://")
engine = create_engine(DATABASE_URL)

def run_migration():
    print("🔄 Backfilling 'faculty_id' with 'DEPT-####' format...")
    with engine.connect() as conn:
        try:
            # Fetch all faculties with their department codes
            query = text("""
                SELECT f.id, f.name, d.code 
                FROM faculty f
                JOIN department d ON f.department_id = d.id
                ORDER BY d.code, f.id
            """)
            result = conn.execute(query).fetchall()
            
            dept_counters = {} # Track serial per department
            
            for row in result:
                f_id, name, dept_code = row
                
                if dept_code not in dept_counters:
                    dept_counters[dept_code] = 1
                
                serial = dept_counters[dept_code]
                new_faculty_id = f"{dept_code}-{serial:04d}"
                
                # Update the faculty record
                conn.execute(
                    text('UPDATE faculty SET faculty_id = :fid WHERE id = :id'),
                    {"fid": new_faculty_id, "id": f_id}
                )
                print(f"✅ Updated {name} -> {new_faculty_id}")
                
                dept_counters[dept_code] += 1
            
            conn.commit()
            print("🚀 Backfill complete!")

        except Exception as e:
            print(f"⚠️ Error: {e}")

if __name__ == "__main__":
    run_migration()
