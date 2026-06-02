"""관리자 대시보드 — 골프장 취소 정책 관리"""

import os
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db

router = APIRouter(prefix="/admin", tags=["admin"])

# 환경변수 기반 단순 패스워드 보호 (프로덕션에서는 OAuth 등으로 교체)
_ADMIN_TOKEN = os.getenv("ADMIN_TOKEN", "dev-secret-change-me")


def _check_token(request: Request) -> bool:
    token = request.cookies.get("admin_token") or request.headers.get("X-Admin-Token")
    return token == _ADMIN_TOKEN


_HTML_HEAD = """<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>켜자마자 날씨 — 관리자</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0d1b2a; color: #cdd3d9; font-family: -apple-system, sans-serif; padding: 24px; }
  h1 { color: #fff; margin-bottom: 4px; font-size: 1.4rem; }
  .subtitle { color: #6b7a8b; font-size: 0.85rem; margin-bottom: 24px; }
  nav { margin-bottom: 24px; }
  nav a { color: #2E7D6B; margin-right: 16px; text-decoration: none; font-weight: 600; }
  .card { background: #1c2b3a; border-radius: 12px; padding: 20px; margin-bottom: 16px; }
  .card h2 { color: #fff; font-size: 1rem; margin-bottom: 12px; }
  table { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
  th { text-align: left; color: #6b7a8b; padding: 6px 8px; border-bottom: 1px solid #243447; }
  td { padding: 8px; border-bottom: 1px solid #1c2b3a; vertical-align: top; }
  tr:hover td { background: #243447; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 0.75rem; font-weight: 600; }
  .badge-green { background: #1b3a2f; color: #4caf50; }
  .badge-grey { background: #243447; color: #6b7a8b; }
  .btn { display: inline-block; padding: 6px 14px; border-radius: 8px; border: none; cursor: pointer;
         font-size: 0.85rem; text-decoration: none; font-weight: 600; }
  .btn-primary { background: #2E7D6B; color: #fff; }
  .btn-danger { background: #7a1c1c; color: #ff8a80; }
  .btn-secondary { background: #243447; color: #cdd3d9; border: 1px solid #36485a; }
  form label { display: block; color: #6b7a8b; font-size: 0.82rem; margin: 10px 0 4px; }
  form input, form textarea, form select {
    width: 100%; background: #243447; border: 1px solid #36485a; color: #cdd3d9;
    padding: 8px 10px; border-radius: 8px; font-size: 0.9rem; }
  form textarea { resize: vertical; min-height: 60px; }
  .alert { padding: 10px 14px; border-radius: 8px; margin-bottom: 16px; font-size: 0.88rem; }
  .alert-error { background: #3a1c1c; color: #ff8a80; border: 1px solid #7a1c1c; }
  .alert-success { background: #1b3a2f; color: #69e0a0; border: 1px solid #1b5c3a; }
  .stat-row { display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 20px; }
  .stat { background: #1c2b3a; border-radius: 10px; padding: 14px 20px; flex: 1; min-width: 140px; }
  .stat .num { font-size: 1.6rem; font-weight: 700; color: #fff; }
  .stat .lbl { font-size: 0.78rem; color: #6b7a8b; margin-top: 2px; }
  .login-wrap { max-width: 360px; margin: 80px auto; }
</style>
</head>
<body>
"""

_HTML_FOOT = "</body></html>"


@router.get("/login", response_class=HTMLResponse)
async def login_page(error: Optional[str] = None):
    err_html = f'<div class="alert alert-error">{error}</div>' if error else ''
    return _HTML_HEAD + f"""
<div class="login-wrap">
  <h1>🌤️ 켜자마자 날씨</h1>
  <p class="subtitle">관리자 로그인</p>
  {err_html}
  <div class="card">
    <form method="post" action="/admin/login">
      <label>관리자 토큰</label>
      <input type="password" name="token" placeholder="ADMIN_TOKEN" autofocus>
      <br><br>
      <button type="submit" class="btn btn-primary" style="width:100%">로그인</button>
    </form>
  </div>
</div>
""" + _HTML_FOOT


@router.post("/login")
async def do_login(token: str = Form(...)):
    if token != _ADMIN_TOKEN:
        return RedirectResponse("/admin/login?error=잘못된+토큰입니다", status_code=302)
    resp = RedirectResponse("/admin/dashboard", status_code=302)
    resp.set_cookie("admin_token", token, httponly=True, samesite="strict")
    return resp


@router.get("/logout")
async def logout():
    resp = RedirectResponse("/admin/login", status_code=302)
    resp.delete_cookie("admin_token")
    return resp


@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request, db: AsyncSession = Depends(get_db)):
    if not _check_token(request):
        return RedirectResponse("/admin/login", status_code=302)

    # 통계
    stats = (await db.execute(text("""
        SELECT
          (SELECT COUNT(*) FROM golf_courses) AS golf_count,
          (SELECT COUNT(*) FROM fishing_spots) AS spot_count,
          (SELECT COUNT(*) FROM user_devices) AS device_count,
          (SELECT COUNT(*) FROM user_subscriptions WHERE active = TRUE) AS sub_count,
          (SELECT COUNT(*) FROM notification_log WHERE sent_at > NOW() - INTERVAL '24 hours') AS notif_24h
    """))).mappings().first()

    # 골프장 + 정책 목록
    courses = (await db.execute(text("""
        SELECT c.course_id, c.name, c.region, c.golfzon_linked,
               p.same_day_penalty, p.noshow_penalty,
               p.rain_cancel_available, p.updated_at
        FROM golf_courses c
        LEFT JOIN course_cancellation_policies p ON p.course_id = c.course_id
        ORDER BY c.name
        LIMIT 100
    """))).mappings().all()

    rows_html = ''
    for c in courses:
        linked = '<span class="badge badge-green">골프존</span>' if c['golfzon_linked'] else '<span class="badge badge-grey">일반</span>'
        has_policy = c['same_day_penalty'] is not None
        policy_cell = (
            f"{c['same_day_penalty']}" if has_policy else '<span style="color:#6b7a8b">미등록</span>'
        )
        rain_cell = '✅' if c['rain_cancel_available'] else '—'
        rows_html += f"""
        <tr>
          <td><code style="color:#4caf50">{c['course_id']}</code></td>
          <td>{c['name']}</td>
          <td>{c['region']}</td>
          <td>{linked}</td>
          <td>{policy_cell}</td>
          <td style="text-align:center">{rain_cell}</td>
          <td>
            <a href="/admin/policy/{c['course_id']}" class="btn btn-secondary">편집</a>
          </td>
        </tr>"""

    return _HTML_HEAD + f"""
<h1>🌤️ 켜자마자 날씨 — 관리자</h1>
<p class="subtitle">날씨 데이터 및 취소 정책 관리</p>
<nav>
  <a href="/admin/dashboard">대시보드</a>
  <a href="/admin/subscriptions">구독 현황</a>
  <a href="/docs" target="_blank">API 문서</a>
  <a href="/admin/logout" style="color:#ff8a80">로그아웃</a>
</nav>

<div class="stat-row">
  <div class="stat"><div class="num">{stats['golf_count']}</div><div class="lbl">등록 골프장</div></div>
  <div class="stat"><div class="num">{stats['spot_count']}</div><div class="lbl">낚시 출조지</div></div>
  <div class="stat"><div class="num">{stats['device_count']}</div><div class="lbl">등록 디바이스</div></div>
  <div class="stat"><div class="num">{stats['sub_count']}</div><div class="lbl">활성 구독</div></div>
  <div class="stat"><div class="num">{stats['notif_24h']}</div><div class="lbl">알림 발송 (24h)</div></div>
</div>

<div class="card">
  <h2>골프장 취소 정책 관리</h2>
  <table>
    <thead>
      <tr>
        <th>ID</th><th>골프장명</th><th>지역</th><th>유형</th>
        <th>당일 취소</th><th>우천 정책</th><th>액션</th>
      </tr>
    </thead>
    <tbody>{rows_html}</tbody>
  </table>
</div>
""" + _HTML_FOOT


@router.get("/policy/{course_id}", response_class=HTMLResponse)
async def edit_policy_page(
    course_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    msg: Optional[str] = None,
):
    if not _check_token(request):
        return RedirectResponse("/admin/login", status_code=302)

    course = (await db.execute(
        text("SELECT name, region FROM golf_courses WHERE course_id = :id"),
        {"id": course_id},
    )).mappings().first()
    if not course:
        raise HTTPException(404, "골프장을 찾을 수 없습니다")

    policy = (await db.execute(
        text("SELECT * FROM course_cancellation_policies WHERE course_id = :id"),
        {"id": course_id},
    )).mappings().first()

    def v(field, default=''):
        return policy[field] if policy and policy[field] is not None else default

    checked = 'checked' if v('rain_cancel_available', False) else ''
    msg_html = f'<div class="alert alert-success">{msg}</div>' if msg else ''

    return _HTML_HEAD + f"""
<h1>🌤️ 취소 정책 편집</h1>
<p class="subtitle">{course['name']} ({course['region']})</p>
<nav>
  <a href="/admin/dashboard">← 대시보드</a>
</nav>
{msg_html}
<div class="card">
  <form method="post" action="/admin/policy/{course_id}">
    <label>당일 취소 페널티</label>
    <input name="same_day_penalty" value="{v('same_day_penalty')}" placeholder="예: 그린피의 50%">

    <label>노쇼 페널티</label>
    <input name="noshow_penalty" value="{v('noshow_penalty')}" placeholder="예: 그린피의 100% + 다음 예약 불가">

    <label>무료 취소 마감 (시간 전)</label>
    <input name="free_cancel_hours" type="number" value="{v('free_cancel_hours', 24)}" min="0" max="168">

    <label>무료 취소 설명</label>
    <input name="free_cancel_desc" value="{v('free_cancel_desc')}" placeholder="예: 라운딩 전날 18:00까지 무료 취소">

    <label>
      <input type="checkbox" name="rain_cancel_available" value="1" {checked}
             style="width:auto;margin-right:6px">
      우천 취소 특별 정책 있음
    </label>

    <label>우천 취소 조건 (있을 경우)</label>
    <input name="rain_cancel_condition" value="{v('rain_cancel_condition')}"
           placeholder="예: 라운드 전날까지 강수 확률 70% 이상 시 무료 취소">

    <label>우천 환불 규정</label>
    <input name="rain_refund_rule" value="{v('rain_refund_rule')}"
           placeholder="예: 그린피 전액 환불">

    <br><br>
    <button type="submit" class="btn btn-primary">저장</button>
    &nbsp;
    <a href="/admin/dashboard" class="btn btn-secondary">취소</a>
  </form>
</div>
""" + _HTML_FOOT


@router.post("/policy/{course_id}", response_class=HTMLResponse)
async def save_policy(
    course_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    same_day_penalty: str = Form(''),
    noshow_penalty: str = Form(''),
    free_cancel_hours: int = Form(24),
    free_cancel_desc: str = Form(''),
    rain_cancel_available: Optional[str] = Form(None),
    rain_cancel_condition: str = Form(''),
    rain_refund_rule: str = Form(''),
):
    if not _check_token(request):
        return RedirectResponse("/admin/login", status_code=302)

    rain_bool = rain_cancel_available == '1'

    await db.execute(
        text("""
            INSERT INTO course_cancellation_policies
            (course_id, same_day_penalty, noshow_penalty, free_cancel_hours,
             free_cancel_desc, rain_cancel_available, rain_cancel_condition, rain_refund_rule,
             updated_at)
            VALUES (:course_id, :same_day, :noshow, :hours,
                    :desc, :rain_avail, :rain_cond, :rain_rule, NOW())
            ON CONFLICT (course_id)
            DO UPDATE SET
                same_day_penalty       = EXCLUDED.same_day_penalty,
                noshow_penalty         = EXCLUDED.noshow_penalty,
                free_cancel_hours      = EXCLUDED.free_cancel_hours,
                free_cancel_desc       = EXCLUDED.free_cancel_desc,
                rain_cancel_available  = EXCLUDED.rain_cancel_available,
                rain_cancel_condition  = EXCLUDED.rain_cancel_condition,
                rain_refund_rule       = EXCLUDED.rain_refund_rule,
                updated_at             = NOW()
        """),
        {
            "course_id": course_id,
            "same_day": same_day_penalty or None,
            "noshow": noshow_penalty or None,
            "hours": free_cancel_hours,
            "desc": free_cancel_desc or None,
            "rain_avail": rain_bool,
            "rain_cond": rain_cancel_condition or None,
            "rain_rule": rain_refund_rule or None,
        },
    )
    await db.commit()
    return RedirectResponse(
        f"/admin/policy/{course_id}?msg=저장됐습니다",
        status_code=302,
    )


@router.get("/subscriptions", response_class=HTMLResponse)
async def subscriptions(request: Request, db: AsyncSession = Depends(get_db)):
    if not _check_token(request):
        return RedirectResponse("/admin/login", status_code=302)

    rows = (await db.execute(text("""
        SELECT s.sub_id, s.activity_type, s.target_id, s.event_date,
               s.event_title, s.last_status, s.last_notified,
               d.platform
        FROM user_subscriptions s
        LEFT JOIN user_devices d ON d.user_token = s.user_token
        WHERE s.active = TRUE AND s.event_date >= CURRENT_DATE
        ORDER BY s.event_date
        LIMIT 200
    """))).mappings().all()

    rows_html = ''
    for r in rows:
        status_color = {'GREEN': '#4caf50', 'YELLOW': '#ffc107', 'RED': '#f44336'}.get(
            r['last_status'] or '', '#6b7a8b'
        )
        rows_html += f"""
        <tr>
          <td>{r['sub_id']}</td>
          <td>{r['activity_type']}</td>
          <td><code>{r['target_id']}</code></td>
          <td>{r['event_date']}</td>
          <td>{r['event_title'] or '—'}</td>
          <td style="color:{status_color}">{r['last_status'] or '—'}</td>
          <td>{str(r['last_notified'])[:16] if r['last_notified'] else '—'}</td>
          <td>{r['platform'] or '—'}</td>
        </tr>"""

    return _HTML_HEAD + f"""
<h1>🌤️ 구독 현황</h1>
<p class="subtitle">활성 날씨 알림 구독 목록</p>
<nav>
  <a href="/admin/dashboard">← 대시보드</a>
</nav>
<div class="card">
  <h2>활성 구독 ({len(rows)}건)</h2>
  <table>
    <thead>
      <tr><th>#</th><th>유형</th><th>대상 ID</th><th>일정일</th><th>제목</th>
          <th>최근 상태</th><th>마지막 알림</th><th>플랫폼</th></tr>
    </thead>
    <tbody>{rows_html}</tbody>
  </table>
</div>
""" + _HTML_FOOT
