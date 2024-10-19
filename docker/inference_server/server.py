from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

app = FastAPI()

class InferenceRequest(BaseModel):
    inputs: str
    parameters: dict = {}

class InferenceResponse(BaseModel):
    generated_text: str

# Load model and tokenizer
MODEL_NAME = "nvidia/Llama-3.1-Nemotron-70B-Instruct-HF"

try:
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModelForCausalLM.from_pretrained(
        MODEL_NAME,
        torch_dtype=torch.float16,
        device_map="auto"  # Automatically map to available GPUs
    )
except Exception as e:
    print(f"Error loading model: {e}")
    raise e

@app.post("/generate", response_model=InferenceResponse)
def generate_text(request: InferenceRequest):
    try:
        inputs = tokenizer.encode(request.inputs, return_tensors="pt").to(model.device)
        output = model.generate(
            inputs,
            max_new_tokens=request.parameters.get("max_new_tokens", 200),
            temperature=request.parameters.get("temperature", 0.7)
        )
        generated_text = tokenizer.decode(output[0], skip_special_tokens=True)
        return InferenceResponse(generated_text=generated_text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
