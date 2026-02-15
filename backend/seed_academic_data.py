from sqlmodel import Session, select
from app.core.database import engine, create_db_and_tables
from app.models.department import Department
from app.models.program import Program
from app.models.course import Course

def create_academic_data():
    with Session(engine) as session:
        # Departments
        departments_data = [
            {"name": "Computer Science", "code": "CS"},
            {"name": "Software Engineering", "code": "SE"},
            {"name": "Artificial Intelligence", "code": "AI"},
            {"name": "Electrical Engineering", "code": "EE"},
            {"name": "Business Administration", "code": "BBA"},
            {"name": "Cyber Security", "code": "CY"},
            {"name": "Psychology", "code": "PSY"},
        ]

        departments = {}
        for dept_data in departments_data:
            dept = session.exec(select(Department).where(Department.code == dept_data["code"])).first()
            if not dept:
                dept = Department(name=dept_data["name"], code=dept_data["code"])
                session.add(dept)
                session.commit()
                session.refresh(dept)
                print(f"Created Department: {dept.name}")
            departments[dept.code] = dept

        # Programs
        programs_data = [
            {"name": "BS Computer Science", "code": "BSCS", "dept_code": "CS"},
            {"name": "BS Software Engineering", "code": "BSSE", "dept_code": "SE"},
            {"name": "BS Artificial Intelligence", "code": "BSAI", "dept_code": "AI"},
            {"name": "BS Electrical Engineering", "code": "BSEE", "dept_code": "EE"},
            {"name": "Bachelor of Business Admin", "code": "BBA", "dept_code": "BBA"},
            {"name": "BS Cyber Security", "code": "BSCY", "dept_code": "CY"},
            {"name": "BS Psychology", "code": "BSPSY", "dept_code": "PSY"},
        ]

        programs = {}
        for prog_data in programs_data:
            dept = departments.get(prog_data["dept_code"])
            if dept:
                prog = session.exec(select(Program).where(Program.code == prog_data["code"])).first()
                if not prog:
                    prog = Program(name=prog_data["name"], code=prog_data["code"], department_id=dept.id)
                    session.add(prog)
                    session.commit()
                    session.refresh(prog)
                    print(f"Created Program: {prog.name}")
                programs[prog.code] = prog

        # Courses
        courses_data = [
            {"name": "Introduction to ICT", "code": "ICT101", "dept_code": "CS", "semester": 1},
            {"name": "Programming Fundamentals", "code": "CS102", "dept_code": "CS", "semester": 1},
            {"name": "Object Oriented Programming", "code": "CS201", "dept_code": "CS", "semester": 2},
            {"name": "Data Structures & Algorithms", "code": "CS202", "dept_code": "CS", "semester": 3},
            {"name": "Database Systems", "code": "CS301", "dept_code": "CS", "semester": 4},
            {"name": "Software Engineering", "code": "SE301", "dept_code": "SE", "semester": 5},
            {"name": "Artificial Intelligence", "code": "AI301", "dept_code": "AI", "semester": 6},
            {"name": "Circuit Analysis", "code": "EE101", "dept_code": "EE", "semester": 2},
            {"name": "Digital Logic Design", "code": "EE201", "dept_code": "EE", "semester": 3},
            {"name": "Marketing Management", "code": "MKT101", "dept_code": "BBA", "semester": 1},
            {"name": "Psychology 101", "code": "PSY101", "dept_code": "PSY", "semester": 1},
            {"name": "Network Security", "code": "CY301", "dept_code": "CY", "semester": 5},
        ]

        for course_data in courses_data:
             dept = departments.get(course_data["dept_code"])
             if dept:
                course = session.exec(select(Course).where(Course.code == course_data["code"])).first()
                if not course:
                     course = Course(
                         name=course_data["name"], 
                         code=course_data["code"], 
                         department_id=dept.id,
                         semester=course_data.get("semester", 1)
                     )
                     session.add(course)
                     session.commit()
                     print(f"Created Course: {course.name} (Sem {course.semester})")

if __name__ == "__main__":
    create_academic_data()
