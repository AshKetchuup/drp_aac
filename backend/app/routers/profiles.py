"""Child-profile CRUD. Every operation is scoped to the JWT ``sub`` (owner)."""
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import get_current_user
from app import db
from app.schemas import Profile

router = APIRouter(prefix="/api/profiles", tags=["profiles"])


def _clean(doc: dict) -> dict:
    """Strip Mongo's ``_id`` and the internal ``owner`` field before returning."""
    doc.pop("_id", None)
    doc.pop("owner", None)
    return doc


@router.get("")
async def list_profiles(user: dict = Depends(get_current_user)) -> list[dict]:
    owner = user["sub"]
    cursor = db.profiles.find({"owner": owner})
    return [_clean(doc) async for doc in cursor]


@router.post("")
async def upsert_profile(
    profile: Profile, user: dict = Depends(get_current_user)
) -> dict:
    owner = user["sub"]
    doc = profile.model_dump()
    await db.profiles.update_one(
        {"owner": owner, "profile_id": profile.profile_id},
        {"$set": {**doc, "owner": owner}},
        upsert=True,
    )
    return doc


@router.delete("/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(profile_id: str, user: dict = Depends(get_current_user)):
    owner = user["sub"]
    result = await db.profiles.delete_one({"owner": owner, "profile_id": profile_id})
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found"
        )

    # Cascade: drop the profile's tiles, schedule and board files + metadata.
    await db.tiles.delete_many({"owner": owner, "profile_id": profile_id})
    await db.schedules.delete_many({"owner": owner, "profile_id": profile_id})

    async for board in db.boards.find({"owner": owner, "profile_id": profile_id}):
        file_id = board.get("file_id")
        if file_id is not None:
            try:
                await db.board_files.delete(file_id)
            except Exception:
                # File already gone — metadata cleanup below still proceeds.
                pass
    await db.boards.delete_many({"owner": owner, "profile_id": profile_id})
