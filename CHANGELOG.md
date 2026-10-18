# Changelog

## [0.3.29] — Alpha 1
- Optionsfenster: In jedem Reiter liegt die Uhrzeit auf dem Hintergrund der Minimap-Uhr (Globus) in der Rahmenecke; der Fensterhintergrund reicht 4 px weiter nach unten; die ganze Kopfzeile verschiebt das Fenster. Alle Lagen und Größen sind Tuning-Werte (`OPT_*`, Frame_Debugger 0.1.16).

## [0.3.27] — Alpha 1
- Optionsfenster im Rahmen des Blizzard-Uhrenfensters (Metallrahmen mit Originalgrafiken inkl. Portrait-Ecke, rotes Schließen-X oben rechts, Name und Untertitel im Kopf). Statt Logos steht unter Allgemein nur die laufende Uhrzeit in der Rahmenecke. Der untere Schließen-Knopf entfällt, der Inhalt beginnt tiefer. Fehlt eine Rahmengrafik im Client, bleibt der bisherige Rahmen mit Logo.

## [0.3.25] — Alpha 1
- Health: Die Quellen der Standardtexte stehen ganz unten im jeweiligen Health-Reiter (Bewegung, Trinken, Augenpause), nicht in der Meldung.

## [0.3.24] — Alpha 1
- Spielzeit: Die Charakterliste im Shift-Tooltip zeigt jeden einmal erfassten Charakter; ohne bestätigten /played-Wert steht „Noch keine Daten“ (Summe und Anzahl zählen weiter nur bestätigte Werte).
- Health: Augenpause-Titel heißen jetzt „Fernblick!“, „Blinzelpause!“ usw. (statt „Augenpause: …“).

## [0.3.23] — Alpha 1
- Health: Neue Standardtexte als feste Titel/Text-Paare: 10 für Bewegung, 10 für Trinken, 6 Augenübungen mit je 2 Texten (Titel „Fernblick!“, „Blinzelpause!“ usw.), jeweils DE/EN/FR. Der Tonfall-Schalter und die fraktionsabhängigen Bewegungssprüche entfallen.
- Alarm-Meldung: gleiche Schrift wie die Health-Meldung (24 pt, dicke Kontur) in der Effektfarbe des Alarm- bzw. Timer-Effekts.
- Struktur: Health-Grafiken unter `CantPlayForever/Media/Health` (nur genutzte 256×256-TGAs), PNG-Quellen unter `docs/images/health`; Altlasten aus dem Repo-Stamm entfernt.
- Performance: Uhrtext, Symbole und Überdeckungserkennung berechnen Layout und Listen nur bei Änderung; Uhrzeit pro Sekunde zwischengespeichert; Modulsuche per Index; Tick-Messung nur mit OAP-Metrics.
- Tests: Lua-Laufzeittests angepasst (Papierkorb-Farbe, Eigene-Texte-Schalter) und um Texte/Alarmschrift erweitert.

## [0.3.22] — Alpha 1
- Health/Wellness: Der Bereich zur Verwaltung eigener Texte wird nur eingeblendet, wenn „Eigene Texte verwenden“ aktiviert ist; gespeicherte Texte bleiben erhalten.
- Gemeinsame Listen-Bedienelemente für Alarm, Timer und Health: eigenes goldenes WoW-Papierkorb-Icon (64 × 64 TGA), bei Mouseover rot; Zahnrad und Funktionen bleiben unverändert.

## [0.3.21] — Alpha 1
- Health > Eigene Texte: kompakter Knopf „Neuen Text hinzufügen“ auf eigener Zeile, danach Trennüberschrift „Gespeicherte Texte“ und Alarm-Layout je gespeichertem Text (Haken, blaues Zahnrad, roter Papierkorb, Text und Trennlinien).
- Mehrzeilige Eingabefelder ohne zusätzlichen „Annehmen“-Knopf: nur Speichern/Abbrechen. Die Entwürfe werden beim Tippen aktualisiert und erst durch Speichern übernommen.
- Beschreibung zum Standardtext-Fallback dezent grau statt weiss; Zahnrad behält ausserhalb des Hover seine originale Blizzard-Farbe und wird erst beim Hover entsättigt und blau eingefärbt. Der Papierkorb bleibt grau/rot.

## [0.3.20] — Alpha 1
- Listen-Symbole (Health, Alarme, Timer): Blizzard-Zahnrad statt kleiner Farbgrafik; Muelleimer nutzt einen Blizzard-Loeschen-Atlas, wo vorhanden, sonst die mitgelieferte transparente Grafik. Entsaettigte Symbole werden beim Mouseover sichtbar blau (Bearbeiten) bzw. rot (Loeschen) eingefaerbt; AceGUI-Recycling und deaktivierte Zustaende beruecksichtigt.
- Health: Beliebig viele eigene Erinnerungstexte je Kategorie mit Hauptschalter, optional 50/50-Mischung mit Standardtexten und eigenem Aktivierungshaken pro Text. Zahnrad und Papierkorb übernehmen die Alarm-Symbole und Hover-Farben. Hinzufügen/Bearbeiten/Speichern/Löschen pro Eintrag, lokalisiert DE/EN/FR, persistiert ohne Default-Listen.


## [0.3.19] — Alpha 1
- Health: Der globale Farbwähler unter Optionen → Effekte → Health → Darstellung ist entfernt. Bewegung, Trinken und Augenpausen verwenden ausnahmslos ihre zum Icon und zur Fraktion passenden Standardfarben, sofern „Eigene Effektdarstellung“ für die Kategorie nicht aktiviert ist.
- Frühere globale Health-Farbwerte und `colorCustomized`-Markierungen werden ignoriert. Effektart, Zyklusdauer, Deckkraft, Icon-Sichtbarkeit, Transparenz und Y-Position bleiben global einstellbar; individuelle Health-Farben bleiben gespeichert. Die allgemeine Health-Testnachricht verwendet neutrales Health-Grün (`5FFF4F`).

## [0.3.18] — Alpha 1
- Health: Der allgemeine Effekt-Test verwendet die neuen eigens gestalteten transparenten Allianz-/Hordewappen statt der Blizzard-PVP-Waehrungstexturen. Die Fraktion wird beim Anzeigen ueber `UnitFactionGroup('player')` erkannt. Die Wappen liegen als 256x256-TGA und -PNG unter `CantPlayForever/assets/health/`; die eigentlichen Kategorie-Erinnerungen behalten unveraendert ihre spezifischen Motive.

## [0.3.17] — Alpha 1
- Health: Der Effekt-Test unter Optionen → Effekte → Health zeigt jetzt eine neutrale Health-Testnachricht mit Blizzard-Allianz-/Hordewappen, Text in globaler Effektfarbe und den globalen Icon-Einstellungen.
- Der Effekt-Test in individuellen Health-Darstellungen verwendet den echten Kategorie-Erinnerungstext und das passende Health-Icon samt individueller Effekt- und Icon-Darstellung. Tests beeinflussen weder Erinnerungsintervalle noch Chatmeldungen oder Toene; sie verbergen sich nach neun Sekunden und bleiben im Kampf/in Instanzen gesperrt.

## [0.3.16] — Alpha 1
- Health: Icon-Aktivierung, Icon-Transparenz und vertikale Icon-Position aus den stets sichtbaren Kategorie-Tabs entfernt und in **Optionen → Effekte → Health → Darstellung** als globale Vorgabe aufgenommen.
- Kategorien: Diese drei Icon-Optionen erscheinen nur nach Aktivierung von **Eigene Effektdarstellung** zusammen mit der individuellen Effekt-Darstellung. Einzelwerte werden separat gespeichert, globale Einstellungen bleiben unangetastet.
- Bereits gespeicherte Kategorie-Iconwerte werden bei aktiviertem individuellem Effekt berücksichtigt und beim erstmaligen Aktivieren übernommen.
- Standardposition der Hintergrund-Icons auf **+65 px** (Y-Achse) angehoben. Bereits gespeicherte benutzerdefinierte Positionen bleiben erhalten.

## [0.3.15] — Alpha 1
- Health: Kollisionen von Erinnerungen innerhalb von +/-5 Minuten (inklusive der Grenze) werden bei der Bildschirmdarstellung nach **Trinken > Bewegung > Augenpause** aufgeloest. Niedriger priorisierte Erinnerungen behalten ihre Chatmeldung, Bildschirmdarstellung, Glow und Ton werden jedoch unterdrueckt.
- Augenpause verwendet nun standardmaessig die Effektfarbe Weiss. Die Health-Darstellung besitzt pro Kategorie einen eigenen Kasten "Darstellung" mit Icon-Schalter, Transparenz und neuer vertikaler Y-Position des Hintergrund-Icons.
- Das Hintergrundbild fuer Augenentspannung wurde durch das neue Wind-/Blaetter-Augenmotiv ersetzt.


## [0.3.14] — Alpha 1
- Health: Trink- und Augenpausen sind funktionsfähig (standardmäßig eingeschaltet, 30 bzw. 20 Minuten); Schlafenszeit-Tab entfernt. Alle Erinnerungen nutzen den vorhandenen Core-Tick und die Login-Session. Gleichzeitige Bildschirmmeldungen werden nacheinander eingeblendet; Chat bleibt pünktlich.
- Neue fraktionsabhängige, transparente 256x256-TGA-Grafiken: Allianz-/Horde-Trinkkrug, Allianz-/Horde-Stiefel und gemeinsames Auge. Fraktion wird automatisch erkannt. Alle Assets sind im Addon enthalten.
- Unter Health > jeweilige Kategorie kann das Hintergrund-Icon deaktiviert und seine Transparenz (0–100 %, Standard 65 %) eingestellt werden.
- Bildschirmtext in Effektfarbe mit schwarzer THICKOUTLINE-Kontur und Schatten vor den Icons; passende Standardfarben pro Kategorie/Fraktion. Individuelle Kategorieeffekte und geänderte globale Vorgaben bleiben vorrangig.
- Im Kampf und in Instanzen weiterhin ausschließlich Chat ohne optische Ausgabe/Ton; DE/EN/FR-Lokalisierung und Tests aktualisiert.

## [0.3.13] — Alpha 1
- Health: Bildschirm-Erinnerungen exakt mittig statt 115 px unterhalb der Mitte. Halbtransparentes, hinter dem Text liegendes WoW-Icon (35 % Deckkraft); eigenständige Standard-Icons für Bewegung, Trinken, Augenpausen und Schlafenszeit. Gemeinsames Anzeige-Modul `Modules/Health/Notice.lua` für späteren Ausbau, ohne zusätzlichen Ticker.


## [0.3.12] — Alpha 1
- Health: Untertabs für Bewegung, Trinken, Augenpausen, Schlafenszeit und Allgemein. Pro Kategorie optional eigene Farbe, Effektart, Zyklusdauer und Deckkraft mit Testvorschau; globale Health-Aktivierung/Sicherheitsregeln bleiben wirksam.
- Alarme: kompakter Alarmtyp (1/3 Breite), „Alle Tage“ vor den Wochentagen, Tag/Monat/Jahr in einer Zeile.

## [0.3.11] — Alpha 1
- Alarme: Neuer Typ (Wecker, Event, Erinnerung) mit Blizzard-Icon in Alarmübersicht, Tooltip und Bildschirmmeldung. Vorhandene Alarme erhalten automatisch den Typ Wecker.
- Optional eigene Effekt-Darstellung pro Alarm (Farbe, Pulse/Static/Blink, Dauer und Deckkraft) nach „Wiederholen“; ohne Haken gelten unverändert die Einstellungen unter Optionen → Effekte → Alarme. Globale Effekt-Aktivierung/Instanzsperre bleiben vorrangig.
- Alarmübersicht und Bildschirmmeldung verwenden bei individuellen Einstellungen die gewählte Alarmfarbe; Wochentage mit breiteren, eigenen Toggle-Feldern gegen abgeschnittenes „Mo...“.
- Standardwerte für neue Effektprofile: Health `5FFF4F, Pulse, 1 s, 10 %`, Alarme `FF2619, Pulse, 1 s, 30 %`, Timer `3399FF, Pulse, 1 s, 30 %`. Vorhandene persönliche Effekt-Einstellungen bleiben unverändert.

## [0.3.10] — Alpha 1
- Optionen → Effekte: Einheitlicher Aufbau je Modul: Effekt aktivieren, Instanz-Ausnahme, Rahmen „Darstellung“ mit Farbe/Art/Zyklusdauer/Deckkraft und abschließend „Effekt jetzt testen“. Separate Farbvorschau-Zeile entfernt; Health-Instanzsperre sichtbar, aber fest aktiviert.
- Effekt-Test zeigt den Bildschirmrand für 9 Sekunden, ohne Alarmmeldung oder Alarmton.
- Alarm-Audio und visuelle Effekte entkoppelt: `alarmRepeats` regelt nur die
  Tonwiederholungen. Bildschirmmeldung, Uhren-Glow und Bildschirmrand-Effekt
  starten einmalig je Alarm und behalten eine feste Anzeigedauer (9 Sekunden),
  unabhaengig von der Tonwiederholungszahl.

## [0.3.9] — Alpha 1
- Optionen → Effekte (Timer, Alarme, Health): Blizzard-Farbwaehler mit Farbfeld
  und aktuellem HEX-Wert, Dropdown fuer Pulse/Static/Blink sowie Slider fuer
  Zyklusdauer (0,2–10 Sekunden) und Bildschirmrand-Deckkraft (0–100 %).
- Der statische Effekt deaktiviert nur die Zyklusdauer; der gewaehlte Wert
  bleibt fuer die spaetere Rueckkehr zu Pulse/Blink gespeichert.
- Alte Glow-Specs bleiben kompatibel, inklusive vorhandener Formparameter;
  jeder Modul-Effekt nutzt wieder seine eigene Art und Dauer.

## [0.3.8] — Alpha 1
- Health in combat/instances: reminders always in chat, suppress on-screen messages, screen glows and sounds; remove outdated deferral switches.
- Clock tooltip: normal-sized white time display and matching class-colored playtime values for each character.
- Health/Bewegung berechnet das Intervall aus der Login-Session (`GetSessionSeconds`) statt aus einem neu gestarteten `GetTime()`-Countdown. Alle 5 Minuten funktionieren damit auch ueber `/reload`, ohne neuen Ticker.
- Effekte > Timer / Alarme / Health: getrennte Bildschirmrand-Effekte mit Ein/Aus, Farbe/Verhalten, Pulsrate und Instanz-Ausnahme. Alte Bildschirmrand-Einstellungen wandern einmalig zu „Alarme“.
- Vorbereitet fuer spaetere alarmbezogene Effektkategorien/Vorgaben (noch keine individuellen Alarm-Effekte).
- Tooltip bei Shift: Spielzeitwerte direkt nach der Überschrift, ohne Leerzeile; unter der Statistik kein Divider mehr, sondern ein Leerzeilenabstand zu den folgenden Hinweisen.
- Tooltip: Das Info-Icon des Shift-Hinweises wird wie sein Text blau eingefärbt.

## [0.3.7] — Alpha 1
- Change alarm arm/disarm from Shift + left-click to Ctrl + left-click; plain left-click continues to toggle the selected timer. Keep Shift for `/played` tooltip details.
- Update in-game tooltips, addon-compartment help and alarm options in deDE, enUS and frFR.
- Show the active timer directly beneath the clock time in its tooltip; present login sessions separately from Shift `/played` data.
- Show a blue Blizzard information icon and a localized Shift hint below the sessions; pressing Shift swaps that line for the "Playtime" heading and fresh server data, releasing Shift restores the hint.
- Save current character class, faction, and full given/family name on login; list known characters in WoW class colors with Alliance/Horde badges and per-character confirmed playtime.
- Prefer full names when available and preserve previously stored surnames; keep same-name characters from different realms distinct by GUID.

## [0.3.6] — Alpha 1
- Start quiet WoW `/played` polling 30 seconds after a real login, then every 10 minutes (schedule survives `/reload`); ordinary clock mouseover does not trigger requests.
- Pressing Shift while hovering requests fresh server `/played` data; entering the clock with Shift already held also requests it. Every `TIME_PLAYED_MSG`, including replies to manual `/played` chat commands, updates saved character totals without resetting the automatic schedule.
- Quiet WoW `/played` output for addon-initiated Shift and periodic requests: temporarily pause only `TIME_PLAYED_MSG` chat-frame listeners and restore them on reply, error or timeout; manual `/played` remains visible.
- Clock tooltip: make the clock time visually prominent and separate session durations from Shift `/played` data with localized headings.
- List every known character below the account-wide total with class-colored names and per-character `/played` (days/hours/minutes). Persist the class token by GUID; older unclassified entries use neutral text until that character next logs in.
- Account total and character list use the last WoW-confirmed `TIME_PLAYED_MSG` per character, never locally extrapolated logout estimates. The active character requires the fresh Shift server response.

## [0.3.5] — Alpha 1
- Format Shift-Mouseover `/played` values (character, level, account) as localized full days, hours and minutes; omit seconds.
- Current and last login sessions remain in `hh:mm:ss`; only presentation changes, not saved data or server queries.
- Replace the ASCII line after Shift `/played` statistics with the built-in WoW tooltip divider texture (10px high, 10px side inset; Glimpse style).

## [0.3.4] — Alpha 1
- Shift clock tooltip now uses only fresh server `TIME_PLAYED_MSG` for current character and level; each new Shift hover requests `/played` and shows a loading state until it arrives.
- On logout, persist each character's last confirmed server values and a separate elapsed-time logout estimate; account totals use saved offline-character end states without ever presenting estimates as live server `/played` values.
- Preserve current login session across `/reload`; show last completed character session and avoid double-counting played time or offline intervals.
- Refresh Shift mouseover immediately, including on modifier changes; automatic startup `/played` requests remain throttled.

## [0.3.3] — Alpha 1
- Regression hotfix: isolate newly added `/played`, AddonCompartment and options-style calls so a fault cannot halt the shared clock ticker or collision glow updates.
- Restore the unmodified, known-good `0.3.1-alpha.1` OptionsLogo.lua while diagnosing the `0.3.2` UI regression; no AceGUI tab-layout overrides.
- Recheck minimap overlap immediately when a clock drag ends.

## [0.3.2] — Alpha 1
- Added account-wide per-character `/played` tracking, current-session clock-tooltip row and Shift-expanded character/level/account totals, with a separator.
- Added localized Blizzard AddonCompartment entry that opens the general options and shows clock controls.
- Unified the clock-face header logo across options tabs; Allgemein overlays the provided transparent Can't Play Forever text art at 50px.
- Centered header circle and balanced left/right tab spacing; shortened the Health tab name and added a gray localized introduction.
- Extended optional OAP Health Live Watch with pending state, deferral reason, remaining seconds and reminder counters.

## [0.3.1] — Alpha 1
- OAP Debug 1.1 API directly verified from supplied Lua source; native Metrics counters/gauges/timers, Inspector, live Watches, Chat copy, tab shortcuts, and four verbosity levels implemented.
- Profile-level debug UI exists only when OAP is present; addon remains quiet about diagnostics when it is absent.
- OAP Debug: eigenständiger Debug-Reiter nur bei installiertem OAP, vollständig stumm ohne OAP; Inspector-/Watch-Telemetrie für Timer, Alarms, Health und Core.
- Redirect technical logging to optional OAP Debug, with one centralized bridge and configurable verbosity. Remove debug messages from game chat; preserve ordinary user notifications.
- Forward previously swallowed core tick errors to OAP Debug (deduplicated); keep the addon fully usable without OAP Debug.

## [0.3.0] — Alpha 1
- Renamed the planned Wellness module to Health, keeping it off by default and allowing it to be enabled under General > Modules; existing Wellness module selections migrate.
- Added Health movement reminders with independent minute intervals, localized faction-based messages, message styles, screen/chat options, optional sound, and combat/instance deferral.
- Added configurable toggles and interval sliders for drinking, eye breaks, and bedtime; their actual reminders are reserved for later steps.
- Documented Health roadmap and configuration.

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
