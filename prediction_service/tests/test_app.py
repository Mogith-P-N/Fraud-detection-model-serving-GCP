import types
from fastapi.testclient import TestClient
from prediction_service.app.main import create_app


class StubModel:a
    def predict_proba(self, X):
        # Always predict class 1 with 0.9 confidence
        import numpy as np

        return np.array([[0.1, 0.9]])

# health check test
def test_health_ok():
    app = create_app(model=StubModel())
    client = TestClient(app)
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"

# predict success test
def test_predict_success():
    app = create_app(model=StubModel())
    client = TestClient(app)
    payload = {"features": {"amount": 123.45, "merchant_id": 42}}
    resp = client.post("/v1/predict", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["prediction"] in (0, 1)
    assert 0.0 <= body["confidence"] <= 1.0
    assert "model_version" in body

# model not loaded test
def test_model_not_loaded():
    app = create_app(model=None) 
    client = TestClient(app)
    payload = {"features": {"amount": 123.45}}
    resp = client.post("/v1/predict", json=payload)
    assert resp.status_code == 500
    assert "Model not loaded" in resp.json()["detail"]

# emtpy request test
def test_invalid_features():
    app = create_app(model=StubModel())
    client = TestClient(app)
    payload = {"features": {}} 
    resp = client.post("/v1/predict", json=payload)
    assert resp.status_code == 400