#!/bin/zsh
# Installs aside-rtl: copies the patch to ~/.aside-rtl, applies it to every installed Aside
# version and adds the LaunchAgent com.aside-rtl so Aside updates get patched too.
#   zsh install.sh              install or update
#   zsh install.sh --no-agent   apply once, no background LaunchAgent
# ASIDE_RTL_HOME overrides the install folder.
set -eu
[[ $(uname) == Darwin ]] || { print -u2 "aside-rtl: macOS only"; exit 1; }
SKILL=${0:A:h:h}
DEST=${ASIDE_RTL_HOME:-$HOME/.aside-rtl}
BASE=${ASIDE_RTL_BASE:-"$HOME/Library/Application Support/Aside/AsideAgentManager"}
LABEL=com.aside-rtl
PLIST=$HOME/Library/LaunchAgents/$LABEL.plist

[[ -d $BASE ]] || { print -u2 "aside-rtl: Aside's chat extension folder not found: $BASE"; exit 1; }

mkdir -p "$DEST"
rm -rf "$DEST/patch"
cp -R "$SKILL/assets/patch" "$DEST/patch"
cp "$SKILL/scripts/apply.sh" "$SKILL/scripts/uninstall.sh" "$DEST/"

if [[ ${1:-} != --no-agent ]]; then
  mkdir -p "${PLIST:h}"
  cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/zsh</string><string>$DEST/apply.sh</string></array>
  <key>WatchPaths</key>
  <array><string>$BASE</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>600</integer>
  <key>StandardErrorPath</key><string>$DEST/apply.err.log</string>
</dict>
</plist>
PL
  plutil -lint -s "$PLIST"
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
fi

zsh "$DEST/apply.sh"
print "aside-rtl installed in $DEST"
tail -n 5 "$DEST/apply.log" 2>/dev/null || true
if grep -lq 'aside-ui-patch' "$BASE"/*/*.html(N) 2>/dev/null; then
  print "note: an older aside-ui-patch is also injected; remove it so both don't run."
fi
print "Reopen the Aside side panel (or reload chat pages) to see it."
