# Shared calendar helpers, sourced by `agenda` and `cal-notify`.
#
# Events come from `cal-events`, a small EventKit helper (cal-events.swift,
# built by build.sh). It reads the calendars macOS keeps synced with your
# accounts; no API keys, no network of our own.

CAL_EVENTS_BIN="${CAL_EVENTS_BIN:-$HOME/.local/share/cal/cal-events}"

# cal_events <daysAhead>   (negative = look back)
# Emits one line per timed event:
#   "<startEpoch>|<YYYY-MM-DD>|<HH:MM>|<title>|<calendar>"
# Excluded calendars come from $CAL_EXCLUDE (see cal-events.swift).
cal_events() {
  if [ ! -x "$CAL_EVENTS_BIN" ]; then
    echo "cal-events not built: run ~/dotfiles/share/cal/build.sh" >&2
    return 1
  fi
  "$CAL_EVENTS_BIN" "${1:-1}"
}

# cal_countdown <seconds> -> "<1m" | "42m" | "3h 5m"
cal_countdown() {
  s=$1
  [ "$s" -lt 60 ] && { echo "<1m"; return; }
  m=$((s / 60))
  [ "$m" -lt 60 ] && { echo "${m}m"; return; }
  h=$((m / 60)); m=$((m % 60))
  echo "${h}h ${m}m"
}

# cal_color <calendarName> -> a 256-color code, stable per calendar.
# The real Calendar.app colors aren't read, so we deterministically
# hash the name to a fixed palette (same calendar -> same color every run).
# Override a specific calendar via CAL_COLORS="Work=39;Home=41".
cal_color() {
  _name=$1
  # explicit override?
  if [ -n "${CAL_COLORS:-}" ]; then
    _o=$(printf '%s' "$CAL_COLORS" | tr ';' '\n' | grep -F "${_name}=" | head -1)
    [ -n "$_o" ] && { echo "${_o#*=}"; return; }
  fi
  _palette="39 208 41 170 197 220 45 214 129 81"
  _count=$(echo "$_palette" | wc -w | tr -d ' ')
  _n=$(printf '%s' "$_name" | cksum | cut -d' ' -f1)
  _i=$(( _n % _count + 1 ))
  echo "$_palette" | cut -d' ' -f"$_i"
}
