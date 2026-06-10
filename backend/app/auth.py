"""
JWKS-based JWT authentication for the FastAPI backend.
Fetches Authentik's public signing keys via OIDC discovery and validates
incoming Bearer tokens locally — no per-request call to Authentik.
"""
import time
import httpx
import jwt as pyjwt
from jwt import PyJWK, exceptions as jwt_exceptions
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# ── Authentik OIDC configuration ──────────────────────────────────────────
ISSUER = "https://authentik.ismailmehmood.co.uk/application/o/drp-aac/"
DISCOVERY_URL = f"{ISSUER}.well-known/openid-configuration"
CLIENT_ID = "DkaB9fr83vOFhBoBBIJLOXBih1lBn1dM7meHEqIu"

# ── JWKS cache ────────────────────────────────────────────────────────────
_jwks_cache: dict = {}
_jwks_cache_time: float = 0
_JWKS_CACHE_TTL = 3600

security = HTTPBearer()

async def _get_jwks() -> dict:
    """Fetch (and cache) the JSON Web Key Set from Authentik via httpx."""
    global _jwks_cache, _jwks_cache_time

    if _jwks_cache and (time.time() - _jwks_cache_time) < _JWKS_CACHE_TTL:
        return _jwks_cache

    async with httpx.AsyncClient() as client:
        # 1. Discover the JWKS URI
        discovery_resp = await client.get(DISCOVERY_URL)
        discovery_resp.raise_for_status()
        jwks_uri = discovery_resp.json()["jwks_uri"]

        # 2. Fetch the actual keys
        jwks_resp = await client.get(jwks_uri)
        jwks_resp.raise_for_status()
        _jwks_cache = jwks_resp.json()
        _jwks_cache_time = time.time()

    return _jwks_cache


def _find_signing_key(token: str, jwks: dict) -> PyJWK:
    """Match the token's kid to a key in the JWKS and return a PyJWK."""
    unverified_header = pyjwt.get_unverified_header(token)
    kid = unverified_header.get("kid")

    for key_data in jwks.get("keys", []):
        if key_data.get("kid") == kid:
            return PyJWK(key_data)

    raise jwt_exceptions.PyJWKClientError("Unable to find appropriate signing key")


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    token = credentials.credentials

    try:
        jwks = await _get_jwks()
        signing_key = _find_signing_key(token, jwks)

        payload = pyjwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            issuer=ISSUER,
            audience=CLIENT_ID,
            options={
                "verify_aud": True,
                "verify_iss": True,
                "verify_exp": True,
            },
        )
        return payload

    except jwt_exceptions.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token validation failed: {str(e)}",
        )
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Could not fetch JWKS keys: {str(e)}",
        )