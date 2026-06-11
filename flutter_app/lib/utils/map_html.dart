import 'dart:convert';

/// WebView용 지도 HTML.
///
/// Windy API 키가 있으면 Windy Map Forecast API를 사용하고, 없으면
/// OpenStreetMap + Leaflet으로 안전하게 대체합니다.
String buildMapHtml({
  required double lat,
  required double lng,
  String label = '골프장 위치',
  int zoom = 13,
  String windyApiKey = '',
}) {
  if (windyApiKey.trim().isNotEmpty) {
    return _buildWindyMapHtml(
      lat: lat,
      lng: lng,
      label: label,
      zoom: zoom,
      windyApiKey: windyApiKey.trim(),
    );
  }

  return _buildLeafletMapHtml(lat: lat, lng: lng, label: label, zoom: zoom);
}

String _sharedMapStyles(String rootId) => '''
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body, #$rootId { width: 100%; height: 100%; background: #0E2A24; }
    .course-pin {
      width: 28px;
      height: 28px;
      border-radius: 50% 50% 50% 0;
      transform: rotate(-45deg);
      background: #F7C948;
      border: 3px solid #0B2D26;
      box-shadow: 0 8px 18px rgba(0, 0, 0, 0.35);
    }
    .course-pin::after {
      content: '';
      position: absolute;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #0B2D26;
      top: 7px;
      left: 7px;
    }
    .course-label {
      min-width: max-content;
      padding: 7px 10px;
      border-radius: 14px;
      background: rgba(11, 45, 38, 0.92);
      color: #F4FBF8;
      border: 1px solid rgba(247, 201, 72, 0.75);
      font: 700 13px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      box-shadow: 0 8px 18px rgba(0, 0, 0, 0.25);
      white-space: nowrap;
    }
    .course-target {
      position: absolute;
      left: 50%;
      top: 50%;
      z-index: 1200;
      transform: translate(-50%, -100%);
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      pointer-events: none;
    }
    .course-target .course-label {
      max-width: 220px;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .leaflet-popup-content-wrapper, .leaflet-popup-tip {
      background: #143630;
      color: #F4FBF8;
      border: 1px solid rgba(244, 251, 248, 0.16);
    }
''';

String _markerOverlayScript(String label) {
  final safeLabel = jsonEncode(label.trim().isEmpty ? '골프장 위치' : label.trim());
  return '''
    const label = $safeLabel;
    document.querySelector('.course-target .course-label').textContent = label;
''';
}

String _courseTargetHtml() => '''
  <div class="course-target" aria-label="selected golf course">
    <div class="course-label"></div>
    <div class="course-pin"></div>
  </div>
''';

String _buildWindyMapHtml({
  required double lat,
  required double lng,
  required String label,
  required int zoom,
  required String windyApiKey,
}) {
  final key = jsonEncode(windyApiKey);
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
  <script src="https://unpkg.com/leaflet@1.4.0/dist/leaflet.js"></script>
  <script src="https://api.windy.com/assets/map-forecast/libBoot.js"></script>
  <style>
${_sharedMapStyles('windy')}
  </style>
</head>
<body>
  <div id="windy"></div>
${_courseTargetHtml()}
  <script>
    const options = {
      key: $key,
      lat: $lat,
      lon: $lng,
      zoom: $zoom,
      overlay: 'wind',
      level: 'surface',
      product: 'ecmwf',
      particlesAnim: 'on',
      timestamp: Date.now()
    };

    windyInit(options, function(windyAPI) {
      const map = windyAPI.map;
${_markerOverlayScript(label)}
      map.setView([$lat, $lng], $zoom);
    });
  </script>
</body>
</html>
''';
}

String _buildLeafletMapHtml({
  required double lat,
  required double lng,
  required String label,
  required int zoom,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
${_sharedMapStyles('map')}
  </style>
</head>
<body>
  <div id="map"></div>
${_courseTargetHtml()}
  <script>
    const map = L.map('map').setView([$lat, $lng], $zoom);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap'
    }).addTo(map);
${_markerOverlayScript(label)}
  </script>
</body>
</html>
''';
}
