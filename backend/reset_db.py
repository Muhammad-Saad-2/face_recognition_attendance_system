from sqlmodel import SQLModel
from app.core.database import engine, create_db_and_tables
from app.models.student import Student  # Import models to ensure they are registered

def reset_database():
    print("WARNING: This will delete all data in the database.")
    confirmation = input("Are you sure you want to proceed? (yes/no): ")
    
    if confirmation.lower() == "yes":
        print("Dropping all tables...")
        SQLModel.metadata.drop_all(engine)
        print("Creating all tables...")
        create_db_and_tables()
        print("Database reset successfully.")
    else:
        print("Operation cancelled.")

if __name__ == "__main__":
    # Add current directory to sys.path to ensure imports work
    import sys
    import os
    sys.path.append(os.getcwd())
    
    reset_database()
