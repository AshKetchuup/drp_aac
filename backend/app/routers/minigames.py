from typing import List
from fastapi import APIRouter, Depends

from app.db import db
from app.schemas import MinigameOut
from app.auth import get_current_user

router = APIRouter(tags=["minigames"])

@router.get("/minigames", response_model=List[MinigameOut])
def get_minigames(user: dict = Depends(get_current_user)):
    return [
        MinigameOut(id=doc.id, **doc.to_dict()) 
        for doc in db.collection("minigames").stream()
    ]
