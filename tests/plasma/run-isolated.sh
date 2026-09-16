#!/usr/bin/env bash
set -euo pipefail

# Usage: bash tests/plasma/run-isolated.sh /nix/store/.../bin/kwin_wayland /nix/store/.../bin/plasma-lifetime-probe [expected-wl-fixes-version]
# No windows on the real desktop and no access to its session bus/config.
kwinBinary=${1:?Pass the KWin binary to test}
probeBinary=${2:?Pass the built probe binary}
testRoot=$(mktemp -d /tmp/plasma-lifetime-test-XXXXXXXX)
mkdir -p "$testRoot"/{config,cache,data,state,runtime}
chmod 700 "$testRoot/runtime"
echo "Isolated test data: $testRoot"
env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS \
  -u KWIN_USE_FIXES_V2 -u QT_WAYLAND_DISABLED_INTERFACES \
  XDG_CONFIG_HOME="$testRoot/config" XDG_CACHE_HOME="$testRoot/cache" \
  XDG_DATA_HOME="$testRoot/data" XDG_STATE_HOME="$testRoot/state" \
  XDG_RUNTIME_DIR="$testRoot/runtime" \
  LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software \
  PROBE_EXPECT_FIXES_VERSION="${3:-}" \
  timeout --kill-after=5s 45s dbus-run-session -- \
  "$kwinBinary" --virtual --no-lockscreen --no-global-shortcuts \
  --no-kactivities --width 320 --height 240 --exit-with-session "$probeBinary"
