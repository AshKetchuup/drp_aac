from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.seed import seed_data
from app.routers import students, minigames, assignments, predictions

@asynccontextmanager
async def lifespan(app: FastAPI):
    # seed_data() # Commented out to avoid firebase crash when running mockup
    yield

app = FastAPI(title="AAC Homework API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(students.router)
app.include_router(minigames.router)
app.include_router(assignments.router)
app.include_router(predictions.router)
