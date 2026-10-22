#!/bin/zsh
# Copies ./patch into every installed version of Aside's chat extension ("Aside Browsing Agent")
# and links it from each page that loads Aside's stylesheet. Only changes what is missing, so it
# is safe to run any time; the LaunchAgent runs it at login, when an Aside update lands, and
# every 10 minutes.
#   zsh apply.sh            apply
#   zsh apply.sh --remove   take it out of every installed version (pages restored byte for byte)
# ASIDE_RTL_BASE overrides the Aside folder (for testing on a copy).
set -u
HERE=${0:A:h}
SRC="$HERE/patch"
BASE=${ASIDE_RTL_BASE:-"$HOME/Library/Application Support/Aside/AsideAgentManager"}
export ASIDE_RTL_TAG='<!-- aside-rtl --><link rel="stylesheet" href="/aside-rtl/aside-rtl.css"><script src="/aside-rtl/aside-rtl.js" defer></script><!-- /aside-rtl -->'
log() { print -r -- "$(date '+%F %T') $*" >> "$HERE/apply.log"; }

[[ -d $BASE ]] || exit 0
[[ ${1:-} == --remove || -d $SRC ]] || { log "missing $SRC"; exit 1; }

for dir in "$BASE"/*(N/); do
  ver=${dir:t}
  [[ $ver == <->.<->.<->.<-> ]] || continue            # version folders only
  for i in {1..12}; do                                  # a version still being unpacked
    [[ -f $dir/manifest.json && -f $dir/sidepanel.html ]] && break
    sleep 5
  done
  [[ -f $dir/manifest.json && -f $dir/sidepanel.html ]] || { log "$ver: incomplete, skipped"; continue; }

  if [[ ${1:-} == --remove ]]; then
    for f in "$dir"/*.html(N); do
      grep -q '<!-- aside-rtl -->' "$f" && perl -0pi -e 's/\s*<!-- aside-rtl -->.*?<!-- \/aside-rtl -->//s' "$f"
    done
    rm -rf "$dir/aside-rtl"
    log "$ver: removed"
    continue
  fi

  changed=()
  if ! diff -rq "$SRC" "$dir/aside-rtl" >/dev/null 2>&1; then
    rm -rf "$dir/.aside-rtl.new"
    if cp -R "$SRC" "$dir/.aside-rtl.new"; then
      rm -rf "$dir/aside-rtl" && mv "$dir/.aside-rtl.new" "$dir/aside-rtl" && changed+=(files)
    fi
  fi
  for f in "$dir"/*.html(N); do
    grep -q 'globals-[^"]*\.css' "$f" || continue        # only pages using Aside's stylesheet
    grep -q '<!-- aside-rtl -->' "$f" && continue
    perl -0pi -e 's|</head>|  $ENV{ASIDE_RTL_TAG}\n  </head>|' "$f" && changed+=(${f:t})
  done
  (( ${#changed} )) && log "$ver: patched ${changed[*]}"
done
exit 0
