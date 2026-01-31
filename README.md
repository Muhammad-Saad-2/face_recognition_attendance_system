<p align="center">
  <img src="images/veriface_logo.png" width="300" alt="VeriFace Logo">
</p>

<h1 align="center">VeriFace - Face Recognition Attendance System</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" alt="Maintained">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/FastAPI-0.x-009688.svg" alt="FastAPI">
  <img src="https://img.shields.io/badge/DeepFace-Modern-orange.svg" alt="DeepFace">
</p>

---

## 🌟 About the Project

**VeriFace** is a comprehensive solution designed to automate the attendance marking process using state-of-the-art face recognition technology. It bridges the gap between traditional manual logs and modern AI-driven efficiency. 

The system allows educators and administrators to register students with just a few photos and thereafter mark attendance for an entire classroom via a single group photo. 

### 🚀 Key Features
- **✨ Seamless Registration:** Capture 1-5 sample images per student for high-accuracy training.
- **👥 Multi-Face Recognition:** Capable of identifying multiple students from a single group photograph.
- **📊 Automated Reporting:** Generates and updates Excel attendance sheets (`attendance.xlsx`) in real-time.
- **🛡️ Secure & Scalable:** Uses a PostgreSQL backend for metadata and specialized services for face encoding.
- **📱 Cross-Platform App:** A sleek Flutter mobile application for both iOS and Android.

---

## 🛠️ Technical Stack

### **Backend**
- **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Python)
- **AI/ML:** [DeepFace](https://github.com/serengil/deepface), OpenCV, Face Recognition
- **Database:** PostgreSQL (SQLModel / SQLAlchemy)
- **Containerization:** Docker & Docker Compose
- **Reporting:** OpenPyXL (Excel generation)

### **Frontend**
- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** Provider / Built-in State
- **Hardware Interaction:** Camera & Gallery integration

---

## 🏗️ Architecture Overview

VeriFace follows a service-oriented architecture:
1. **Identity Service:** Handles student registration and face encoding storage (Pickle/DB).
2. **Attendance Service:** Manages the logic for recognizing faces in group photos and logging entries.
3. **Flutter App:** Handles user interaction, photo capture, and API communication.

---

## 🚀 Getting Started

### 1. Prerequisites
- Docker & Docker Compose
- Flutter SDK (for mobile)
- Python 3.10+ (for local development)

### 2. Backend Setup
```bash
cd backend
# Create .env file based on example
cp .env.example .env
# Start with Docker
docker compose up --build
```
The API will be available at `http://localhost:8000`.

### 3. Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

---

## 📸 Demonstration

| Student Registration | Attendance Marked |
| :---: | :---: |
| <img src="images/registration_demo.png" width="300"> | <img src="images/attendance_demo.png" width="300"> |

*Note: Screenshots are for demonstration purposes. Replace with actual app screenshots.*

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
  Built with ❤️ by Muhammad Saad & Team
</p>
