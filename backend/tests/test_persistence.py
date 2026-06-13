"""
Smoke test for the MongoDB persistence layer.

Exercises the full lifecycle (profile -> tile -> schedule -> board upload /
download -> cascade delete) and asserts that one owner cannot read another
owner's data.

Requires a reachable MongoDB. Point ``MONGO_URI`` at one (defaults to
localhost:27017). The test runs against a throwaway database and drops it at the
end; it is skipped automatically if no server is reachable.
"""
import asyncio
import os

import pytest

# Use an isolated throwaway database BEFORE importing the app modules, since
# app.db binds the database at import time.
os.environ["MONGO_DB"] = "aac_test_persistence"

import httpx  # noqa: E402
from httpx import ASGITransport  # noqa: E402

from app.main import app  # noqa: E402
from app import db  # noqa: E402
from app.auth import get_current_user  # noqa: E402

USER_A = {"sub": "owner-a"}
USER_B = {"sub": "owner-b"}


def _set_user(user: dict) -> None:
    app.dependency_overrides[get_current_user] = lambda: user


async def _flow() -> None:
    # Skip when no MongoDB is reachable rather than hard-failing.
    try:
        await asyncio.wait_for(db.client.admin.command("ping"), timeout=2)
    except Exception:
        pytest.skip("MongoDB not reachable; skipping persistence smoke test")

    await db.client.drop_database(os.environ["MONGO_DB"])
    await db.init_db()

    transport = ASGITransport(app=app)
    async with httpx.AsyncClient(
        transport=transport, base_url="http://test"
    ) as ac:
        # ── Owner A creates a profile ──────────────────────────────────────
        _set_user(USER_A)
        prof = {"profile_id": "child-1", "name": "Robin", "likes": ["Dogs"]}
        r = await ac.post("/api/profiles", json=prof)
        assert r.status_code == 200, r.text

        r = await ac.get("/api/profiles")
        assert r.status_code == 200
        assert [p["profile_id"] for p in r.json()] == ["child-1"]

        # ── Tile ───────────────────────────────────────────────────────────
        tile = {"tile_id": "t1", "label": "Train", "imageB64": "AAAA"}
        r = await ac.post("/api/profiles/child-1/tiles", json=tile)
        assert r.status_code == 200, r.text
        r = await ac.get("/api/profiles/child-1/tiles")
        assert r.status_code == 200
        assert r.json()[0]["label"] == "Train"

        # ── Schedule ───────────────────────────────────────────────────────
        sched = {"data": {"0_0": [{"id": "t1", "label": "Train"}]}}
        r = await ac.put("/api/profiles/child-1/schedule", json=sched)
        assert r.status_code == 200, r.text
        r = await ac.get("/api/profiles/child-1/schedule")
        assert r.json()["data"] == sched["data"]

        # ── Board upload / list / download ─────────────────────────────────
        raw = b"PK\x03\x04 fake obz bytes"
        r = await ac.post(
            "/api/profiles/child-1/boards",
            files={"file": ("my_board.obz", raw, "application/zip")},
            data={"name": "My Board", "board_id": "b1"},
        )
        assert r.status_code == 201, r.text
        r = await ac.get("/api/profiles/child-1/boards")
        assert [b["board_id"] for b in r.json()] == ["b1"]
        r = await ac.get("/api/profiles/child-1/boards/b1/file")
        assert r.status_code == 200
        assert r.content == raw

        # ── Ownership isolation: owner B sees nothing of A's ───────────────
        _set_user(USER_B)
        r = await ac.get("/api/profiles")
        assert r.json() == []
        # B cannot reach A's child profile (404, not data leak).
        r = await ac.get("/api/profiles/child-1/tiles")
        assert r.status_code == 404
        r = await ac.get("/api/profiles/child-1/boards/b1/file")
        assert r.status_code == 404

        # ── Cascade delete by owner A ──────────────────────────────────────
        _set_user(USER_A)
        r = await ac.delete("/api/profiles/child-1")
        assert r.status_code == 204
        assert await db.tiles.count_documents({"owner": "owner-a"}) == 0
        assert await db.schedules.count_documents({"owner": "owner-a"}) == 0
        assert await db.boards.count_documents({"owner": "owner-a"}) == 0
        # GridFS blob is gone too.
        r = await ac.get("/api/profiles/child-1/boards/b1/file")
        assert r.status_code == 404

    await db.client.drop_database(os.environ["MONGO_DB"])
    app.dependency_overrides.clear()


def test_persistence_lifecycle():
    asyncio.run(_flow())
