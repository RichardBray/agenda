# agenda

Never miss a meeting again. A tiny, dependency-light macOS tool that:

- **Notifies you 5 minutes and 1 minute before every calendar event** (native macOS notifications, with sound).
- Gives you a fast CLI — **`agenda`** — to see what's coming up, color-coded per calendar.

It reads the calendar that macOS **already syncs locally** from your accounts
(Google, iCloud, Exchange — anything added in *System Settings → Internet
Accounts*). No API keys, no OAuth, no network calls of its own.

```
$ agenda
Today  Thu 18 Jun
  ● 17:30  Richard <> Rhys                   in 27m

Tomorrow  Fri 19 Jun
  ● 13:00  lunch                             in 14h 42m
  ● 17:00  Daily Standup                     in 18h 42m

Calendars: ● richard@sideguide.dev   ● richardobray@yahoo.co.uk
```

(Dots and times are tinted by calendar; the legend maps colors to calendars.)

## How it works

```
Your accounts ⇄ macOS sync (automatic) ⇄ local calendar store (~/Library/Calendars)
                                                      │
                         cal-events reads it ─────────┤
                                                      │
   agenda  ──────────────────────────────────────────┤  (on demand, in your terminal)
                                                      │
   launchd (every 60s) ──► cal-notify ──► osascript ──┘  (background reminders)
```

- **`cal-events`** is a small Swift helper (EventKit) that reads the local
  calendar store — fast, no credentials. It's compiled by `install.sh`.
- **`agenda`** formats upcoming events for the terminal.
- **`cal-notify`** is run every 60s by a **launchd** agent; it fires a
  notification 5 min and 1 min before each event (deduplicated so each alert
  fires once). Notifications are posted with `osascript` because
  `terminal-notifier` silently fails to deliver on current macOS.

## Requirements

- macOS (Apple Silicon or Intel)
- Xcode command line tools (for `swiftc`):  `xcode-select --install`
- At least one calendar account added in *System Settings → Internet Accounts*

## Install

```sh
git clone git@github.com:RichardBray/agenda.git
cd agenda
./install.sh
```

`install.sh` copies the scripts into `~/.local/bin` + `~/.local/share/cal`,
compiles `cal-events`, generates the launchd agent with your paths, and loads it. Re-run it any time
after editing. Make sure `~/.local/bin` is on your `PATH`.

## Usage

```sh
agenda          # upcoming events today + tomorrow (default)
agenda 0        # today's remaining events only
agenda 7        # the next 7 days
```

Reminders run automatically in the background once installed — nothing to launch.

### Make notifications stick

macOS shows them as auto-dismissing *banners* by default. To keep them on
screen until dismissed: *System Settings → Notifications → Script Editor →*
set the style to **Alerts**. (They're credited to "Script Editor" because
that's who macOS attributes `osascript` notifications to.)

## Configuration

Environment variables, read by both `agenda` and `cal-notify`
(set them in the launchd plist's environment or your shell for `agenda`):

| Variable      | Default                                   | Purpose                                            |
| ------------- | ----------------------------------------- | -------------------------------------------------- |
| `CAL_EXCLUDE` | holidays, birthdays, reminders calendars  | Comma-separated calendar names to ignore.          |
| `CAL_COLORS`  | (auto)                                    | Pin colors, e.g. `Work=39;Home=41` (256-color codes). |
| `CAL_EVENTS_BIN` | `~/.local/share/cal/cal-events`        | Path to the cal-events helper.                     |

**Reminder timings** live at the top of `bin/cal-notify`:

```sh
T_FIRST=300    # first alert, seconds before start (5 min)
T_SECOND=60    # second alert (1 min)
```

Edit, then re-run `./install.sh`.

### About the colors

The real Calendar.app colors aren't read, so each calendar's color is
**deterministically derived from its name** (stable across runs) from a fixed
palette. Override any calendar explicitly with `CAL_COLORS`.

## Files

| Path                                         | What                                  |
| -------------------------------------------- | ------------------------------------- |
| `~/.local/bin/agenda`                        | the CLI                               |
| `~/.local/bin/cal-notify`                    | the notifier (run by launchd)         |
| `~/.local/share/cal/events.sh`               | shared parsing / color helpers        |
| `~/Library/LaunchAgents/com.robray.cal-notify.plist` | the 60s scheduler             |
| `~/.local/state/cal/`                        | dedup state + logs (`notify.log`, `last-run`) |

## Uninstall

```sh
./uninstall.sh
```

## Troubleshooting

- **No reminders fire.** Check `~/.local/state/cal/last-run` — `upcoming events
  visible: N` confirms the background agent can read your calendar. Tail
  `~/.local/state/cal/notify.log` to see what fired.
- **`agenda` shows nothing** but you have events: confirm your account is
  syncing in Calendar.app and isn't in `CAL_EXCLUDE`.
- **Agent status:** `launchctl print gui/$(id -u)/com.robray.cal-notify`.
