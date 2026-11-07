"""Static regression checks; does not replace native installation tests."""
import json
import plistlib
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[1]
layout = root / 'android/app/src/main/res/layout/golf_weather_widget.xml'
allowed = {'LinearLayout', 'FrameLayout', 'RelativeLayout', 'TextView', 'ImageView',
           'Button', 'ImageButton', 'ProgressBar', 'Chronometer', 'TextClock'}
for element in ET.parse(layout).iter():
    assert element.tag in allowed, f'Unsupported RemoteViews element: {element.tag}'

project = json.loads(subprocess.check_output([
    'plutil', '-convert', 'json', '-o', '-', str(root / 'ios/Runner.xcodeproj/project.pbxproj')
]))
objects = project['objects']
runner = next(x for x in objects.values() if x.get('isa') == 'PBXNativeTarget' and x.get('name') == 'Runner')
widget_id, widget = next((k, x) for k, x in objects.items()
                         if x.get('isa') == 'PBXNativeTarget' and x.get('name') == 'GolfWeatherWidget')
assert widget['productType'] == 'com.apple.product-type.app-extension'
assert any(objects[d].get('target') == widget_id for d in runner['dependencies'])
assert any(objects[phase].get('dstSubfolderSpec') in ('13', 13) and
           any(objects[f]['fileRef'] == widget['productReference'] for f in objects[phase]['files'])
           for phase in runner['buildPhases'] if objects[phase]['isa'] == 'PBXCopyFilesBuildPhase')
assert any(objects[objects[f]['fileRef']].get('path') == 'GolfWeatherWidget.swift'
           for phase in widget['buildPhases'] if objects[phase]['isa'] == 'PBXSourcesBuildPhase'
           for f in objects[phase]['files'])
for target, entitlement in [(runner, 'Runner/Runner.entitlements'),
                            (widget, 'GolfWeatherWidget/GolfWeatherWidget.entitlements')]:
    for config in objects[target['buildConfigurationList']]['buildConfigurations']:
        assert objects[config]['buildSettings']['CODE_SIGN_ENTITLEMENTS'] == entitlement
with (root / 'ios/Runner/Runner.entitlements').open('rb') as f:
    app_groups = plistlib.load(f)['com.apple.security.application-groups']
with (root / 'ios/GolfWeatherWidget/GolfWeatherWidget.entitlements').open('rb') as f:
    widget_groups = plistlib.load(f)['com.apple.security.application-groups']
assert app_groups == widget_groups == ['group.com.weatherapp.widget']
print('PASS: RemoteViews layout, iOS extension embedding, build configurations and App Groups')
