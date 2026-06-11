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
    .map-caption {
      position: absolute;
      left: 14px;
      top: 14px;
      z-index: 999;
      padding: 8px 12px;
      border-radius: 16px;
      background: rgba(11, 45, 38, 0.9);
      color: #F4FBF8;
      border: 1px solid rgba(244, 251, 248, 0.18);
      font: 700 13px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      pointer-events: none;
    }
    .leaflet-popup-content-wrapper, .leaflet-popup-tip {
      background: #143630;
      color: #F4FBF8;
      border: 1px solid rgba(244, 251, 248, 0.16);
    }
''';

String _markerScript({
  required double lat,
  required double lng,
  required String label,
  required String caption,
}) {
  final safeLabel = jsonEncode(label.trim().isEmpty ? '골프장 위치' : label.trim());
  final safeCaption = jsonEncode(caption);
  return '''
    const label = $safeLabel;
    document.querySelector('.map-caption').textContent = $safeCaption;
    const pinIcon = L.divIcon({
      className: '',
      html: '<div class="course-pin"></div>',
      iconSize: [28, 28],
      iconAnchor: [14, 28],
      popupAnchor: [0, -30]
    });
    const labelIcon = L.divIcon({
      className: '',
      html: '<div class="course-label">' + label.replace(/[&<>]/g, function(c) {
        return {'&':'&amp;','<':'&lt;','>':'&gt;'}[c];
      }) + '</div>',
      iconSize: null,
      iconAnchor: [-18, 34]
    });
    L.marker([$lat, $lng], { icon: pinIcon }).addTo(map).bindPopup(label).openPopup();
    L.marker([$lat, $lng], { icon: labelIcon, interactive: false }).addTo(map);
''';
}

String _buildWindyMapHtml({
  required double lat,
  required double lng,
  required String label,
  required int zoom,
  required String windyApiKey,
}) {
  final key = jsonEncode(windyApiKey);
  final caption = '${label.trim().isEmpty ? '골프장' : label.trim()} 위치 기준 바람 예보';
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <script src="https://unpkg.com/leaflet@1.4.0/dist/leaflet.js"></script>
  <script src="https://api.windy.com/assets/map-forecast/libBoot.js"></script>
  <style>
${_sharedMapStyles('windy')}
  </style>
</head>
<body>
  <div id="windy"></div>
  <div class="map-caption"></div>
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
${_markerScript(lat: lat, lng: lng, label: label, caption: caption)}
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
  final caption = '${label.trim().isEmpty ? '골프장' : label.trim()} 위치 기준 지도';
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
${_sharedMapStyles('map')}
  </style>
</head>
<body>
  <div id="map"></div>
  <div class="map-caption"></div>
  <script>
    const map = L.map('map').setView([$lat, $lng], $zoom);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap'
    }).addTo(map);
${_markerScript(lat: lat, lng: lng, label: label, caption: caption)}
  </script>
</body>
</html>
''';
}
