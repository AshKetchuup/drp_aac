import base64
from fastapi import APIRouter, HTTPException
from app.schemas import PredictionRequest, PredictionResponse

router = APIRouter(prefix="/api/context", tags=["predictions"])


@router.post("/predict", response_model=PredictionResponse)
def predict_words(payload: PredictionRequest):
    try:
        if payload.audio_base64:
            decoded_bytes = base64.b64decode(payload.audio_base64)
            decoded_bytes.decode("utf-8")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid base64 input")

    # Hardcoded payload of highly relevant semantic tokens as requested
    return {
        "predictions": ["Pizza", "Apple", "Sandwich", "Pasta"]
    }
