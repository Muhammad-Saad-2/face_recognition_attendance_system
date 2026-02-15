import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("POSTGRESQL_URL").replace("postgres://", "postgresql://")
engine = create_engine(DATABASE_URL)

def run_migration():
    print("🔄 Adding 'unique_id' column to 'department' table...")
    with engine.connect() as conn:
        try:
            # 1. Add column
            conn.execute(text('ALTER TABLE "department" ADD COLUMN unique_id VARCHAR;'))
            conn.commit()
            print("✅ 'unique_id' column added.")

            # 2. Populate existing rows
            print("🔢 Populating 'unique_id' for existing departments...")
            
            # Fetch all existing department IDs
            result = conn.execute(text('SELECT id FROM "department" ORDER BY id'))
            dept_ids = [row[0] for row in result]
            
            start_id = 1001
            for d_id in dept_ids:
                new_unique_id = str(start_id)
                conn.execute(text('UPDATE "department" SET unique_id = :uid WHERE id = :did'), 
                             {"uid": new_unique_id, "did": d_id})
                start_id += 1
            
            conn.commit()
            print(f"✅ Populated {len(dept_ids)} departments with unique IDs starting from 1001.")

            # 3. Add constraint (optional but good practice)
            # Note: This might fail if there are duplicates, but we just ensured uniqueness.
            try:
                conn.execute(text('CREATE UNIQUE INDEX ix_department_unique_id ON "department" (unique_id);'))
                conn.commit()
                print("✅ Unique index created on 'unique_id'.")
            except Exception as e:
                print(f"⚠️ Index creation skipped/failed: {e}")

        except Exception as e:
            print(f"⚠️ Error: {e}")
            print("Note: If column already exists, this is expected.")

if __name__ == "__main__":
    run_migration()
