from sqlmodel import Session, select
from app.core.database import engine, create_db_and_tables
from app.models.department import Department
from app.models.program import Program
from app.models.faculty import Faculty
from app.core.security import get_password_hash # If creating accounts, but for Faculty model we just need basic info

def seed_data():
    print("🌱 Seeding Academic Data...")
    
    with Session(engine) as session:
        # 1. Departments
        departments_data = [
            {"name": "Department of Computer Science", "code": "CS"},
            {"name": "Department of Software Engineering", "code": "SE"},
            {"name": "Department of Artificial Intelligence", "code": "AI"},
            {"name": "Department of Electrical Engineering", "code": "EE"},
            {"name": "Department of Business Administration", "code": "BBA"},
            {"name": "Department of Psychology", "code": "PSY"},
        ]
        
        departments = {}
        for dept_data in departments_data:
            dept = session.exec(select(Department).where(Department.code == dept_data["code"])).first()
            if not dept:
                dept = Department(name=dept_data["name"], code=dept_data["code"])
                session.add(dept)
                session.commit()
                session.refresh(dept)
                print(f"✅ Created Department: {dept.name}")
            else:
                if dept.name != dept_data["name"]:
                    dept.name = dept_data["name"]
                    session.add(dept)
                    session.commit()
                    print(f"🔄 Updated Department: {dept.name}")
            departments[dept.code] = dept

        # 2. Programs
        programs_data = [
            {"name": "BS Computer Science", "code": "BSCS", "dept_code": "CS"},
            {"name": "BS Software Engineering", "code": "BSSE", "dept_code": "SE"},
            {"name": "BS Artificial Intelligence", "code": "BSAI", "dept_code": "AI"},
            {"name": "BS Electrical Engineering", "code": "BSEE", "dept_code": "EE"},
            {"name": "Bachelor of Business Admin", "code": "BBA", "dept_code": "BBA"},
            {"name": "BS Psychology", "code": "BSPSY", "dept_code": "PSY"},
            {"name": "BS Cyber Security", "code": "BSCY", "dept_code": "CS"}, # Assuming under CS for now if CY dept doesn't exist
        ]

        for prog_data in programs_data:
            dept = departments.get(prog_data["dept_code"])
            # Fallback if CY dept not in list but program needs it
            if not dept and prog_data["dept_code"] == "CY":
                 # Create or find CY department if missing from main list for some reason
                 pass 

            if dept:
                prog = session.exec(select(Program).where(Program.code == prog_data["code"])).first()
                if not prog:
                    prog = Program(name=prog_data["name"], code=prog_data["code"], department_id=dept.id)
                    session.add(prog)
                    session.commit()
                    print(f"✅ Created Program: {prog.name}")
                
        # 3. Dummy Faculty
        # Format: (Name, Email, FacultyID, DeptCode)
        faculty_list = [
            ("Dr. Ali Ahmed", "ali.ahmed@univ.edu", "FAC101", "CS"),
            ("Ms. Sara Khan", "sara.khan@univ.edu", "FAC102", "CS"),
            ("Dr. Bilal Tauseef", "bilal.tauseef@univ.edu", "FAC201", "SE"),
            ("Dr. Ayesha Zafar", "ayesha.zafar@univ.edu", "FAC301", "AI"),
            ("Mr. Omar Farooq", "omar.farooq@univ.edu", "FAC401", "EE"),
            ("Ms. Hina Altaf", "hina.altaf@univ.edu", "FAC501", "BBA"),
            ("Dr. Zainab Bibi", "zainab.bibi@univ.edu", "FAC601", "PSY"),
        ]

        for name, email, fac_id, dept_code in faculty_list:
            dept = departments.get(dept_code)
            if dept:
                # Check by faculty_id or email
                existing_fac = session.exec(select(Faculty).where((Faculty.faculty_id == fac_id) | (Faculty.email == email))).first()
                if not existing_fac:
                    fac = Faculty(
                        name=name,
                        email=email,
                        faculty_id=fac_id,
                        department_id=dept.id
                    )
                    session.add(fac)
                    session.commit()
                    print(f"👤 Created Faculty: {name} ({fac_id})")
                else:
                    # Update faculty_id if missing
                    if not existing_fac.faculty_id:
                        existing_fac.faculty_id = fac_id
                        session.add(existing_fac)
                        session.commit()
                        print(f"🔄 Updated Faculty ID for: {name}")

    print("🚀 Seeding Complete!")

if __name__ == "__main__":
    seed_data()
