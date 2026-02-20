# Use official Python runtime as base image
# 'slim' variant = smaller size (150MB vs 900MB for full Python)
FROM python:3.11-slim

# Set working directory inside container
# All subsequent commands run from here
WORKDIR /app

# LAYER 1: Copy only requirements first
# This layer rebuilds ONLY when requirements.txt changes
COPY requirements.txt .

# LAYER 2: Install dependencies
# This layer is cached unless requirements.txt changes
RUN pip install --no-cache-dir -r requirements.txt

# LAYER 3: Copy application code
# This layer rebuilds EVERY time you change app.py
COPY app.py .

# Document which port the container exposes
EXPOSE 5000

# Define the command to run when container starts
CMD ["python", "app.py"]
