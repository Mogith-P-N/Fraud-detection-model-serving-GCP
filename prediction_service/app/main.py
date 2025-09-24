import os
import logging
from typing import Optional

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from .schemas import PredictRequest, PredictResponse


LOGGER = logging.getLogger("prediction_service")
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))


def load_model(model_path: str) -> object:
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found at path: {model_path}")
    LOGGER.info("Loading model from %s", model_path)
    return joblib.load(model_path) #specifically we don't know pytorch or tensorflow


def create_app(model: Optional[object] = None) -> FastAPI:
    app = FastAPI(title="Fraud Prediction Service", version="1.0.0")

    app.state.model = model
    app.state.model_version = os.getenv("MODEL_VERSION", "unknown")

    @app.get("/health")
    async def health() -> dict:
        return {"status": "ok"}

    @app.post("/v1/predict", response_model=PredictResponse)
    async def predict(payload: PredictRequest) -> PredictResponse:
        if getattr(app.state, "model", None) is None:
            raise HTTPException(status_code=500, detail="Model not loaded")

        features = payload.features
        if not isinstance(features, dict) or len(features) == 0:
            raise HTTPException(status_code=400, detail="Invalid feature payload")

        # Create single-row DataFrame to preserve feature names
        data_frame = pd.DataFrame([features])

        model = app.state.model
        # Compute prediction and confidence
        if hasattr(model, "predict_proba"):
            probabilities = model.predict_proba(data_frame)
            # choose max probability as confidence
            if isinstance(probabilities, list):
                probabilities = np.array(probabilities)
            confidence = float(np.max(probabilities, axis=1)[0])
            pred = int(np.argmax(probabilities, axis=1)[0])
        else:
            preds = model.predict(data_frame)
            pred = int(preds[0])
            confidence = 1.0

        return PredictResponse(
            prediction=pred,
            confidence=confidence,
            model_version=app.state.model_version,
        )

    return app


# Default application instance loads model at import time for production
MODEL_PATH = os.getenv("MODEL_PATH", os.path.join(os.path.dirname(__file__), "..", "models", "model.pkl"))
try:
    default_model = load_model(os.path.abspath(MODEL_PATH))
except Exception as exc: 
    LOGGER.error("Failed to load model: %s", exc)
    default_model = None

app = create_app(default_model)
