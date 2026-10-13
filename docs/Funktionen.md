# Funktionen

* Uhr am Minimap-Button (digital/analog), Timer- und Alarm-Symbole am Rand.
* Alarme: täglich, Wochentage, Datum (monatlich/jährlich), wiederholend; Entschärfen per Shift + Linksklick.
* Timer: mehrere Vorgaben, ein aktiver, Start/Stop per Sanduhr.
* Original-Uhr ausblenden, Stoppuhr (Strg + Rechtsklick), Menü Original-Uhr (Alt + Rechtsklick).
* Effekte: Ton, Chat, Leuchten am Bildschirmrand (Geschwindigkeit einstellbar).

## Datenbank (`BetterClockSettings`)

| Bereich | Lesen | Schreiben |
|---|---|---|
| Alarme | `alarms`, `alarmRepeats`, `alarmDisarmOrder`, `alarmConfirmDelete`, `alarmSound` | `alarms` |
| Timer | `presets`, `selectedPresetID`, `activeTimer` | `presets`, `selectedPresetID`, `activeTimer` |
| Uhr | `clockStyle`, `clockSize`, `freeClock`, `useLocalTime`, `minimap`, `minimapPositions`, `hideBlizzardClock` | `minimap`, `minimapPositions`, `freeClock`, `clockSize` |
| Effekte | `playSound`, `screenGlow`, `screenGlowSpec`, `screenGlowSkipInstances`, `glowSpeed` | Optionen |
| Allgemein | `modules`, `global.debug`, `global.scope` | Optionen |

Pro Datei siehe [Files.md](Files.md). Migration: Alarme (Zeitplan-Marker `sched == 2`) beim Laden.
