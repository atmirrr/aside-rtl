#!/bin/zsh
# Removes aside-rtl: stops the LaunchAgent first (otherwise it re-applies at once), restores every
# Aside page byte for byte and deletes the install folder.
set -u
DEST=${ASIDE_RTL_HOME:-$HOME/.aside-rtl}
LABEL=com.aside-rtl
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
if [[ -f $DEST/apply.sh ]]; then zsh "$DEST/apply.sh" --remove
else zsh "${0:A:h}/apply.sh" --remove; fi
rm -rf "$DEST"
print "aside-rtl removed. Reopen the Aside side panel to see the original UI."
