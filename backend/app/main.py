from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.seed import seed_data
from app.routers import students, minigames, assignments

@asynccontextmanager
async def lifespan(app: FastAPI):
    seed_data()
    yield

app = FastAPI(title="AAC Homework API", lifespan=lifespan)

app.include_router(students.router)
app.include_router(minigames.router)
app.include_router(assignments.router)
