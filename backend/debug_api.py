import requests
import json

def debug_api():
    try:
        # Login first if needed? 
        # Actually departments endpoint might be public or I need a token.
        # But wait, frontend calls it. Let's try without token first, or use a known one.
        # The endpoint `read_departments` depends on `current_user` so it needs auth.
        
        # We need a token. Let's log in as superadmin.
        login_url = "http://localhost:8000/api/v1/login/access-token"
        login_data = {"username": "admin", "password": "adminpassword"} # Assuming default credentials
        
        print("Logging in...")
        resp = requests.post(login_url, data=login_data)
        if resp.status_code != 200:
            print(f"Login failed: {resp.text}")
            return

        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        print("Fetching Departments...")
        dept_url = "http://localhost:8000/api/v1/departments/"
        resp = requests.get(dept_url, headers=headers)
        
        if resp.status_code == 200:
            depts = resp.json()
            print(json.dumps(depts, indent=2))
        else:
            print(f"Failed to fetch departments: {resp.text}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    debug_api()
