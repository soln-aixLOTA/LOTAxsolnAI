# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
from fastapi.testclient import TestClient
from src.api.main import app
from unittest.mock import patch
from src.models.model import GPT4oModel

client = TestClient(app)

def test_health_check():
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_predict():
    with patch.object(GPT4oModel, 'predict', return_value="Predicted output for: Test input"):
        response = client.post(
            "/api/predict",
            headers={"Authorization": "Bearer your_jwt_token"},
            json={"text": "Test input"}
        )
        assert response.status_code == 200
        assert "prediction" in response.json()
        assert response.json()["prediction"] == "Predicted output for: Test input"

def test_predict_no_auth():
    response = client.post(
        "/api/predict",
        json={"text": "Test input"}
    )
    assert response.status_code == 401

def test_predict_missing_text():
    response = client.post(
        "/api/predict",
        headers={"Authorization": "Bearer your_jwt_token"},
        json={}
    )
    assert response.status_code == 400

def test_fine_tune():
    with patch.object(GPT4oModel, 'fine_tune', return_value="ft-12345"):
        response = client.post(
            "/api/fine-tune",
            headers={"Authorization": "Bearer your_jwt_token"},
            json={"training_file_id": "file-12345"}
        )
        assert response.status_code == 200
        assert response.json()["status"] == "Model fine-tuned"
        assert response.json()["fine_tune_id"] == "ft-12345"

def test_get_status():
    with patch.object(GPT4oModel, 'get_fine_tune_status', return_value={'status': 'succeeded'}):
        response = client.get(
            "/api/status",
            headers={"Authorization": "Bearer your_jwt_token"},
            params={"fine_tune_id": "ft-12345"}
        )
        assert response.status_code == 200
        assert response.json() == {"fine_tune_id": "ft-12345", "status": "succeeded"}
