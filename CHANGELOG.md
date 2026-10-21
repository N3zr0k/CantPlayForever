# Changelog

## [0.5.9] — Latest 1
- Fixed the "Disable all alarms" button in the options window not being clickable.

## [0.5.8] — Latest 1
- Internal cleanups; no change for players.

## [0.5.7] — Latest 1
- Improved the quality of the holiday decorations around the clock.

## [0.5.6] — Latest 1
- Updated the Hallow's End decoration around the clock.

## [0.5.5] — Latest 1
- Internal cleanups; no change for players.

## [0.5.4] — Latest 1
- Internal cleanups; no change for players.

## [0.5.3] — Latest 1
- Internal cleanups; no change for players.

## [0.5.2] — Latest 1
- New: if BugLab is installed, the addon sends its technical messages (debug, warnings, errors) to BugLab's console. BugLab also gets one line at login with the addon version and whether debug mode is on. Normal chat messages stay as they are.

## [0.5.0] — Latest 1
- New: holiday calendar. While a major in-game holiday runs (Hallow's End, Noblegarden, Harvest Festival, Love is in the Air, Lunar Festival, Midsummer, Feast of Winter Veil, Darkmoon Faire), the medium and large clock shows its icon and a themed decoration around the clock; hover the icon for name, start and end. The clock tooltip and the in-game calendar button tooltip list the running and the next holiday with a countdown. The new Calendar tab in the options lets you choose overlay only, overlay and icon, or icon only, and which holidays are shown. Finished events of the day are hidden.
- New: alarms in the calendar. Your alarms appear as entries in the in-game calendar (only on your computer, never as a server event) or, if installed, in Classic Calendar - Revived. Single alarms with a fixed date are always listed; repeating alarms are listed for the number of days set in the Calendar options (default 60). Each alarm can be left out of the calendar, and its type icon can be shown (off by default). Alarms with their own color appear in that color; a click on an alarm in the in-game calendar opens it in the alarm options.
- New: calendar events as alarms. On request (never automatically), events from the in-game calendar or Classic Calendar - Revived become alarms, with a selection list, a lead time and an alarm color per event type. After login you are asked once if there are new, changed or deleted events; changed events update their alarm, and alarms of deleted events can be removed. Imported alarms cannot change their type and show where they came from.
- New: times in the in-game calendar follow your clock setting. With the clock on local time, all calendar times show in local time, with the server time in brackets in the tooltip and the local time behind the server time when you view or edit an event. The option "Calendar times in local time" turns this off.
- New: more in the clock tooltip. Imported alarms list the calendar event in local and server time. Hold Ctrl for details: type and next trigger of each alarm, creator, attendees, your response and description of calendar events, and the next calendar events of the coming 7 days.

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
