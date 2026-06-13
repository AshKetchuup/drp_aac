"""
Async MongoDB access layer (Motor).

The whole backend talks to Mongo exclusively through this module. Every document
is namespaced by ``owner`` (the JWT ``sub`` claim) and, for child-scoped data, by
``profile_id`` so that callers can only ever touch their own records.

Connection string comes from the ``MONGO_URI`` environment variable.
"""
import os

from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorGridFSBucket

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")

client: AsyncIOMotorClient = AsyncIOMotorClient(MONGO_URI)
db = client["aac"]

# Collections
profiles = db["profiles"]
tiles = db["tiles"]
schedules = db["schedules"]
boards = db["boards"]

# GridFS bucket holding the raw .obf/.obz board files (these can exceed the
# 16 MB BSON document limit, so they cannot live inline in a document).
board_files = AsyncIOMotorGridFSBucket(db, bucket_name="boards_files")


async def init_db() -> None:
    """Create indexes. Safe to call repeatedly (idempotent)."""
    await profiles.create_index([("owner", 1), ("profile_id", 1)], unique=True)
    await tiles.create_index([("owner", 1), ("profile_id", 1)])
    await tiles.create_index(
        [("owner", 1), ("profile_id", 1), ("tile_id", 1)], unique=True
    )
    await schedules.create_index([("owner", 1), ("profile_id", 1)], unique=True)
    await boards.create_index([("owner", 1), ("profile_id", 1)])
    await boards.create_index(
        [("owner", 1), ("profile_id", 1), ("board_id", 1)], unique=True
    )


async def require_profile(owner: str, profile_id: str) -> dict:
    """Return the profile doc or raise 404 if it isn't owned by ``owner``.

    Used by the tile/schedule/board routers to enforce ownership before any
    nested operation, so a user can never reach another account's children.
    """
    profile = await profiles.find_one({"owner": owner, "profile_id": profile_id})
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found",
        )
    return profile
