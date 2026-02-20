import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("POSTGRESQL_URL", "").strip('"').strip("'")
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
engine = create_engine(DATABASE_URL)

def run_migration():
    print("🔄 Adding 'batch' column to 'student' table...")
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE student ADD COLUMN batch VARCHAR DEFAULT 'Unknown';"))
            conn.commit()
            print("✅ 'batch' column added to 'student' successfully.")
        except Exception as e:
            print(f"⚠️ Error: {e}")
            
    print("🔄 Adding 'batch' column to 'attendance' table...")
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE attendance ADD COLUMN batch VARCHAR DEFAULT 'Unknown';"))
            conn.commit()
            print("✅ 'batch' column added to 'attendance' successfully.")
        except Exception as e:
            print(f"⚠️ Error: {e}")

if __name__ == "__main__":
    run_migration()
