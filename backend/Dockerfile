# Use a modern, stable Python base
# DeepFace/TensorFlow works best with 3.10 currently
FROM python:3.12

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on

# Set working directory
WORKDIR /app

# Install only necessary system dependencies
# libglib2.0-0 and libsm6 are required for opencv-python-headless
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
# We uninstall opencv-python to force usage of opencv-python-headless
# This prevents libGL.so.1 errors in headless environments
RUN pip install --no-cache-dir -r requirements.txt && \
    pip uninstall -y opencv-python || true

# Pre-download the VGG-Face model to avoid timeout at runtime
# This creates the weights file in /root/.deepface/weights/
RUN python -c "from deepface import DeepFace; DeepFace.build_model('VGG-Face')"

# Copy the rest of the application
COPY . .

# Hugging Face runs as user 1000
RUN useradd -m -u 1000 user

# Move the downloaded weights to the user's home directory
# DeepFace looks in ~/.deepface/weights
RUN mkdir -p /home/user/.deepface/weights && \
    cp -r /root/.deepface/weights/* /home/user/.deepface/weights/ && \
    chown -R user:user /home/user/.deepface

USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Expose the default HF Space port
EXPOSE 7860

# Start the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]