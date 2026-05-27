from fastapi import FastAPI
from app.seed import seed_data
from app.routers import students, minigames, assignments

app = FastAPI(title="AAC Homework API")

@app.on_event("startup")
def on_startup():
    seed_data()

app.include_router(students.router)
app.include_router(minigames.router)
app.include_router(assignments.router)
