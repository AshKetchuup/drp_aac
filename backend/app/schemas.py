from pydantic import BaseModel


class PredictionRequest(BaseModel):
    text: str = ""
    likes: list[str] = []
    dislikes: list[str] = []
    current_suggestions: list[str] = []
    min_suggestions: int = 4


class PredictionResponse(BaseModel):
    predictions: list[str]
