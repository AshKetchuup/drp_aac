"""Custom tiles, scoped to a single child profile owned by the caller."""
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth import get_current_user
from app import db
from app.schemas import Tile

router = APIRouter(prefix="/api/profiles/{profile_id}/tiles", tags=["tiles"])


def _clean(doc: dict) -> dict:
    doc.pop("_id", None)
    doc.pop("owner", None)
    doc.pop("profile_id", None)
    return doc


@router.get("")
async def list_tiles(
    profile_id: str, user: dict = Depends(get_current_user)
) -> list[dict]:
    owner = user["sub"]
    await db.require_profile(owner, profile_id)
    cursor = db.tiles.find({"owner": owner, "profile_id": profile_id})
    return [_clean(doc) async for doc in cursor]


@router.post("")
async def upsert_tile(
    profile_id: str, tile: Tile, user: dict = Depends(get_current_user)
) -> dict:
    owner = user["sub"]
    await db.require_profile(owner, profile_id)
    doc = tile.model_dump()
    await db.tiles.update_one(
        {"owner": owner, "profile_id": profile_id, "tile_id": tile.tile_id},
        {"$set": {**doc, "owner": owner, "profile_id": profile_id}},
        upsert=True,
    )
    return doc


@router.delete("/{tile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tile(
    profile_id: str, tile_id: str, user: dict = Depends(get_current_user)
):
    owner = user["sub"]
    await db.require_profile(owner, profile_id)
    result = await db.tiles.delete_one(
        {"owner": owner, "profile_id": profile_id, "tile_id": tile_id}
    )
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Tile not found"
        )
