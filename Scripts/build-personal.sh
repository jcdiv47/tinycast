#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DEVELOPER_DIR:?Set DEVELOPER_DIR to the installed Xcode Contents/Developer directory}"
export DEVELOPER_DIR
REVISION=$(git rev-parse HEAD)
VERSION=$(python3 - <<'PY'
import json, re, subprocess
from pathlib import Path
release = json.loads(Path('.agents/tinycast-release.json').read_text())
if not re.fullmatch(r'v\d+\.\d+\.\d+', release['tag']):
    raise SystemExit('Expected a stable release tag')
commit = subprocess.check_output(['git', 'rev-parse', release['tag'] + '^{commit}'], text=True).strip()
if commit != release['commit']:
    raise SystemExit('Release tag does not match the recorded base')
subprocess.run(['git', 'merge-base', '--is-ancestor', commit, 'HEAD'], check=True)
if subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], text=True):
    raise SystemExit('Commit tracked changes before building a personal release')
print(release['tag'][1:])
PY
)
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
    -derivedDataPath build/PersonalDerivedData MARKETING_VERSION="$VERSION" \
    CODE_SIGNING_ALLOWED=NO build
APP=build/PersonalDerivedData/Build/Products/Release/Tinycast.app
python3 - "$APP" "$REVISION" <<'PY'
import json, plistlib, subprocess, sys
from pathlib import Path
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
if revision != sys.argv[2] or subprocess.check_output(
    ['git', 'status', '--porcelain', '--untracked-files=no'], text=True
):
    raise SystemExit('Source changed during the build; rebuild before installing')
release = json.loads(Path('.agents/tinycast-release.json').read_text())
path = Path(sys.argv[1]) / 'Contents/Info.plist'
info = plistlib.loads(path.read_bytes())
info['TinycastUpstreamRelease'] = release['tag']
info['TinycastUpstreamCommit'] = release['commit']
info['TinycastPatchRevision'] = revision
path.write_bytes(plistlib.dumps(info))
PY
codesign --force --sign "Tinycast Self-Signed" --timestamp=none \
    --entitlements Tinycast/Tinycast.entitlements --generate-entitlement-der "$APP"
codesign --verify --deep --strict "$APP"
printf 'Built %s at %s\n' "$VERSION" "$APP"
