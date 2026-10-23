#!/bin/zsh
# Copies ./patch into Aside's chat extension ("Aside Browsing Agent") and links it from each page
# that loads Aside's stylesheet. Aside keeps that extension in one of two places:
#   - older builds: ~/Library/Application Support/Aside/AsideAgentManager/<version>/
#   - newer builds: inside the app, Aside.app/.../Versions/<app version>/Libraries/AsideAgentManager/
# Both are patched. Pages inside the app are backed up to ./bundle-backup/<app version>/ before the
# first edit. Only changes what is missing, so it is safe to run any time; the LaunchAgent runs it
# at login, when an Aside update lands, and every 10 minutes.
#   zsh apply.sh            apply
#   zsh apply.sh --remove   take it out everywhere (pages restored byte for byte)
# ASIDE_RTL_BASE overrides the Application Support folder, ASIDE_RTL_APP the app (for testing on a copy).
set -u
HERE=${0:A:h}
SRC="$HERE/patch"
BASE=${ASIDE_RTL_BASE:-"$HOME/Library/Application Support/Aside/AsideAgentManager"}
APP=${ASIDE_RTL_APP:-/Applications/Aside.app}
export ASIDE_RTL_TAG='<!-- aside-rtl --><link rel="stylesheet" href="/aside-rtl/aside-rtl.css"><script src="/aside-rtl/aside-rtl.js" defer></script><!-- /aside-rtl -->'
log() { print -r -- "$(date '+%F %T') $*" >> "$HERE/apply.log"; }
[[ ${1:-} == --remove || -d $SRC ]] || { log "missing $SRC"; exit 1; }

# patch_one <extension dir> <log name> [backup dir]
patch_one() {
  local dir=$1 name=$2 bk=${3:-} f i
  for i in {1..12}; do                                  # a copy still being unpacked
    [[ -f $dir/manifest.json && -f $dir/sidepanel.html ]] && break
    sleep 5
  done
  [[ -f $dir/manifest.json && -f $dir/sidepanel.html ]] || { log "$name: incomplete, skipped"; return; }
  [[ -w $dir ]] || { log "$name: not writable, skipped"; return; }

  if [[ $MODE == remove ]]; then
    for f in "$dir"/*.html(N); do
      grep -q '<!-- aside-rtl -->' "$f" || continue
      if [[ -n $bk && -f $bk/${f:t} ]]; then cp -p "$bk/${f:t}" "$f"
      else perl -0pi -e 's/\s*<!-- aside-rtl -->.*?<!-- \/aside-rtl -->//s' "$f"; fi
    done
    rm -rf "$dir/aside-rtl"
    log "$name: removed"
    return
  fi

  local changed=()
  if ! diff -rq "$SRC" "$dir/aside-rtl" >/dev/null 2>&1; then
    rm -rf "$dir/.aside-rtl.new"
    if cp -R "$SRC" "$dir/.aside-rtl.new"; then
      rm -rf "$dir/aside-rtl" && mv "$dir/.aside-rtl.new" "$dir/aside-rtl" && changed+=(files)
    fi
  fi
  for f in "$dir"/*.html(N); do
    grep -q 'globals-[^"]*\.css' "$f" || continue        # only pages using Aside's stylesheet
    grep -q '<!-- aside-rtl -->' "$f" && continue
    if [[ -n $bk && ! -f $bk/${f:t} ]]; then mkdir -p "$bk" && cp -p "$f" "$bk/${f:t}" || continue; fi
    perl -0pi -e 's|</head>|  $ENV{ASIDE_RTL_TAG}\n  </head>|' "$f" && changed+=(${f:t})
  done
  (( ${#changed} )) && log "$name: patched ${changed[*]}"
}

MODE=apply; [[ ${1:-} == --remove ]] && MODE=remove

for dir in "$BASE"/*(N/); do                           # older builds: version folders
  [[ ${dir:t} == <->.<->.<->.<-> ]] && patch_one "$dir" "${dir:t}"
done
for dir in "$APP/Contents/Frameworks/Aside Framework.framework/Versions"/*/Libraries/AsideAgentManager(N/); do
  appver=${${dir:h:h}:t}                               # newer builds: inside the app
  patch_one "$dir" "app $appver" "$HERE/bundle-backup/$appver"
done
exit 0
