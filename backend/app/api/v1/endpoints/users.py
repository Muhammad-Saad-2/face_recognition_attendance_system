from typing import Any, List
from fastapi import APIRouter, Body, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlmodel import Session, select

from app.api import deps
from app.core.database import get_session
from app.core.security import get_password_hash
from app.models.user import User, UserCreate, UserRead, UserUpdate
from app.models.admin_permission import AdminPermission

router = APIRouter()

@router.get("/", response_model=List[User])
def read_users(
    session: Session = Depends(get_session),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve users. Only Super Admin can see all admins.
    """
    if not current_user.is_super_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    users = session.exec(select(User).where(User.role == "admin").offset(skip).limit(limit)).all()
    return users

@router.post("/", response_model=User)
def create_user(
    *,
    session: Session = Depends(get_session),
    user_in: UserCreate,
    permissions: AdminPermission = Body(None),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new user (admin). Only Super Admin can create admins.
    """
    if not current_user.is_super_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    user = session.exec(select(User).where(User.username == user_in.username)).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )
    
    user_data = user_in.dict(exclude={"password"})
    hashed_password = get_password_hash(user_in.password)
    user = User(**user_data, hashed_password=hashed_password, role="admin")
    session.add(user)
    session.commit()
    session.refresh(user)

    if permissions:
        permissions.user_id = user.id
        session.add(permissions)
        session.commit()
    else:
        # Create default permissions (all false)
        perm = AdminPermission(user_id=user.id)
        session.add(perm)
        session.commit()

    return user

@router.put("/{user_id}", response_model=User)
def update_user(
    *,
    session: Session = Depends(get_session),
    user_id: int,
    user_in: UserUpdate,
    permissions: AdminPermission = Body(None),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Update a user. Only Super Admin can update other admins.
    """
    if not current_user.is_super_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    update_data = user_in.dict(exclude_unset=True)
    if update_data.get("password"):
        update_data["hashed_password"] = get_password_hash(update_data["password"])
        del update_data["password"]
        
    for key, value in update_data.items():
        setattr(user, key, value)

    session.add(user)
    session.commit()
    session.refresh(user)

    if permissions:
        # Check if permission record exists
        existing_perm = session.exec(select(AdminPermission).where(AdminPermission.user_id == user.id)).first()
        if existing_perm:
            # Update
            perm_data = permissions.dict(exclude_unset=True)
            for k, v in perm_data.items():
                 if k != "id" and k != "user_id":
                    setattr(existing_perm, k, v)
            session.add(existing_perm)
        else:
            # Create
            permissions.user_id = user.id
            session.add(permissions)
        session.commit()

    return user

@router.delete("/{user_id}")
def delete_user(
    *,
    session: Session = Depends(get_session),
    user_id: int,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Delete a user. Only Super Admin can delete admins.
    """
    if not current_user.is_super_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")

    # Delete permissions first
    perms = session.exec(select(AdminPermission).where(AdminPermission.user_id == user.id)).all()
    for p in perms:
        session.delete(p)

    session.delete(user)
    session.commit()
    return {"message": "User deleted successfully"}

@router.get("/{user_id}/permissions", response_model=AdminPermission)
def read_user_permissions(
    user_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get permissions for a user.
    """
    if not current_user.is_super_admin and current_user.id != user_id:
         raise HTTPException(status_code=403, detail="Not enough permissions")

    perm = session.exec(select(AdminPermission).where(AdminPermission.user_id == user_id)).first()
    if not perm:
        return AdminPermission(user_id=user_id) # Return default False permissions
    return perm
