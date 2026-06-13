from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db import init_db
from app.routers import predictions, profiles, tiles, schedule, boards


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create Mongo indexes on startup (idempotent).
    await init_db()
    yield


app = FastAPI(title="alpAACa API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(predictions.router)
app.include_router(profiles.router)
app.include_router(tiles.router)
app.include_router(schedule.router)
app.include_router(boards.router)
