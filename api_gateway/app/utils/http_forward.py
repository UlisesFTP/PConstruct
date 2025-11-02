from typing import Optional, Dict, Any
import httpx
from starlette.responses import JSONResponse

async def forward_json(method: str, url: str, *, headers: Optional[Dict[str, str]] = None, params: Optional[Dict[str, Any]] = None, json_body: Any = None) -> JSONResponse:
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.request(method, url, headers=headers, params=params, json=json_body)
    content = None
    if resp.content:
        try:
            content = resp.json()
        except Exception:
            content = resp.text
    return JSONResponse(status_code=resp.status_code, content=content)
