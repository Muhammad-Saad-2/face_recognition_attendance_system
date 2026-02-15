from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.api import deps
from app.core.database import get_session
from app.models.program import Program, ProgramCreate, ProgramRead, ProgramUpdate
from app.models.user import User
from app.api.permissions import can_manage_academic

router = APIRouter()

@router.get("/", response_model=List[ProgramRead])
def read_programs(
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(get_session),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve programs.
    """
    programs = session.exec(select(Program).offset(skip).limit(limit)).all()
    return programs

@router.post("/", response_model=ProgramRead, dependencies=[Depends(can_manage_academic)])
def create_program(
    *,
    session: Session = Depends(get_session),
    program_in: ProgramCreate,
) -> Any:
    """
    Create new program.
    """
    # Auto-generate unique_id
    if not program_in.unique_id:
        # Find max unique_id that is a number
        all_ids = session.exec(select(Program.unique_id)).all()
        max_id = 20000 # Start from 20000 for programs
        for uid in all_ids:
            if uid and uid.isdigit():
                try:
                    uid_int = int(uid)
                    if uid_int > max_id:
                        max_id = uid_int
                except ValueError:
                    pass
        
        program_in.unique_id = str(max_id + 1)

    program = Program.from_orm(program_in)
    session.add(program)
    session.commit()
    session.refresh(program)
    return program

@router.put("/{program_id}", response_model=ProgramRead, dependencies=[Depends(can_manage_academic)])
def update_program(
    *,
    session: Session = Depends(get_session),
    program_id: int,
    program_in: ProgramUpdate,
) -> Any:
    """
    Update a program.
    """
    program = session.get(Program, program_id)
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
    
    update_data = program_in.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(program, key, value)
        
    session.add(program)
    session.commit()
    session.refresh(program)
    return program

@router.delete("/{program_id}", dependencies=[Depends(can_manage_academic)])
def delete_program(
    *,
    session: Session = Depends(get_session),
    program_id: int,
) -> Any:
    """
    Delete a program.
    """
    program = session.get(Program, program_id)
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
    
    session.delete(program)
    session.commit()
    return {"message": "Program deleted successfully"}
