#!/bin/sh
#
# Removes agenda: unloads the launchd agent and deletes installed files.
# Runtime logs/state in ~/.local/state/cal are left in place (remove manually).

LABEL="com.robray.cal-notify"
UID_NUM=$(id -u)

launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -f "$HOME/.local/bin/agenda" "$HOME/.local/bin/cal-notify"
rm -f "$HOME/.local/share/cal/events.sh" "$HOME/.local/share/cal/cal-events"
rmdir "$HOME/.local/share/cal" 2>/dev/null || true

echo "Uninstalled agenda."
echo "(Logs/state kept in ~/.local/state/cal — 'rm -rf' it to remove.)"
