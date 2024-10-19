# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
from fastapi import FastAPI, Depends, HTTPException
from src.models.model import GPT4oModel
from src.utils.auth import get_current_user
import asyncio

app = FastAPI()
model = GPT4oModel()

@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/api/fine-tune")
async def fine_tune(training_data: dict, current_user: str = Depends(get_current_user)):
    # Fine-tuning logic
    fine_tune_id = model.fine_tune(training_data['training_file_id'])
    return {"status": "Model fine-tuned", "fine_tune_id": fine_tune_id}

@app.post("/api/predict")
async def predict(input_data: dict, current_user: str = Depends(get_current_user)):
    if "text" not in input_data:
        raise HTTPException(status_code=400, detail="Input data must contain 'text' field.")
    # Prediction logic
    prediction = await asyncio.get_event_loop().run_in_executor(None, model.predict, input_data["text"], "davinci-finetuned-xyz")
    return {"prediction": prediction}

@app.get("/api/status")
async def get_status(fine_tune_id: str, current_user: str = Depends(get_current_user)):
    """
    Retrieves the status of a specific fine-tuning job.
    """
    status_response = model.get_fine_tune_status(fine_tune_id)
    return {"fine_tune_id": fine_tune_id, "status": status_response['status']}
