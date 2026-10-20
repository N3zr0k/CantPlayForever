# Dateien

Pflege: bei jeder Dateiänderung aktualisieren. Lesen/Schreiben = Schlüssel in `CantPlayForeverSettings` (profile/global).

Bibliotheken in `CantPlayForever/Libs` (Ace3, LibDBIcon, LibDataBroker, LibStub) sind eingebettet.

## CantPlayForever

| Datei | Beschreibung | DB lesen | DB schreiben |
|---|---|---|---|
| `CantPlayForever.toc` | Addon-Manifest (Version, SavedVariables CantPlayForeverSettings, alt: BetterClockSettings; OptionalDeps OAPDebug) | – | – |
| `CantPlayForever.xml` | Ladereihenfolge: Libs, Core, Modules | – | – |
| `Core/AddonCompartment.lua` | Optionaler Blizzard-Addon-Menü-Eintrag; öffnet Optionen, zeigt Bedienungs-Tooltip | – | – |
| `Core/Alert.lua` | Alarm-Auslösung: Ton, Chat, Bildschirmleuchten; Alarmtext in Health-Schrift und Effektfarbe | alarmRepeats, alarmSound, glowSpeed, playSound | – |
| `Core/Core.lua` | Addon-Objekt, AceDB, Defaults, Migration der Alarme und des Wellness-Modulschalters auf Health, Slash-Befehle, Registrierung des Compartment-Eintrags | oapLevel, modules, health | scope, modules.health (Migration) |
| `Core/Core.xml` | Ladeliste Core: Core.lua, OAPDebug.lua, AddonCompartment.lua und weitere Komponenten | – | – |
| `Core/OAPDebug.lua` | Optionale OAP-Debug-Bridge (Register/Log, native Metrics, Inspector, Watch, Chat-Kopie, Performance und Fehlerisolierung) | global.oapLevel | – |
| `Core/Locales/deDE.lua` | Texte deDE | – | – |
| `Core/Locales/enUS.lua` | Texte enUS | – | – |
| `Core/Locales/frFR.lua` | Texte frFR | – | – |
| `Core/Options.lua` | Optionen Tab Allgemein, Effekte, Bestätigungsabfrage Löschen, Modulschalter | modules, scope | modules, alarmConfirmDelete, alarmRepeats, alarmSound, oapLevel, glowSpeed, playSound, screenGlow, screenGlowSkipInstances, screenGlowSpec |
| `Core/RowIcons.lua` | Icon-Buttons in Listenzeilen (Blizzard-Zahnrad, Blizzard-Löschatlas mit Fallback, graue Symbole mit blauer/roter Hover-Farbe, Tooltip) | – | – |
| `Dev/Tuning.lua` | Meldet Tuning-Werte, Gruppen, Anwenden-Logik und Aktionen beim Frame Debugger an (nur Repo, per `.pkgmeta` aus dem Release ausgeschlossen) | – | – |
| `Dev/Stage.lua` | Testbühne für den Frame Debugger (nur Repo, ohne Frame Debugger ohne Wirkung) | – | – |
| `Dev/FrameDump.lua` | Ring-Vorschau und Rahmen-Diagnose, von den BugLab-Probes genutzt (nur Repo) | – | – |
| `Dev/Probes.lua` | Meldet die Probes `ring`, `glow`, `alert`, `frame`, `holidays` bei BugLab an (nur Repo, ohne BugLab ohne Wirkung) | – | – |
| `Dev/HolidayList.lua` | `Clock:CollectHolidays(Jahr, log)` liest alle Kalender-Feste eines Jahres ins Probe-Log (Probe `holidays`, nur Repo) | – | – |
| `Core/ScreenGlow.lua` | Leuchten am Bildschirmrand | screenGlow, screenGlowSkipInstances, screenGlowSpec | – |
| `Media/Analog/dial_dots_small.tga` | Grafik | – | – |
| `Media/Analog/dial_ticks.tga` | Grafik | – | – |
| `Media/Analog/hand_hour.tga` | Grafik | – | – |
| `Media/Analog/hand_minute.tga` | Grafik | – | – |
| `Media/Analog/hand_second.tga` | Grafik | – | – |
| `Media/Badges/alarm_icon.tga` | Grafik | – | – |
| `Media/Badges/delete_bin.tga` | Grafik | – | – |
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
| `Modules/Clock/Badges.lua` | Symbole am Uhrenrand (Timer, Alarm, Fest) | activeTimer, alarms, holidaySymbol | – |
| `Modules/Calendar/Holidays.lua` | Modul Calendar: Laufende Feste aus dem Spielkalender (Symbol, Tooltip, Fest-Dekoration um die Uhr, Options-Reiter Kalender mit Festliste) | holidaySymbol, holidayHidden, global.holidayCatalog | C_Calendar |
| `Modules/Calendar/CalendarLink.lua` | Alarme als Termine in Classic Calendar - Revived, Kalendertermine (auch aus dem Spielkalender) per Knopf als Alarme | calLinkShow, calLinkLead | ClassicCalendar.API |
| `Modules/Calendar/CalendarRange.lua` | Zeitraum der Alarme im Kalender: Einzelalarme immer, wiederholende nur die eingestellten Tage voraus | calLinkShowDays | - |
| `Modules/Calendar/CalendarDisplay.lua` | Alarme als lokale Einträge im Spielkalender (ohne Classic Calendar), kein Servertermin | calLinkShow | C_Calendar, CalendarFrame |
| `Modules/Calendar/CalendarTooltip.lua` | Strg am Uhr-Tooltip: Alarm-Details und naechste Kalendereintraege (Typ, Zusage, Beschreibung, Teilnehmer) | - | C_Calendar |
| `Modules/Clock/BlizzardClock.lua` | Original-Uhr ausblenden, Stoppuhr, Menü Original-Uhr | – | – |
| `Modules/Clock/Clock.lua` | Minimap-Uhr, Klick-Aktionen | clockStyle, minimap, minimapPositions, use24Hour, useLocalTime | clockSize, freeClock |
| `Modules/Clock/Clock.xml` | Ladeliste | – | – |
| `Modules/Clock/Glow.lua` | Leuchteffekt an der Uhr, Überdeckungserkennung mit gecachter Kinderliste | – | – |
| `Modules/Clock/Locales/deDE.lua` | Texte deDE | – | – |
| `Modules/Clock/Locales/enUS.lua` | Texte enUS | – | – |
| `Modules/Clock/Locales/frFR.lua` | Texte frFR | – | – |
| `Modules/Clock/Options.lua` | Optionen Tab Uhr | minimap | clockStyle, hideBlizzardClock, use24Hour, useLocalTime |
| `Modules/Clock/OptionsLogo.lua` | Optionsfenster im Blizzard-Uhrenfenster-Rahmen (Spielatlanten, rotes X, Logo mit laufender Uhr unter Allgemein), Tabs, Button Alarme entschärfen, Größe fix | – | – |
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
| `Modules/Health/Health.lua` | Health-Modulregistrierung, Hooks und eigener Optionsreiter | modules.health | – |
| `Modules/Health/Health.xml` | Ladeliste mit Locales, Messages, Notice, Reminders, Health und Options | – | – |
| `Modules/Health/Locales/deDE.lua` | Health-Texte und Bewegungssprüche deDE | – | – |
| `Modules/Health/Locales/enUS.lua` | Health-Texte und Bewegungssprüche enUS | – | – |
| `Modules/Health/Locales/frFR.lua` | Health-Texte und Bewegungssprüche frFR | – | – |
| `Modules/Health/Messages.lua` | Titel/Text-Paare je Kategorie (Bewegung 10, Trinken 10, Augenpause 6 Übungen × 2 Texte) und Auswahl der eigenen Texte | health.<category>.customMessages | – |
| `Modules/Health/Notice.lua` | Health-Bildschirmmeldung mittig mit fraktionsabhängigen TGA-Icons, globalen/individuellen Icon-Werten (Sichtbarkeit, Transparenz, vertikale Position) und Text in Effektfarbe; Unterdrückung in Kampf/Instanzen | – | – |
| `Modules/Health/Reminders.lua` | Bewegungs-, Trink- und Augenpausentimer pro Session mit Prioritaet Trinken > Bewegung > Augenpause bei +/-5 Minuten; in Kampf/Instanz nur Chat, sonst je Konfiguration Anzeige/Glow/Ton | health.movement, health.notice, health.sound | – (Sitzung im RAM) |
| `Modules/Health/Options.lua` | Schalter und Minuten-Slider aller drei Komponenten, Health-Mitteilungseinstellungen | health | health |

## Repo

**Versionierung (ab `0.3.1-alpha.1`):** Für jeden neuen Repo-Build wird die Patchnummer `z` aus `x.y.z` um eins erhöht; `x` und `y` werden nur auf ausdrückliche Anweisung geändert. Die neue Patchversion beginnt mit `-alpha.1` (beispielsweise `0.3.1-alpha.1` → `0.3.2-alpha.1`). Vor jedem neuen Repository-ZIP müssen die vorgesehene Version und die ausdrückliche Baufreigabe beim Nutzer eingeholt werden.

| Datei | Beschreibung |
|---|---|
| `tools/check.py` | Strukturprüfung wie CI (`--tag vX.Y.Z-PHASE.N`) |
| `tools/build_repo_zip.py` | baut `<Repo>_Repo_<Version>.zip` |
| `tests/test_check.py` | Tests |
| `.github/workflows/ci.yml` | CI: luacheck, check.py, Tests |
| `.github/workflows/release.yml` | Release über BigWigs-Packager |
| `.pkgmeta`, `.luacheckrc`, `.gitignore`, `.gitattributes` | Packager- und Lint-Konfiguration |

| `Core/Playtime.lua` | Reload-resistente Session, letzte Sitzung, frische Server-/played-Werte bei Shift, bestätigte Charakter-Samples und separat gespeicherte Logout-Schätzstände | `db.global.playtime.characters[GUID]` | – |

- `tests/test_effects.py`: Sicherung der getrennten Effekte und Altprofil-Migration.

- Effektoptionen: `Core/Options.lua` nutzt AceConfig-Farbwaehler, Dropdown und Slider; `Core/ScreenGlow.lua` liest/schreibt kompatible `effects.<modul>.spec`-Angaben, inkl. `periodSeconds`. `Core/Alert.lua` nutzt die Modulart/Periodendauer auch fuer den Uhr-Alarm-Glow.

| `Media/Health/{movement,drink,eye}_{alliance,horde}.tga` | Transparente 256×256-TGA-Icons (Bewegung, Trinken, Augenpause) | – | – |

| `Media/Health/faction_{alliance,horde}.tga` | Transparente 256×256-Testwappen für Health-Effektvorschau | – | – |
| `docs/images/health/*.png` | PNG-Quellen der Health-Grafiken (Bewegung/Trinken je Fraktion, Augenpause) (nicht im Addon-Paket) | – | – |
| `docs/images/timer_hourglass.png` | Quelle der Sanduhr im Timer-Menü (nicht im Addon-Paket) | – | – |
| `docs/images/delete_bin.png` | Quelle des goldenen Papierkorbs (nicht im Addon-Paket) | – | – |
| `docs/images/CantPlayForever_Header_light.png` | Header hell (GitHub, README) (nicht im Addon-Paket) | – | – |
| `docs/images/CantPlayForever_Header_dark.png` | Header dunkel (CurseForge) (nicht im Addon-Paket) | – | – |
