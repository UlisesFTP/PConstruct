from fastapi import APIRouter, HTTPException, status, Request, Response
import httpx, json, hashlib
from app.config import SERVICE_CONFIG, logger

router = APIRouter(tags=["components"])

def _map_pagination(qp):
    page = int(qp.pop("page", 0) or 0)
    page_size = int(qp.pop("page_size", 0) or 0)
    if page and page_size:
        qp["skip"] = max(page - 1, 0) * page_size
        qp["limit"] = page_size
    return qp

async def _proxy_components(request: Request):
    qp = dict(request.query_params)
    qp = _map_pagination(qp)
    base = SERVICE_CONFIG["component"]
    url = f"{base}/components/"
    try:
        r = await request.app.state.http.get(url, params=qp, follow_redirects=True)
        r.raise_for_status()
        body = r.text
        etag = hashlib.sha256(body.encode()).hexdigest()
        inm = request.headers.get("if-none-match")
        if inm == etag:
            return Response(status_code=304)
        return Response(content=body, media_type="application/json", headers={"ETag": etag})
    except httpx.HTTPStatusError as e:
        try:
            detail = e.response.json()
        except json.JSONDecodeError:
            detail = e.response.text
        raise HTTPException(status_code=e.response.status_code, detail=detail)
    except Exception as e:
        logger.error(f"Get components error: {str(e)}")
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Component service unavailable")

@router.get("/components")
async def get_components_no_slash(request: Request):
    return await _proxy_components(request)

@router.get("/components/")
async def get_components_slash(request: Request):
    return await _proxy_components(request)

@router.get("/components/{component_id}")
async def get_component(request: Request, component_id: int):
    base = SERVICE_CONFIG["component"]
    url = f"{base}/components/{component_id}"
    try:
        r = await request.app.state.http.get(url)
        if r.status_code == 404:
            raise HTTPException(status_code=404, detail="Component not found")
        r.raise_for_status()
        body = r.text
        etag = hashlib.sha256(body.encode()).hexdigest()
        inm = request.headers.get("if-none-match")
        if inm == etag:
            return Response(status_code=304)
        return Response(content=body, media_type="application/json", headers={"ETag": etag})
    except Exception as e:
        logger.error(f"Get component error: {str(e)}")
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Component service unavailable")
