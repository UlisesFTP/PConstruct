from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse
from typing import Any, Dict, List, Optional, Tuple
import asyncio
import httpx
import json
import logging
from datetime import datetime, timezone, timedelta

from app.config import SERVICE_CONFIG, REDIS_URL, PRICE_TTL_HOURS, RETAILERS

router = APIRouter(prefix="/catalog", tags=["catalog"])
logger = logging.getLogger("catalog")



TIMEOUT = httpx.Timeout(connect=5.0, read=20.0, write=10.0, pool=10.0)
HTTPX_OPTS = dict(timeout=TIMEOUT, follow_redirects=True)  # add this



try:
    # redis >=5
    import redis.asyncio as redis
except Exception:  # pragma: no cover
    redis = None

_redis: Optional["redis.Redis"] = None

def _price_base() -> str:
    base = SERVICE_CONFIG.get("price")
    if not base:
        raise RuntimeError("SERVICE_CONFIG['price'] is not set")
    return base.rstrip("/")

def _component_base() -> str:
    base = SERVICE_CONFIG.get("component")
    if not base:
        raise RuntimeError("SERVICE_CONFIG['component'] is not set")
    return base.rstrip("/")

def _parse_iso(ts: Optional[str]) -> Optional[datetime]:
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except Exception:
        return None

def _is_stale(seen_at: Optional[str]) -> bool:
    dt = _parse_iso(seen_at)
    if not dt:
        return True
    ttl = timedelta(hours=PRICE_TTL_HOURS or 24)
    return datetime.now(timezone.utc) - dt > ttl

async def _get_redis() -> Optional["redis.Redis"]:
    global _redis
    if redis is None:
        return None
    if _redis is None:
        _redis = redis.from_url(REDIS_URL, decode_responses=True)
    return _redis
async def _get_components(params: Dict[str, Any]) -> Dict[str, Any]:
    qparams = {}

    # category → UPPER (service likely stores categories as CPU/GPU/…)
    if "category" in params and params["category"]:
        qparams["category"] = str(params["category"]).upper()

    # send both brand and manufacturer to maximize compatibility
    if "brand" in params and params["brand"]:
        br = str(params["brand"])
        qparams["brand"] = br
        qparams["manufacturer"] = br

    if "q" in params and params["q"]:
        qparams["q"] = params["q"]

    if "page" in params:      qparams["page"] = params["page"]
    if "page_size" in params: qparams["page_size"] = params["page_size"]
    if "sort" in params:      qparams["sort"] = params["sort"]

    async with httpx.AsyncClient(timeout=TIMEOUT, follow_redirects=True) as client:
        r = await client.get(f"{_component_base()}/components/", params=qparams)
        if r.status_code != 200:
            raise HTTPException(status_code=502, detail=f"component-service {r.status_code}")
        data = r.json()
        if isinstance(data, list):
            return {"page": 1, "page_size": len(data), "total": len(data), "items": data}
        if isinstance(data, dict) and "items" in data:
            return data
        return {"page": 1, "page_size": len(data or []), "total": len(data or []), "items": data or []}


async def _batch_quotes(component_ids: List[int]) -> Dict[str, Any]:
    if not component_ids:
        return {}
    async with httpx.AsyncClient(**HTTPX_OPTS) as client:
        # Call gateway’s own /prices/batch or pricing-service directly; we go direct
        try:
            # We implemented gateway-side batch already, but this works either way
            r = await client.post(f"{_price_base()}/prices/refresh", json={"component_ids": component_ids, "countries": ["MX"]})
        except Exception:
            # ignore refresh errors; quotes may already exist
            pass
        quotes = {}
        async def fetch_one(cid: int):
            try:
                rr = await client.get(f"{_price_base()}/prices/{cid}")
                if rr.status_code == 200:
                    quotes[str(cid)] = rr.json()
                else:
                    quotes[str(cid)] = []
            except Exception as e:
                quotes[str(cid)] = []
        await asyncio.gather(*(fetch_one(cid) for cid in component_ids))
        return quotes

def _best_price(quotes: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    if not quotes:
        return None
    usable = []
    for q in quotes:
        if not isinstance(q, dict): 
            continue
        retailer = (q.get("retailer") or "").lower()
        if retailer not in RETAILERS:
            continue
        price = q.get("mxn") or q.get("price_mxn") or q.get("price")
        try:
            price = float(price)
        except Exception:
            continue
        usable.append({
            "mxn": price,
            "retailer": retailer,
            "url": q.get("url"),
            "seen_at": q.get("seen_at"),
        })
    if not usable:
        return None
    usable.sort(key=lambda x: x["mxn"])
    top = usable[0]
    top["stale"] = _is_stale(top.get("seen_at"))
    return top

@router.get("/components")
async def catalog_components(request: Request):
    params = dict(request.query_params)
    # normalize budget
    norm_max = None
    b = params.get("budget_lte")
    m = params.get("max_price")
    try:
        if b is not None: norm_max = float(b)
        if m is not None:
            mv = float(m)
            norm_max = mv if norm_max is None else min(norm_max, mv)
    except Exception:
        pass

    env = await _get_redis()
    comp = await _get_components(params)
    items = comp.get("items", [])
    ids: List[int] = []
    for it in items:
        raw_id = it.get("id") or it.get("component_id") or it.get("id_component")
        try:
            if raw_id is not None:
                ids.append(int(raw_id))
        except Exception:
            pass

    # Try Redis cache best_price first
    cached: Dict[int, Optional[Dict[str, Any]]] = {}
    if env:
        pipe = env.pipeline()
        for cid in ids:
            pipe.get(f"best_price:{cid}")
        raw = await pipe.execute()
        for cid, val in zip(ids, raw):
            cached[cid] = json.loads(val) if val else None

    missing = [cid for cid in ids if not cached.get(cid)]
    quote_map: Dict[str, Any] = {}
    if missing:
        quote_map = await _batch_quotes(missing)

    # Assemble response
    out_items = []
    for it in items:
        raw_id = it.get("id") or it.get("component_id") or it.get("id_component")
        cid = None
        try:
            if raw_id is not None:
                cid = int(raw_id)
        except Exception:
            cid = None

        # brand may be nested object or plain string
        brand_val = it.get("brand")
        if isinstance(brand_val, dict):
            brand_name = brand_val.get("name")
        else:
            brand_name = brand_val

        # compute best price (only if we have a numeric id)
        bp = None
        if cid is not None:
            if cid in cached and cached[cid]:
                bp = cached[cid]
                if isinstance(bp, dict):
                    bp["stale"] = _is_stale(bp.get("seen_at"))
            else:
                quotes = quote_map.get(str(cid), [])
                bp = _best_price(quotes)
                if env and bp:
                    await env.setex(
                        f"best_price:{cid}",
                        int(timedelta(hours=PRICE_TTL_HOURS or 24).total_seconds()),
                        json.dumps(bp),
                    )

        # price filter if norm_max present
        if norm_max is not None and bp and isinstance(bp, dict):
            try:
                if float(bp.get("mxn", 0.0)) > norm_max:
                    continue
            except Exception:
                pass

        out_items.append({
            "id": cid,  # may be null/None if service didn’t send an id
            "name": it.get("name") or it.get("model") or it.get("title"),
            "category": it.get("category"),
            "brand": brand_name,
            "image_url": it.get("image_url") or it.get("image"),
            "best_price": bp
        })