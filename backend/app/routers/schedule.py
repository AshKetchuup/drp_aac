"""Per-profile weekly schedule (whole-document replace)."""
from fastapi import APIRouter, Depends

from app.auth import get_current_user
from app import db
from app.schemas import Schedule

router = APIRouter(prefix="/api/profiles/{profile_id}/schedule", tags=["schedule"])


@router.get("")
async def get_schedule(
    profile_id: str, user: dict = Depends(get_current_user)
) -> Schedule:
    owner = user["sub"]
    await db.require_profile(owner, profile_id)
    doc = await db.schedules.find_one({"owner": owner, "profile_id": profile_id})
    return Schedule(data=doc.get("data", {}) if doc else {})


@router.put("")
async def put_schedule(
    profile_id: str, schedule: Schedule, user: dict = Depends(get_current_user)
) -> Schedule:
    owner = user["sub"]
    await db.require_profile(owner, profile_id)
    await db.schedules.update_one(
        {"owner": owner, "profile_id": profile_id},
        {"$set": {"owner": owner, "profile_id": profile_id, "data": schedule.data}},
        upsert=True,
    )
    return schedule
