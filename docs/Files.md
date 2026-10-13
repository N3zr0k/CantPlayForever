# Dateien

Pflege: bei jeder Dateiänderung aktualisieren. Lesen/Schreiben = Schlüssel in `CantPlayForeverSettings` (profile/global).

Bibliotheken in `CantPlayForever/Libs` (Ace3, LibDBIcon, LibDataBroker, LibStub) sind eingebettet.

## CantPlayForever

| Datei | Beschreibung | DB lesen | DB schreiben |
|---|---|---|---|
| `CantPlayForever.toc` | Addon-Manifest (Version, SavedVariables CantPlayForeverSettings, alt: BetterClockSettings) | – | – |
| `CantPlayForever.xml` | Ladereihenfolge: Libs, Core, Modules | – | – |
| `Core/Alert.lua` | Alarm-Auslösung: Ton, Chat, Bildschirmleuchten | alarmRepeats, alarmSound, glowSpeed, playSound | – |
| `Core/Core.lua` | Addon-Objekt, AceDB, Defaults, Migration der Alarme, Slash-Befehle | debug, modules | scope |
| `Core/Core.xml` | Ladeliste Core | – | – |
| `Core/Locales/deDE.lua` | Texte deDE | – | – |
| `Core/Locales/enUS.lua` | Texte enUS | – | – |
| `Core/Locales/frFR.lua` | Texte frFR | – | – |
| `Core/Options.lua` | Optionen Tab Allgemein, Effekte, Bestätigungsabfrage Löschen | modules, scope | alarmConfirmDelete, alarmRepeats, alarmSound, debug, glowSpeed, playSound, screenGlow, screenGlowSkipInstances, screenGlowSpec |
| `Core/RowIcons.lua` | Icon-Buttons in Listenzeilen (Grau/Farbe bei Mouseover, Tooltip) | – | – |
| `Core/ScreenGlow.lua` | Leuchten am Bildschirmrand | screenGlow, screenGlowSkipInstances, screenGlowSpec | – |
| `Media/Analog/dial_dots_small.tga` | Grafik | – | – |
| `Media/Analog/dial_ticks.tga` | Grafik | – | – |
| `Media/Analog/hand_hour.tga` | Grafik | – | – |
| `Media/Analog/hand_hour_small.tga` | Grafik | – | – |
| `Media/Analog/hand_minute.tga` | Grafik | – | – |
| `Media/Analog/hand_second.tga` | Grafik | – | – |
| `Media/Badges/alarm_icon.tga` | Grafik | – | – |
| `Media/Badges/delete_bin.tga` | Grafik | – | – |
| `Media/Badges/delete_bin_grey.tga` | Grafik | – | – |
| `Media/Badges/edit_gear.tga` | Grafik | – | – |
| `Media/Badges/edit_gear_grey.tga` | Grafik | – | – |
| `Media/Badges/hourglass.tga` | Grafik | – | – |
| `Media/Badges/hourglass_grey.tga` | Grafik | – | – |
| `Media/Badges/hourglass_on.tga` | Grafik | – | – |
| `Media/Badges/radio_off.tga` | Grafik | – | – |
| `Media/Badges/radio_on.tga` | Grafik | – | – |
| `Media/Badges/timer_icon.tga` | Grafik | – | – |
| `Media/ClockLarge.tga` | Grafik | – | – |
| `Media/Logos/alarm_logo.tga` | Grafik | – | – |
| `Media/Logos/allgemein_logo.tga` | Grafik | – | – |
| `Media/Logos/diamond.tga` | Grafik | – | – |
| `Media/Logos/kalender_logo.tga` | Grafik | – | – |
| `Media/Logos/optionen_logo.tga` | Grafik | – | – |
| `Media/Logos/pause_logo.tga` | Grafik | – | – |
| `Media/Logos/timer_logo.tga` | Grafik | – | – |
| `Media/Logos/uhr_logo.tga` | Grafik | – | – |
| `Modules/Alarms/Alarms.lua` | Alarm-Logik: Zeitplan, Prüfung, Entschärfen | alarmDisarmOrder, alarms, useLocalTime | – |
| `Modules/Alarms/Alarms.xml` | Ladeliste | – | – |
| `Modules/Alarms/Locales/deDE.lua` | Texte deDE | – | – |
| `Modules/Alarms/Locales/enUS.lua` | Texte enUS | – | – |
| `Modules/Alarms/Locales/frFR.lua` | Texte frFR | – | – |
| `Modules/Alarms/Options.lua` | Alarmliste, Edit-Modus, Zeitplan-Eingabe | alarms | alarmDisarmOrder |
| `Modules/Clock/AnalogClock.lua` | Analoge Uhr | activeTimer, useLocalTime | – |
| `Modules/Clock/Badges.lua` | Symbole am Uhrenrand (Timer, Alarm) | activeTimer, alarms | – |
| `Modules/Clock/BlizzardClock.lua` | Original-Uhr ausblenden, Stoppuhr, Menü Original-Uhr | – | – |
| `Modules/Clock/Clock.lua` | Minimap-Uhr, Klick-Aktionen | clockStyle, minimap, minimapPositions, use24Hour, useLocalTime | clockSize, freeClock |
| `Modules/Clock/Clock.xml` | Ladeliste | – | – |
| `Modules/Clock/Glow.lua` | Leuchteffekt an der Uhr | – | – |
| `Modules/Clock/Locales/deDE.lua` | Texte deDE | – | – |
| `Modules/Clock/Locales/enUS.lua` | Texte enUS | – | – |
| `Modules/Clock/Locales/frFR.lua` | Texte frFR | – | – |
| `Modules/Clock/Options.lua` | Optionen Tab Uhr | minimap | clockStyle, hideBlizzardClock, use24Hour, useLocalTime |
| `Modules/Clock/OptionsLogo.lua` | Optionsfenster: Logo, Tabs, Button Alarme entschärfen, Größe fix | – | – |
| `Modules/Clock/Ring.lua` | Ring um die Uhr | – | – |
| `Modules/Clock/SizeSlider.lua` | Größenregler | – | – |
| `Modules/Clock/Tooltip.lua` | Tooltip der Uhr | activeTimer, alarms | – |
| `Modules/Events/Events.lua` | Ereignis-Modul | – | – |
| `Modules/Events/Events.xml` | Ladeliste | – | – |
| `Modules/Events/Locales/deDE.lua` | Texte deDE | – | – |
| `Modules/Events/Locales/enUS.lua` | Texte enUS | – | – |
| `Modules/Events/Locales/frFR.lua` | Texte frFR | – | – |
| `Modules/Modules.xml` | Ladeliste | – | – |
| `Modules/Statistics/Locales/deDE.lua` | Texte deDE | – | – |
| `Modules/Statistics/Locales/enUS.lua` | Texte enUS | – | – |
| `Modules/Statistics/Locales/frFR.lua` | Texte frFR | – | – |
| `Modules/Statistics/Statistics.lua` | Statistik-Modul | – | – |
| `Modules/Statistics/Statistics.xml` | Ladeliste | – | – |
| `Modules/Timer/Locales/deDE.lua` | Texte deDE | – | – |
| `Modules/Timer/Locales/enUS.lua` | Texte enUS | – | – |
| `Modules/Timer/Locales/frFR.lua` | Texte frFR | – | – |
| `Modules/Timer/Options.lua` | Timerliste, Edit-Modus | activeTimer, presets | selectedPresetID |
| `Modules/Timer/Timer.lua` | Timer-Logik | presets, selectedPresetID | activeTimer |
| `Modules/Timer/Timer.xml` | Ladeliste | – | – |
| `Modules/Wellness/Locales/deDE.lua` | Texte deDE | – | – |
| `Modules/Wellness/Locales/enUS.lua` | Texte enUS | – | – |
| `Modules/Wellness/Locales/frFR.lua` | Texte frFR | – | – |
| `Modules/Wellness/Wellness.lua` | Wellness-Modul | – | – |
| `Modules/Wellness/Wellness.xml` | Ladeliste | – | – |

## Repo

| Datei | Beschreibung |
|---|---|
| `tools/check.py` | Strukturprüfung wie CI (`--tag vX.Y.Z-PHASE.N`) |
| `tools/build_repo_zip.py` | baut `<Repo>_Repo_<Version>.zip` |
| `tests/test_check.py` | Tests |
| `.github/workflows/ci.yml` | CI: luacheck, check.py, Tests |
| `.github/workflows/release.yml` | Release über BigWigs-Packager |
| `.pkgmeta`, `.luacheckrc`, `.gitignore`, `.gitattributes` | Packager- und Lint-Konfiguration |
