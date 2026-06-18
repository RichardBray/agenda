#!/bin/sh
#
# Installer for cal-reminders. Idempotent -- safe to re-run after edits.
# Copies the CLI + notifier into ~/.local, generates the launchd agent with
# your paths, and (re)loads it.

set -e

REPO=$(cd "$(dirname "$0")" && pwd)
LABEL="com.robray.cal-notify"
BIN="$HOME/.local/bin"
LIB="$HOME/.local/share/cal"
STATE="$HOME/.local/state/cal"
AGENTS="$HOME/Library/LaunchAgents"
PLIST="$AGENTS/$LABEL.plist"
UID_NUM=$(id -u)

# 1. Dependency check
if ! command -v icalBuddy >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/icalBuddy ]; then
  echo "Missing dependency: icalBuddy" >&2
  echo "Install it with:  brew install ical-buddy" >&2
  exit 1
fi

# 2. Deploy files
mkdir -p "$BIN" "$LIB" "$STATE" "$AGENTS"
install -m 0755 "$REPO/bin/agenda"     "$BIN/agenda"
install -m 0755 "$REPO/bin/cal-notify" "$BIN/cal-notify"
install -m 0644 "$REPO/lib/events.sh"  "$LIB/events.sh"

# 3. Generate the launchd agent (paths are user-specific, so not committed)
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>$BIN/cal-notify</string>
    </array>
    <key>StartInterval</key>
    <integer>60</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$STATE/launchd.out.log</string>
    <key>StandardErrorPath</key>
    <string>$STATE/launchd.err.log</string>
</dict>
</plist>
EOF

# 4. (Re)load the agent
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST"
launchctl enable "gui/$UID_NUM/$LABEL"

echo "Installed cal-reminders."
echo "  CLI:    agenda          (try it now)"
echo "  Agent:  $LABEL  (fires reminders every 60s, starts at login)"
