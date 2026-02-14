import sys
import os
from sqlmodel import Session, select

# Add current directory to sys.path to ensure imports work
sys.path.append(os.getcwd())

from app.core.database import engine, create_db_and_tables
from app.models.user import User, UserRole
from app.core import security

def create_admin():
    print("--- Create Initial Admin Account ---")
    username = input("Enter admin username: ").strip()
    email = input("Enter admin email: ").strip()
    password = input("Enter admin password: ").strip()

    if not username or not email or not password:
        print("Error: Username, email, and password are required.")
        return

    # Ensure tables exist
    create_db_and_tables()

    with Session(engine) as session:
        # Check if user already exists
        statement = select(User).where(User.username == username)
        existing_user = session.exec(statement).first()
        if existing_user:
            print(f"Error: User '{username}' already exists.")
            return

        # Create admin user
        hashed_password = security.get_password_hash(password)
        admin_user = User(
            username=username,
            email=email,
            hashed_password=hashed_password,
            role=UserRole.ADMIN,
            is_active=True
        )
        
        session.add(admin_user)
        session.commit()
        print(f"Successfully created admin account: {username}")

if __name__ == "__main__":
    create_admin()
