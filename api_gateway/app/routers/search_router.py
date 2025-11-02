from fastapi import APIRouter, HTTPException
import httpx
import asyncio
from app.config import SERVICE_CONFIG

router = APIRouter(tags=["search"])

@router.get("/search/")
async def search_all(q: str):
    async with httpx.AsyncClient(timeout=10.0) as client:
        post_search_task = client.get(
            f"{SERVICE_CONFIG['posts']}/posts/search/",
            params={"q": q}
        )
        user_search_task = client.get(
            f"{SERVICE_CONFIG['user']}/users/search/",
            params={"q": q}
        )

        results = await asyncio.gather(
            post_search_task,
            user_search_task,
            return_exceptions=True
        )

        posts_response, users_response = results

        posts = []
        if isinstance(posts_response, httpx.Response) and posts_response.status_code == 200:
            posts = posts_response.json()

        users = []
        if isinstance(users_response, httpx.Response) and users_response.status_code == 200:
            users = users_response.json()

        return {"posts": posts, "users": users}
