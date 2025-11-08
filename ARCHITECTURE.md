# 🎯 Face Recognition Attendance System

## 🧩 Project Overview
This project aims to build a **Face Recognition Attendance System** using **Python, OpenCV, and FastAPI**, with a **Flutter** mobile app for capturing student photos.  
The system automatically recognizes students’ faces (even in group photos) and marks their attendance directly into an **Excel file**, without needing any external database.

---

## 🥅 Goal of the Project
The main goal is to **automate the attendance process** by identifying students’ faces from camera images instead of manual marking.

### 🔹 Key Objectives:
1. **Register students** with multiple face samples (3–5 images per student).
2. **Recognize faces automatically** from both individual and group photos.
3. **Record attendance** with date and time directly into an Excel sheet.
4. **Provide a simple mobile interface** for photo capture and attendance marking.

---

## 🧠 Why This Project?
Manual attendance systems are time-consuming and prone to errors.  
By using face recognition, attendance can be marked instantly and more accurately.  
This project showcases a real-world use of **AI + Software Engineering** to simplify routine tasks.

---

## 🏗️ Tech Stack

| Component | Technology Used | Purpose |
|------------|-----------------|----------|
| **Backend** | FastAPI (Python) | Handles all APIs for registration, recognition, and Excel update |
| **Face Detection & Recognition** | OpenCV + `face_recognition` (based on dlib) | Detects and identifies faces from images |
| **Frontend** | Flutter | Captures photo using mobile camera and sends it to backend |
| **Storage** | Pickle (`.pkl`) + Excel (`.xlsx`) | `.pkl` stores face encodings, Excel stores attendance records |
| **Excel Handling** | OpenPyXL | Creates and updates attendance sheet automatically |

---

## 🔄 Project Workflow (Simple Explanation)

Below is the **step-by-step explanation** of how the system works — written simply so everyone in the group can understand.

---

### 🧍 Step 1: Student Registration
1. Open the mobile app (Flutter frontend).
2. Capture **3–5 photos** of each student from different angles.
3. The app sends each photo (with the student’s name, program, and major) to the backend.
4. The backend:
   - Detects the face in each image.
   - Converts each face into a **numeric face encoding** (a special set of numbers representing the person’s unique features).
   - Saves these encodings in a file called `encodings.pkl` for future use.

**In short:**  
> The system learns to remember each student’s face using mathematical face features.

---

### 👥 Step 2: Taking Attendance
1. Teacher or user opens the app again and captures a **group photo** (e.g., all students sitting together).
2. The app sends this group image to the backend.
3. The backend:
   - Detects all faces in the group photo.
   - Compares each detected face with the stored encodings.
   - Identifies the students it recognizes.
4. For each recognized student:
   - Their **name**, **date**, and **time** are recorded in `attendance.xlsx`.

**In short:**  
> The backend matches faces in the photo with the known faces and writes the attendance automatically.

---

### 📁 Step 3: Excel File Generation
- The attendance Excel file (`attendance.xlsx`) looks like this:

| Name | Date | Time |
|------|------|------|
| Muhammad Saad | 2025-11-08 | 09:31:22 |
| Ali Ahmed | 2025-11-08 | 09:31:22 |

- Each time a group photo is sent, new entries are automatically appended.

**In short:**  
> The Excel file acts as your attendance register.

---

### 🧱  Uppe Level System Architecture


📱 Flutter (frontend)
   |
   | -> Sends photo to
   ↓
⚙️ FastAPI (backend)
   ├── /register_student (save encodings)
   ├── /mark_attendance (recognize and log to Excel)
   ├── encodings.pkl (stored face data)
   └── attendance.xlsx (auto-updated file)



---

## 🧰 Project Modules

| Module | Description |
|---------|-------------|
| **1. Registration Module** | Captures and saves multiple face samples for each student |
| **2. Recognition Module** | Detects and identifies faces in a new photo |
| **3. Attendance Module** | Logs recognized faces into Excel with date and time |
| **4. Frontend Module (Flutter)** | Provides simple camera interface and sends photos to API |

---

## 🧪 Example API Endpoints

| Endpoint | Method | Description |
|-----------|---------|-------------|
| `/register_student` | POST | Registers a student with their images and info |
| `/mark_attendance` | POST | Recognizes faces and updates attendance sheet |
| `/get_attendance` | GET | (Optional) Returns the Excel file or its summary |

---

## 📦 Project Folder Structure (Backend)

face_recognition_attendance/
│
├── **main.py** # FastAPI entry point
├── **requirements.txt** # Project dependencies
├── **utils/**
│   ├── **face_utils.py** # Functions for encoding and comparison
│   └── **excel_utils.py** # Functions for Excel handling
│
├── **data/**
│   ├── **encodings.pkl** # Stored face data
│   └── **attendance.xlsx** # Attendance record file
│
└── **images/**
    ├── **registered/** # Student face samples
    └── **group_photos/** # Attendance group photos



---

## 🧮 Dependencies

| Library | Purpose |
|----------|----------|
| `fastapi` | Backend API framework |
| `uvicorn` | Runs FastAPI server |
| `opencv-python` | Image handling and preprocessing |
| `face_recognition` | Face encoding and comparison |
| `numpy` | Numerical operations |
| `openpyxl` | Excel file creation and updates |
| `pickle` | Saving and loading face encodings |

---

## 🧠 Core Concept (Simple Analogy)
- Every face has a unique pattern of features.
- The system converts a face into a **list of numbers** that represent its unique features — like a fingerprint for your face.
- When a new image comes, it converts faces into numbers and compares them with stored ones.
- If the difference between two sets of numbers is small, the system says:  
  “This is the same person!”

---

## 🧾 Future Improvements (Optional)
1. Add **login system** for teacher/admin.
2. Integrate **Google Sheets API** to sync attendance online.
3. Add **live video feed recognition** instead of static images.
4. Support **attendance per course** or per classroom.

---

## 🧩 Summary

| Feature | Status |
|----------|--------|
| Database | ❌ Not used (Excel only) |
| Real-time updates | ✅ Yes |
| Multi-face detection | ✅ Supported |
| Offline support | ⚠️ Not priority |
| Platform | ✅ Android (via Flutter app) |
| Backend | ✅ FastAPI + OpenCV |

---

## ✅ Final Takeaway
This project provides a **complete end-to-end working system** for face-based attendance without needing a complex database or cloud services.  
It’s simple, understandable, and demonstrates strong technical integration between **AI, backend APIs, and a mobile app interface** — perfectly suitable for an FYP.



