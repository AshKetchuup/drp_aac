from pydantic import BaseModel, Field


class PredictionRequest(BaseModel):
    text: str = ""
    likes: list[str] = []
    dislikes: list[str] = []
    current_suggestions: list[str] = []
    min_suggestions: int = 4


class PredictionResponse(BaseModel):
    predictions: list[str]


# ── Persistence models ─────────────────────────────────────────────────────
# These mirror the Flutter client models so JSON round-trips cleanly. ``owner``
# is never accepted from the client — it is always taken from the validated JWT.


class Profile(BaseModel):
    """A child profile belonging to a teacher account. Mirrors Flutter
    ``UserProfile`` (frontend/lib/models/models.dart)."""

    profile_id: str
    name: str
    age: int | None = None
    pronoun: str | None = None
    avatarId: str = "avatar_1"
    likes: list[str] = []
    dislikes: list[str] = []
    currentMood: str | None = None
    createdAt: str | None = None


class Tile(BaseModel):
    """A custom communication tile. Mirrors the persistable parts of the Flutter
    ``Symbol`` model. Drawn-icon / photo images travel inline as base64."""

    tile_id: str
    label: str
    category: str = "noun"
    iconCodePoint: int | None = None
    imageB64: str | None = None
    isSvg: bool = False
    backgroundColor: int | None = None
    borderColor: int | None = None


class Schedule(BaseModel):
    """Whole-schedule replacement payload. ``data`` is the serialized
    ``{"<dayIndex>_<slotIndex>": [symbolJson, ...]}`` map produced by the Flutter
    LocalScheduleRepository."""

    data: dict = Field(default_factory=dict)


class BoardMeta(BaseModel):
    """Metadata for a saved board whose raw bytes live in GridFS."""

    board_id: str
    name: str
    filename: str
    contentType: str | None = None
    uploadedAt: str | None = None
