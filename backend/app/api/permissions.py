from fastapi import HTTPException, Depends, status
from app.api.deps import get_current_user
from app.models.user import User
from app.models.admin_permission import AdminPermission
from sqlmodel import Session, select
from app.core.database import get_session

def check_permission(permission_name: str):
    def dependency(current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
        if current_user.is_super_admin:
            return True
        
        # Check AdminPermission
        statement = select(AdminPermission).where(AdminPermission.user_id == current_user.id)
        perm = session.exec(statement).first()
        
        if not perm:
             raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to perform this action."
            )
            
        if not getattr(perm, permission_name, False):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing permission: {permission_name}"
            )
        return True
    return dependency

# Specific permission dependencies
can_manage_students = check_permission("can_manage_students")
can_manage_faculty = check_permission("can_manage_faculty")
can_manage_courses = check_permission("can_manage_courses")
can_manage_attendance = check_permission("can_manage_attendance")
can_manage_academic = check_permission("can_manage_academic") # Depts, programs
