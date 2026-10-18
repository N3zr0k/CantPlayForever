# Changelog

## [0.3.37] — Beta 1
- Internal cleanups; no change for players.

## [0.3.36] — Beta 1
- Options: the edit gear is slightly larger.

## [0.3.35] — Beta 1
- Options: the edit gear is slightly larger and sits a little higher.

## [0.3.34] — Beta 1
- Options: new gear for editing and a new trash can, matching the timer's start/stop arrow in size.

## [0.3.33] — Beta 1
- Options: new golden trash can and the timer's start/stop button uses the game's arrow symbol.

## [0.3.32] — Beta 1
- Options: the edit buttons use the game's settings gear and the timer's start/stop button uses the game's arrow symbol.

## [0.3.31] — Beta 1
- Timer: new start/stop button in the options that turns green while the timer runs.
- Health: the eye break shows a separate image for Alliance and Horde. Optional notification sound; the effect test plays it too.

## [0.3.30] — Beta 1
- New **Health** module (off by default): reminders for movement, drinking and eye breaks with their own intervals, German/English/French texts with titles, optional custom texts, faction-themed screen icons, and source links for the default texts in each Health tab. In combat and instances reminders appear in chat only.
- New **effects** per module (alarms, timers, Health): screen-edge glow and clock glow with colour, pulse/static/blink, duration and opacity, plus a test button. Alarms can optionally use their own effect.
- Alarms: alarm types (alarm clock, event, reminder) with icons; the on-screen message uses the same font as Health in the effect colour. Ctrl + left-click arms or disarms an alarm.
- Playtime: the clock tooltip shows the current and last session. Hold Shift to see `/played` for every known character (class colours, faction badges) and the account total.
- The options window now uses the Blizzard clock-menu frame with a red close button and the current time in the corner. The addon also appears in the minimap addon menu.
- Clock: smoother and lighter on performance.
- Settings from earlier versions are kept; no action needed.

## 0.2.6
- Fixed the alarm glow on the clock staying red after an alarm.

## 0.2.5
- Fixed the options window content overlapping the new logo and description.

## 0.2.4
- Options window logo is larger and sits next to the title and description.

## 0.2.3
- Options window shows the addon logo and a short description under the title.

## 0.2.2
- Settings are now stored in `CantPlayForeverSettings`; existing settings are migrated automatically.

## 0.2.1
- Hides the original minimap clock while this clock is active (option, on by default).
- Ctrl + right-click opens the original stopwatch, Alt + right-click the original clock menu.

## 0.2.0
- New alarm list with edit mode: daily, weekdays, fixed date, monthly or yearly repeat.
- New timer list with start/stop hourglass and edit mode.
- Confirmation before deleting alarms and timers (can be switched off).
- Adjustable pulse speed of the alert glow; screen-edge glow is off by default.
- Texts in English, German and French.
