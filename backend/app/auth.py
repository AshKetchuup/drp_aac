"""
JWKS-based JWT authentication for the FastAPI backend.
Fetches Authentik's public signing keys via OIDC discovery and validates
incoming Bearer tokens locally — no per-request call to Authentik.
"""
import time
import httpx
import jwt as pyjwt
from jwt import PyJWKClient, exceptions as jwt_exceptions
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# ── Authentik OIDC configuration ──────────────────────────────────────────
ISSUER = "https://authentik.ismailmehmood.co.uk/application/o/drp-aac/"
DISCOVERY_URL = f"{ISSUER}.well-known/openid-configuration"
CLIENT_ID = "DkaB9fr83vOFhBoBBIJLOXBih1lBn1dM7meHEqIu"

# ── JWKS cache ────────────────────────────────────────────────────────────
_jwks_client: PyJWKClient | None = None
_jwks_client_time: float = 0
_JWKS_CACHE_TTL = 3600  # refresh keys every hour

security = HTTPBearer()


async def _get_jwks_client() -> PyJWKClient:
    """Fetch (and cache) the JWKS URI from OIDC discovery, return a PyJWKClient."""
    global _jwks_client, _jwks_client_time

    if _jwks_client and (time.time() - _jwks_client_time) < _JWKS_CACHE_TTL:
        return _jwks_client

    async with httpx.AsyncClient() as client:
        # 1. Discover the JWKS URI
        discovery_resp = await client.get(DISCOVERY_URL)
        discovery_resp.raise_for_status()
        discovery = discovery_resp.json()
        jwks_uri = discovery["jwks_uri"]

    # 2. Build a PyJWKClient pointed at the JWKS URI
    _jwks_client = PyJWKClient(jwks_uri)
    _jwks_client_time = time.time()
    return _jwks_client


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    FastAPI dependency that validates an Authentik JWT access token.
    Returns the decoded token claims on success, or raises 401.
    """
    token = credentials.credentials

    try:
        jwks_client = await _get_jwks_client()
        signing_key = jwks_client.get_signing_key_from_jwt(token)

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