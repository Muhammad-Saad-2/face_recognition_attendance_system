import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("POSTGRESQL_URL").replace("postgres://", "postgresql://")
engine = create_engine(DATABASE_URL)

def run_migration():
    print("🔄 Adding 'unique_id' column to 'program' table...")
    with engine.connect() as conn:
        try:
            # 1. Add column
            conn.execute(text('ALTER TABLE "program" ADD COLUMN unique_id VARCHAR;'))
            conn.commit()
            print("✅ 'unique_id' column added.")

            # 2. Populate existing rows
            print("🔢 Populating 'unique_id' for existing programs...")
            
            # Fetch all existing program IDs
            result = conn.execute(text('SELECT id FROM "program" ORDER BY id'))
            prog_ids = [row[0] for row in result]
            
            start_id = 20001
            for p_id in prog_ids:
                new_unique_id = str(start_id)
                conn.execute(text('UPDATE "program" SET unique_id = :uid WHERE id = :pid'), 
                             {"uid": new_unique_id, "pid": p_id})
                start_id += 1
            
            conn.commit()
            print(f"✅ Populated {len(prog_ids)} programs with unique IDs starting from 20001.")

            # 3. Add constraint (optional but good practice)
            try:
                conn.execute(text('CREATE UNIQUE INDEX ix_program_unique_id ON "program" (unique_id);'))
                conn.commit()
                print("✅ Unique index created on 'unique_id'.")
            except Exception as e:
                print(f"⚠️ Index creation skipped/failed: {e}")

        except Exception as e:
            print(f"⚠️ Error: {e}")
            print("Note: If column already exists, this is expected.")

if __name__ == "__main__":
    run_migration()
