import base64
from fastapi import APIRouter, HTTPException
from app.schemas import PredictionRequest, PredictionResponse

router = APIRouter(tags=["predictions"])


@router.post("/predict", response_model=PredictionResponse)
def predict_words(payload: PredictionRequest):
    try:
        decoded_bytes = base64.b64decode(payload.audio_base64)
        decoded_bytes.decode("utf-8")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid base64 input")

    return {
        "predictions": ["life", "is", "roblox"]
    }
