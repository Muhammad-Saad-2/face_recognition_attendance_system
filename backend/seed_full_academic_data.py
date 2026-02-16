from sqlmodel import Session, select
from app.core.database import engine, create_db_and_tables
from app.models.department import Department
from app.models.program import Program
from app.models.faculty import Faculty
# from app.core.security import get_password_hash # Not needed for simple seed

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
        dept_id_counter = 1001
        for dept_data in departments_data:
            dept = session.exec(select(Department).where(Department.code == dept_data["code"])).first()
            if not dept:
                dept = Department(
                    name=dept_data["name"], 
                    code=dept_data["code"],
                    unique_id=str(dept_id_counter)
                )
                session.add(dept)
                session.commit()
                session.refresh(dept)
                print(f"✅ Created Department: {dept.name} ({dept.unique_id})")
                dept_id_counter += 1
            else:
                print(f"ℹ️  Department already exists: {dept.name} ({dept.unique_id})")
            # Store by code for easy lookup
            departments[dept.code] = dept

        # 2. Programs
        programs_data = [
            {"name": "BS Computer Science", "code": "BSCS", "dept_code": "CS"},
            {"name": "BS Software Engineering", "code": "BSSE", "dept_code": "SE"},
            {"name": "BS Artificial Intelligence", "code": "BSAI", "dept_code": "AI"},
            {"name": "BS Electrical Engineering", "code": "BSEE", "dept_code": "EE"},
            {"name": "Bachelor of Business Admin", "code": "BBA", "dept_code": "BBA"},
            {"name": "BS Psychology", "code": "BSPSY", "dept_code": "PSY"},
            {"name": "BS Cyber Security", "code": "BSCY", "dept_code": "CS"},
        ]

        prog_id_counter = 20001
        for prog_data in programs_data:
            dept = departments.get(prog_data["dept_code"])
            if dept:
                prog = session.exec(select(Program).where(Program.code == prog_data["code"])).first()
                if not prog:
                    prog = Program(
                        name=prog_data["name"], 
                        code=prog_data["code"], 
                        department_id=dept.unique_id, # Link via unique_id (String)
                        unique_id=str(prog_id_counter)
                    )
                    session.add(prog)
                    session.commit()
                    print(f"✅ Created Program: {prog.name} ({prog.unique_id})")
                prog_id_counter += 1
                
        # 3. Dummy Faculty
        # Format: (Name, Email, FacultyID, DeptCode)
        faculty_list = [
            ("Dr. Ali Ahmed", "ali.ahmed@univ.edu", "CS-0001", "CS"),
            ("Ms. Sara Khan", "sara.khan@univ.edu", "CS-0002", "CS"),
            ("Dr. Bilal Tauseef", "bilal.tauseef@univ.edu", "SE-0001", "SE"),
            ("Dr. Ayesha Zafar", "ayesha.zafar@univ.edu", "AI-0001", "AI"),
            ("Mr. Omar Farooq", "omar.farooq@univ.edu", "EE-0001", "EE"),
            ("Ms. Hina Altaf", "hina.altaf@univ.edu", "BBA-0001", "BBA"),
            ("Dr. Zainab Bibi", "zainab.bibi@univ.edu", "PSY-0001", "PSY"),
            ("Mr. Kamran Akmal", "kamran.akmal@univ.edu", "CS-0003", "CS"),
            ("Dr. Nadia Hussain", "nadia.hussain@univ.edu", "SE-0002", "SE"),
            ("Mr. Javed Miandad", "javed.miandad@univ.edu", "EE-0002", "EE"),
        ]

        for name, email, fac_id, dept_code in faculty_list:
            if dept_code not in departments:
                continue
                
            dept = departments[dept_code]
            
            # Check by faculty_id or email
            existing_fac = session.exec(select(Faculty).where((Faculty.faculty_id == fac_id) | (Faculty.email == email))).first()
            if not existing_fac:
                fac = Faculty(
                    name=name,
                    email=email,
                    faculty_id=fac_id,
                    department_id=dept.unique_id # Link via unique_id (String)
                )
                session.add(fac)
                session.commit()
                print(f"👤 Created Faculty: {name} ({fac_id})")

        # 4. Dummy Courses
        # Format: (Name, Code, Semester, DeptCode)
        courses_list = [
            ("Intro to Computing", "CS-101", 1, "CS"),
            ("Programming Fundamentals", "CS-102", 1, "CS"),
            ("Object Oriented Programming", "CS-201", 2, "CS"),
            ("Data Structures", "CS-202", 3, "CS"),
            ("Intro to Software Engineering", "SE-101", 1, "SE"),
            ("Software Requirements", "SE-201", 2, "SE"),
            ("Software Design & Arch", "SE-301", 3, "SE"),
            ("Artificial Intelligence I", "AI-101", 1, "AI"),
            ("Machine Learning", "AI-201", 2, "AI"),
            ("Basic Electronics", "EE-101", 1, "EE"),
            ("Circuit Analysis", "EE-102", 1, "EE"),
            ("Intro to Business", "BBA-101", 1, "BBA"),
            ("Principles of Management", "BBA-102", 1, "BBA"),
            ("Intro to Psychology", "PSY-101", 1, "PSY"),
            ("Developmental Psychology", "PSY-201", 2, "PSY"),
        ]

        # Import Course model inside function to avoid circular imports if any
        from app.models.course import Course

        for name, code, sem, dept_code in courses_list:
            if dept_code not in departments:
                continue
            
            dept = departments[dept_code]
            course = session.exec(select(Course).where(Course.code == code)).first()
            if not course:
                course = Course(
                    name=name,
                    code=code,
                    semester=sem,
                    department_id=dept.unique_id # String ID
                )
                session.add(course)
                session.commit()
                print(f"📘 Created Course: {code} - {name} ({dept_code})")

    print("🚀 Seeding Complete!")

if __name__ == "__main__":
    seed_data()
