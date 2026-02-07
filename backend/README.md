---
title: Attendance Backend
emoji: 🚀
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# Face Recognition Attendance System Backend
This Space runs the FastAPI backend for the attendance system.

## Getting Started

### Prerequisites
- Python 3.10+
- Docker (optional, but recommended)

### Setup
1. **Clone the repository.**
2. **Configure Environment Variables:**
   - Copy the example environment file:
     ```bash
     cp .env.example .env
     ```
   - Open `.env` and replace the placeholder `POSTGRESQL_URL` with your actual database connection string.
3. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
4. **Run the application:**
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```