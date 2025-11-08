# 📱 Face Recognition Attendance System


## Upper Level workflow

📱 Flutter (frontend)
   |
   | -> Sends photo to
   ↓
⚙️ FastAPI (backend)
   ├── /register_student (save encodings)
   ├── /mark_attendance (recognize and log to Excel)
   ├── encodings.pkl (stored face data)
   └── attendance.xlsx (auto-updated file)


