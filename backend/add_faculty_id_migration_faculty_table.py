import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("POSTGRESQL_URL").replace("postgres://", "postgresql://")
engine = create_engine(DATABASE_URL)

def run_migration():
    print("🔄 Adding 'faculty_id' column to 'faculty' table...")
    with engine.connect() as conn:
        try:
            conn.execute(text('ALTER TABLE "faculty" ADD COLUMN faculty_id VARCHAR;'))
            conn.commit()
            print("✅ 'faculty_id' column added successfully.")
        except Exception as e:
            print(f"⚠️ Error: {e}")
            print("Note: If the column already exists, this error is expected.")

if __name__ == "__main__":
    run_migration()
