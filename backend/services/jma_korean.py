"""Conservative Korean rendering of JMA's fixed regional forecast phrases.

Translate the whole field only when every token is recognized. Never discard
unrecognized qualifications, infer numeric wind/swell values, or alter the raw
forecast. No external translation service receives user or forecast data.
"""
import re
import unicodedata


TERMS = {
    '晴れ': '맑음', '晴': '맑음', 'くもり': '흐림', '曇り': '흐림', '曇': '흐림',
    '雨か雪': '비 또는 눈', '雪か雨': '눈 또는 비', '雨': '비', '雪': '눈',
    'みぞれ': '진눈깨비', '霧': '안개', '雷を伴う': '천둥 동반',
    '雷を伴い': '천둥을 동반하며', '激しく降る': '매우 강하게 내림',
    '強く降る': '강하게 내림', 'ふぶく': '눈보라',
    '所により': '곳에 따라', 'ところにより': '곳에 따라',
    '時々': '가끔', '時折': '때때로', '一時': '한때', 'のち': ', 이후', '後': ', 이후',
    'ただし': ', 다만', 'または': '또는', 'か': '또는',
    '未明': '이른 새벽', '明け方': '새벽', '朝': '아침', '午前中': '오전',
    '昼前': '늦은 오전', '昼過ぎ': '이른 오후', '昼頃': '정오 무렵',
    '昼過ぎから夕方': '이른 오후부터 저녁까지',
    '夕方': '저녁', '夜のはじめ頃': '초저녁', '夜遅く': '늦은 밤',
    '夜': '밤', '昼': '낮', 'はじめ': '초반', '初め': '초반',
    'から': '부터', 'にかけて': '까지', 'まで': '까지', '頃': '무렵',
    '海上では': '· 해상에서는', '海上で': '· 해상에서',
    'では': '에서는', 'で': '에서', '海上': '해상', '海岸': '해안',
    '山地': '산지', '山沿い': '산간', '平地': '평지', '内陸': '내륙',
    '北部': '북부', '南部': '남부', '東部': '동부', '西部': '서부',
    '瀬戸内側': '세토내해 쪽', '対馬海峡': '쓰시마 해협',
    'うねりを伴う': '너울 동반', 'うねりを伴い': '너울을 동반하며',
    'やや強く': '다소 강함', '非常に強く': '매우 강함',
    '強く': '강함', '弱く': '약함', 'やや高く': '다소 높음', '高く': '높음',
    'メートル': 'm', 'm': 'm', '以上': '이상', '以下': '이하',
    '、': ',', '。': '.', '・': '·', '(': '(', ')': ')', '〜': '~', '~': '~',
}
for japanese, korean in {
    '北': '북', '北東': '북동', '東': '동', '南東': '남동',
    '南': '남', '南西': '남서', '西': '서', '北西': '북서',
}.items():
    TERMS[japanese + 'の風'] = korean + '풍'
TOKENS = sorted(TERMS, key=len, reverse=True)
NUMBER = re.compile(r'\d+(?:\.\d+)?')


def translate_forecast(text):
    if not isinstance(text, str) or not text.strip():
        return None
    source = ''.join(unicodedata.normalize('NFKC', text).split())
    pieces, position = [], 0
    while position < len(source):
        number = NUMBER.match(source, position)
        if number:
            pieces.append(number.group())
            position = number.end()
            continue
        token = next((t for t in TOKENS if source.startswith(t, position)), None)
        if token is None:
            return None
        pieces.append(TERMS[token])
        position += len(token)
    if len(pieces) > 1 and pieces[0] in ('맑음', '흐림', '비', '눈') and not pieces[1].startswith(','):
        pieces[0] += ','
    result = ' '.join(pieces)
    for suffix in ('부터', '까지', '에서는', '에서'):
        result = result.replace(' ' + suffix, suffix)
    result = result.replace(' ,', ',').replace(' .', '.').replace('( ', '(').replace(' )', ')')
    return result


def localize_reference(result):
    # Apply after reading the raw cache so older entries also gain localization.
    return {**result, 'days': [
        {**day, 'ko': {field: translate_forecast(day.get(field))
                      for field in ('waves', 'winds', 'weathers')}}
        for day in result.get('days', [])
    ]}
