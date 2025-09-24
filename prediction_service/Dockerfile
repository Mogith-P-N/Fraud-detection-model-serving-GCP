# syntax=docker/dockerfile:1.7-labs
FROM python:3.11-slim AS base #can use python:3.11-alpine for smaller image 

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    UVICORN_WORKERS=2

# install system deps required by scientific python
RUN apt-get update && apt-get install -y  build-essential curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# install dependencies first for better caching
COPY prediction_service/requirements.txt /app/requirements.txt
RUN pip install --no-deps --no-cache-dir -r /app/requirements.txt

# Copy app source
COPY prediction_service /app/prediction_service

# Model path inside image: /app/prediction_service/models/model.pkl

EXPOSE 8000

ENV MODEL_PATH=/app/prediction_service/models/model.pkl \
    MODEL_VERSION=unknown

# Run as non-root
RUN useradd -m appuser
USER appuser

CMD ["uvicorn", "prediction_service.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
