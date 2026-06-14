"""
Async MongoDB access layer (Motor).

The whole backend talks to Mongo exclusively through this module. Every document
is namespaced by ``owner`` (the JWT ``sub`` claim) and, for child-scoped data, by
``profile_id`` so that callers can only ever touch their own records.

Connection string comes from the ``MONGO_URI`` environment variable.
"""

import os
from typing import Optional

from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorGridFSBucket

MONGO_URI = os.getenv("MONGO_URI")

# ---- GLOBALS (created at runtime, NOT import time) ----
client: Optional[AsyncIOMotorClient] = None
db = None

profiles = None
tiles = None
schedules = None
boards = None
board_files = None


async def init_db() -> None:
    """Create Mongo connection + indexes. Must run inside FastAPI lifespan."""

    global client, db, profiles, tiles, schedules, boards, board_files

    # Create client INSIDE running event loop (IMPORTANT FIX)
    client = AsyncIOMotorClient(MONGO_URI)
    db = client["aac"]

    # Collections
    profiles = db["profiles"]
    tiles = db["tiles"]
    schedules = db["schedules"]
    boards = db["boards"]

    # GridFS bucket
    board_files = AsyncIOMotorGridFSBucket(db, bucket_name="boards_files")

    # Indexes (idempotent)
    await profiles.create_index([("owner", 1), ("profile_id", 1)], unique=True)

    await tiles.create_index([("owner", 1), ("profile_id", 1)])
    await tiles.create_index(
        [("owner", 1), ("profile_id", 1), ("tile_id", 1)],
        unique=True,
    )

    await schedules.create_index([("owner", 1), ("profile_id", 1)], unique=True)

    await boards.create_index([("owner", 1), ("profile_id", 1)])
    await boards.create_index(
        [("owner", 1), ("profile_id", 1), ("board_id", 1)],
        unique=True,
    )


async def require_profile(owner: str, profile_id: str) -> dict:
    """Return the profile doc or raise 404 if it isn't owned by `owner`."""

    if profiles is None:
        raise RuntimeError("Database not initialized. Did you forget init_db()?")

    profile = await profiles.find_one(
        {"owner": owner, "profile_id": profile_id}
    )

    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found",
        )

    return profile


async def close_db() -> None:
    """Optional cleanup on shutdown."""
    global client
    if client:
        client.close()