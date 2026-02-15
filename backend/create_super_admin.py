from sqlmodel import Session, select
from app.core.database import engine
from app.models.user import User
from app.core.security import get_password_hash

def create_super_admin():
    print("--- Create Super Admin Account ---")
    try:
        username = "superadmin"
        email = "superadmin@example.com"
        password = "SuperAdmin124$"
    except Exception:
        pass
    
    # username = input("Enter super admin username (default: superadmin): ") or "superadmin"
    # email = input("Enter super admin email (default: superadmin@example.com): ") or "superadmin@example.com"
    # password = input("Enter super admin password: ")
    
    if not password:
        print("Password is required.")
        return

    with Session(engine) as session:
        # Check if user exists
        existing_user = session.exec(select(User).where(User.username == username)).first()
        if existing_user:
            print(f"User {username} already exists. Updating to Super Admin...")
            existing_user.is_super_admin = True
            existing_user.hashed_password = get_password_hash(password)
            session.add(existing_user)
            session.commit()
            print("Updated successfully.")
            return

        user = User(
            username=username,
            email=email,
            full_name="Super Administrator",
            hashed_password=get_password_hash(password),
            role="admin",
            is_super_admin=True
        )
        session.add(user)
        session.commit()
        print(f"Super Admin created: {username}")

if __name__ == "__main__":
    create_super_admin()
