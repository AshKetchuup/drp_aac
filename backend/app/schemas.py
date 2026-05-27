from datetime import datetime
from pydantic import BaseModel

class StudentOut(BaseModel):
    id: str
    name: str
    age: int | None = None

class MinigameOut(BaseModel):
    id: str
    title: str
    description: str | None = None
    category: str | None = None

class AssignmentCreate(BaseModel):
    teacher_id: str
    student_id: str
    minigame_id: str

class AssignmentOut(BaseModel):
    id: str
    teacher_id: str
    student_id: str
    minigame_id: str
    status: str
    assigned_at: datetime

class StudentAssignmentOut(BaseModel):
    id: str
    status: str
    assigned_at: datetime
    minigame: MinigameOut