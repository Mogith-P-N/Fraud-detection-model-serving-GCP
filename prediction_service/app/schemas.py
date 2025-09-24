from pydantic import BaseModel, Field
from typing import Dict


class PredictRequest(BaseModel):
    features: Dict[str, float] = Field(
        ..., description="Mapping of feature name to numeric value for one transaction"
    )


class PredictResponse(BaseModel):
    prediction: int
    confidence: float
    model_version: str
