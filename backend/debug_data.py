from sqlmodel import Session, select
from app.core.database import engine
from app.models.department import Department
from app.models.program import Program

def debug_data():
    with Session(engine) as session:
        print("\n--- DEPARTMENTS ---")
        depts = session.exec(select(Department)).all()
        for d in depts:
            print(f"ID: {d.id}, UniqueID: '{d.unique_id}', Name: {d.name}")

        print("\n--- PROGRAMS ---")
        progs = session.exec(select(Program)).all()
        for p in progs:
            print(f"ID: {p.id}, Code: {p.code}, Name: {p.name}, DeptID (FK): '{p.department_id}'")

if __name__ == "__main__":
    debug_data()
