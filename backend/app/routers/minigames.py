from typing import List
from fastapi import APIRouter

from app.db import db
from app.schemas import MinigameOut

router = APIRouter(tags=["minigames"])

@router.get("/minigames", response_model=List[MinigameOut])
def get_minigames():
    return [
        MinigameOut(id=doc.id, **doc.to_dict()) 
        for doc in db.collection("minigames").stream()
    ]
