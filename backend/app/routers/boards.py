"""Saved boards. Raw .obf/.obz bytes live in GridFS; metadata in a collection."""
import uuid

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse

from app.auth import get_current_user
from app import db
from app.schemas import BoardMeta

router = APIRouter(prefix="/api/profiles/{profile_id}/boards", tags=["boards"])

_CHUNK = 256 * 1024


def _clean(doc: dict) -> dict:
    doc.pop("_id", None)
    doc.pop("owner", None)
    doc.pop("profile_id", None)
    doc.pop("file_id", None)
    return doc


@router.get("")
async def list_boards(
    profile_id: str, user: dict = Depends(get_current_user)
) -> list[dict]:
    owner = user["sub"]
    await db.require_profile(owner, profile_id)
    cursor = db.boards.find({"owner": owner, "profile_id": profile_id})
    return [_clean(doc) async for doc in cursor]


@router.post("", status_code=status.HTTP_201_CREATED)
async def upload_board(
    profile_id: str,
    file: UploadFile = File(...),
    name: str | None = Form(None),
    board_id: str | None = Form(None),
    uploadedAt: str | None = Form(None),
    user: dict = Depends(get_current_user),
) -> BoardMeta:
    owner = user["sub"]
    await db.require_profile(owner, profile_id)

    board_id = board_id or uuid.uuid4().hex
    filename = file.filename or f"{board_id}.obz"
    name = name or filename

    # If a board with this id already exists, drop its old GridFS blob first.
    existing = await db.boards.find_one(
        {"owner": owner, "profile_id": profile_id, "board_id": board_id}
    )
    if existing and existing.get("file_id") is not None:
        try:
            await db.board_files.delete(existing["file_id"])
        except Exception:
            pass

    data = await file.read()
    file_id = await db.board_files.upload_from_stream(
        filename, data, metadata={"owner": owner, "profile_id": profile_id}
    )

    meta = BoardMeta(
        board_id=board_id,
        name=name,
        filename=filename,
        contentType=file.content_type,
        uploadedAt=uploadedAt,
    )
    await db.boards.update_one(
        {"owner": owner, "profile_id": profile_id, "board_id": board_id},
        {
            "$set": {
                **meta.model_dump(),
                "owner": owner,
                "profile_id": profile_id,
                "file_id": file_id,
            }
        },
        upsert=True,
    )
    return meta


@router.get("/{board_id}/file")
async def download_board(
    profile_id: str, board_id: str, user: dict = Depends(get_current_user)
):
    owner = user["sub"]
    await db.require_profile(owner, profile_id)
    board = await db.boards.find_one(
        {"owner": owner, "profile_id": profile_id, "board_id": board_id}
    )
    if board is None or board.get("file_id") is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Board not found"
        )

    stream = await db.board_files.open_download_stream(board["file_id"])

    async def _iter():
        while True:
            chunk = await stream.readchunk()
            if not chunk:
                break
            yield chunk

    media_type = board.get("contentType") or "application/octet-stream"
    headers = {
        "Content-Disposition": f'attachment; filename="{board.get("filename", board_id)}"'
    }
    return StreamingResponse(_iter(), media_type=media_type, headers=headers)


@router.delete("/{board_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_board(
    profile_id: str, board_id: str, user: dict = Depends(get_current_user)
):
    owner = user["sub"]
    await db.require_profile(owner, profile_id)
    board = await db.boards.find_one(
        {"owner": owner, "profile_id": profile_id, "board_id": board_id}
    )
    if board is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Board not found"
        )
    if board.get("file_id") is not None:
        try:
            await db.board_files.delete(board["file_id"])
        except Exception:
            pass
    await db.boards.delete_one(
        {"owner": owner, "profile_id": profile_id, "board_id": board_id}
    )
