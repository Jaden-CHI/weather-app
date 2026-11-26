"""Port catalog and independent KMA/JMA comparison (no legacy marine-cache dependency)."""
import os
import httpx
import redis.asyncio as aioredis
from fastapi import APIRouter, HTTPException, Query
from services.port_forecasts import PORTS, compare_port
from services.departure_marine import departure_info

router = APIRouter(prefix='/api/v1/marine', tags=['marine'])

@router.get('/forecast-spots')
async def ports(q: str = Query('', max_length=80)):
    keyword = q.strip().replace(' ', '').lower()
    matches = [s for s in PORTS if keyword in (s['name'] + s['name_short'] + s['region']).replace(' ', '').lower()]
    return {'results': [{k: s[k] for k in ('spot_id', 'name', 'region', 'lat', 'lon')} for s in matches]}

@router.get('/spots/{spot_id}/forecast-comparison')
async def comparison(spot_id: str):
    return await _load(spot_id, compare_port)


@router.get('/spots/{spot_id}/departure-info')
async def departure(spot_id: str):
    return await _load(spot_id, departure_info)


async def _load(spot_id, loader):
    spot = next((s for s in PORTS if s['spot_id'] == spot_id), None)
    if spot is None:
        raise HTTPException(404, '등록된 한국 항구를 선택해 주세요.')
    try:
        cache = aioredis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379/0'), decode_responses=True, socket_connect_timeout=0.5, socket_timeout=0.5)
    except (ValueError, TypeError):
        cache = None
    try:
        async with httpx.AsyncClient() as client:
            return await loader(spot, client, cache)
    finally:
        if cache is not None:
            try:
                await cache.aclose()
            except Exception:
                pass  # Cache cleanup must not discard a successful forecast.
