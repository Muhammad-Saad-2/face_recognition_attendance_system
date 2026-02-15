
import requests
import pytest

BASE_URL = "http://localhost:8000/api/v1"

# Credentials
SUPER_ADMIN = {"username": "superadmin", "password": "SuperAdmin124$"}
CHILD_ADMIN = {"username": "childadmin", "password": "ChildAdmin123$"}

def get_token(username, password):
    response = requests.post(f"{BASE_URL}/login/access-token", data={"username": username, "password": password})
    if response.status_code == 200:
        return response.json()
    return None

def test_rbac_flow():
    print("Testing RBAC Flow...")

    # 1. Login as Super Admin
    sa_token_data = get_token(SUPER_ADMIN['username'], SUPER_ADMIN['password'])
    assert sa_token_data is not None, "Super admin login failed"
    sa_headers = {"Authorization": f"Bearer {sa_token_data['access_token']}"}
    print("Super Admin logged in.")

    # 2. Key Check: Ensure we can manage users
    # Delete child admin if exists
    users = requests.get(f"{BASE_URL}/users/", headers=sa_headers).json()
    for u in users:
        if u['username'] == CHILD_ADMIN['username']:
            requests.delete(f"{BASE_URL}/users/{u['id']}", headers=sa_headers)
            print("Cleaned up existing child admin.")

    # 3. Create Child Admin with NO permissions
    child_data = {
        "user_in": {
            "username": CHILD_ADMIN['username'],
            "password": CHILD_ADMIN['password'],
            "email": "child@example.com",
            "full_name": "Child Admin",
            "is_active": True
        },
        "permissions": {
            "can_manage_students": False,
            "can_manage_courses": True # Grant ONLY course permission
        }
    }
    
    resp = requests.post(f"{BASE_URL}/users/", headers=sa_headers, json=child_data)
    if resp.status_code != 200:
        print(f"Failed to create child admin: {resp.text}")
    assert resp.status_code == 200
    print("Child Admin created with Course permission only.")

    # 4. Login as Child Admin
    ca_token_data = get_token(CHILD_ADMIN['username'], CHILD_ADMIN['password'])
    assert ca_token_data is not None, "Child admin login failed"
    ca_headers = {"Authorization": f"Bearer {ca_token_data['access_token']}"}
    print("Child Admin logged in.")

    # 5. Verify Permissions via API Actions
    
    # A. Try to create a student (Should FAIL)
    student_data = {
        "name": "Test Student",
        "student_id": "TEST001",
        "program": "CS",
        "major": "CS",
        "current_semester": 1
    }
    # Using update endpoint on non-existent or create endpoint? My student create endpoint might need images if using register.
    # But I can check fetching students. Usually read is open to all admins, write is restricted.
    # Let's try DELETE student (requires can_manage_students)
    # Pick a random ID or just expect 403 regardless of ID existence check (dependency runs first).
    # Wait, dependency runs first.
    resp = requests.delete(f"{BASE_URL}/students/99999", headers=ca_headers)
    assert resp.status_code == 403, f"Child admin should NOT be able to delete student. Got {resp.status_code}"
    print("Verified: Child Admin CANNOT manage students (403 Forbidden).")

    # B. Try to create a course (Should SUCCEED)
    # Create dept first as super admin to link
    dept_data = {"name": "Test Dept", "code": "TD"}
    dept_resp = requests.post(f"{BASE_URL}/departments/", headers=sa_headers, json=dept_data)
    if dept_resp.status_code == 200:
        dept_id = dept_resp.json()['id']
    else:
        # Maybe already exists
        depts = requests.get(f"{BASE_URL}/departments/", headers=sa_headers).json()
        dept_id = depts[0]['id']

    course_data = {
        "name": "Test Course",
        "code": "TC101",
        "department_id": dept_id,
        "semester": 1
    }
    resp = requests.post(f"{BASE_URL}/courses/", headers=ca_headers, json=course_data)
    assert resp.status_code in [200, 201], f"Child admin SHOULD be able to create course. Got {resp.status_code} {resp.text}"
    print("Verified: Child Admin CAN manage courses.")
    
    # Cleanup course
    if resp.status_code in [200, 201]:
        course_id = resp.json()['id']
        requests.delete(f"{BASE_URL}/courses/{course_id}", headers=ca_headers)


    print("\nRBAC Flow Test Passed Successfully!")

if __name__ == "__main__":
    try:
        test_rbac_flow()
    except AssertionError as e:
        print(f"\nTEST FAILED: {e}")
    except Exception as e:
        print(f"\nERROR: {e}")
