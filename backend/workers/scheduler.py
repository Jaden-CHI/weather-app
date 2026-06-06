"""배치 스케줄러 — 골프 + 해양 데이터 주기적 수집"""

import asyncio
import os

from .weather_collector import run_golf_collection
from .marine_collector import run_marine_collection
from .notification_worker import run_notification_check
from models.database import AsyncSessionLocal, init_schema, seed_data


async def ensure_database_ready() -> None:
    async with AsyncSessionLocal() as session:
        await init_schema(session)
        await seed_data(session)


async def run_once() -> None:
    print("[스케줄러] 수집 시작")
    golf_result   = await run_golf_collection()
    marine_result = await run_marine_collection()
    # 날씨 수집 후 변화 감지 → 알림 발송
    notif_result  = await run_notification_check()
    print(f"[스케줄러] 완료 — 골프: {golf_result}, 해양: {marine_result}, 알림: {notif_result}")


async def main() -> None:
    interval = int(os.getenv("WORKER_INTERVAL_MINUTES", "60")) * 60
    await ensure_database_ready()
    while True:
        await run_once()
        print(f"[스케줄러] {interval // 60}분 후 재실행 대기")
        await asyncio.sleep(interval)


if __name__ == "__main__":
    asyncio.run(main())
