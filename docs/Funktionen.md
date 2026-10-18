# Funktionen

* Uhr am Minimap-Button (digital/analog), Timer- und Alarm-Symbole am Rand.
* Blizzard-Addon-Menü (AddonCompartmentFrame): eigener Eintrag mit Uhrsymbol; Klick öffnet **Allgemein** in den Optionen, Mouseover erklärt die Uhrenbedienung. Die Minimap-Klickaktionen bleiben separat.
* Alarme: täglich, Wochentage, Datum (monatlich/jährlich), wiederholend; Entschärfen per Strg + Linksklick. Der Alarmtyp verwendet 1/3 der Formularbreite, der Knopf **Alle Tage** steht vor Mo–So und die Felder Tag/Monat/Jahr teilen sich eine Zeile.
* Timer: mehrere Vorgaben, ein aktiver, Start/Stop per Sanduhr.
* Original-Uhr ausblenden, Stoppuhr (Strg + Rechtsklick), Menü Original-Uhr (Alt + Rechtsklick).
* Effekte: Ton, Chat, Leuchten am Bildschirmrand (Geschwindigkeit einstellbar).
* **Health** (aus Wellness umbenannt): Standardmäßig **ausgeschaltet** unter **Allgemein > Module**.
  * Untertabs **Bewegung, Trinken, Augenpausen, Allgemein**; pro Kategorie eigener Haken für die Effektdarstellung. Aktiviert erscheinen die gemeinsamen Farb-/Art-/Dauer-/Deckkraft-Controls und Effekt-Test. Die globalen Health-Effekte bleiben maßgeblich für Aktivierung/Sicherheitsbeschränkungen.
  * Aktive Kategorien: **Trinken** (Standard 30 Minuten, Slider 5–120), **Bewegung** (45 Minuten, Slider 5–180) und **Augenpausen** (20 Minuten, Slider 5–60). Alle laufen anhand der Sessionzeit ab Login; `/reload` setzt die Intervalle nicht zurück. Die Erinnerungen sind unabhängig von Alarmen und Timern.
  * **Kollisionsregel:** Liegen geplante Health-Termine höchstens 5 Minuten auseinander, gewinnt **Trinken > Bewegung > Augenpause**. Unterlegene Erinnerungen werden für diesen Durchlauf ausgelassen und nicht später nachgeholt; es gibt auch keine doppelten Chatmeldungen oder Töne. Die Regel berücksichtigt bevorstehende Termine und gilt ebenfalls bei gleichzeitig überfälligen Kategorien nach Lag. Nächste Fälligkeiten bleiben erhalten.
  * Humorvolle, zufällig ausgewählte Sprüche in Deutsch, Englisch und Französisch; Allianz/Horde automatisch erkannt, Tonfall freundlich/lustig/frech einstellbar. Fraktionsabhängige Trink- und Bewegungsicons sowie Augen-Icon mit einstellbarer Transparenz liegen hinter dem gut konturierten Bildschirmtext.
  * Bildschirmanzeige, Chat oder beides; optional WoW-Hinweiston (der Effekt-Test spielt ihn immer). Im Kampf und in Instanzen kommen gewonnene Health-Erinnerungen ausschließlich im Chat an, ohne Bildschirm, Glow oder Ton.

Weiteres Health-Konzept: eigene längere 20-20-20-Übungsanleitung und optional volk-/klassenspezifische Sprüche.

## Datenbank (`CantPlayForeverSettings`)

| Bereich | Lesen | Schreiben |
|---|---|---|
| Alarme | `alarms`, `alarmRepeats`, `alarmDisarmOrder`, `alarmConfirmDelete`, `alarmSound` | `alarms` |
| Timer | `presets`, `selectedPresetID`, `activeTimer` | `presets`, `selectedPresetID`, `activeTimer` |
| Uhr | `clockStyle`, `clockSize`, `freeClock`, `useLocalTime`, `minimap`, `minimapPositions`, `hideBlizzardClock` | `minimap`, `minimapPositions`, `freeClock`, `clockSize` |
| Effekte | `playSound`, `screenGlow`, `screenGlowSpec`, `screenGlowSkipInstances`, `glowSpeed` | Optionen |
| Allgemein | `modules`, `global.oapLevel`, `global.scope` | Optionen |
| Health | `modules.health`, `health.<category>.customEffect`, `health.<category>.effect`, `health.notice`, `health.sound` | Health-Untertabs, pro Kategorie optionale eigene Glow-Spezifikation (`spec`, `periodSeconds`); Bewegungsfälligkeit nur im RAM |

Pro Datei siehe [Files.md](Files.md). Migration: beim ersten Start werden die alten `BetterClockSettings` übernommen. Alarme (Zeitplan-Marker `sched == 2`) beim Laden.

## Debug mit OAP Debug (optional)
* Alle technischen Meldungen werden ausschließlich über die optionale OAP-Debug-Bridge protokolliert. Ohne OAP Debug existiert kein Debug-Tab und keine technische Debug-Ausgabe.
* Mit OAP Debug erscheint der Hauptreiter **Debug** mit Protokoll / Inspektor & Watch / Werkzeuge. Die accountweiten Stufen sind Fehler, Normal, Normal + Metriken (Standard), Detailliert.
* Die bestätigte OAP-API erlaubt native Zähler, Gauges und Zeitmessungen im Metrics-Tab, live Watches, Inspector-Objekte, Chat-Kopien sowie Navigation zu allen OAP-Tabs. Reguläre Spielerhinweise bleiben unverändert.
* Der Core misst seinen Tick und die aktiven Module über OAP-Timer; Modulfehler werden dedupliziert und andere Module laufen weiter. Details und Testmatrix: [`docs/OAPDebug.md`](OAPDebug.md).

## Spielzeit im Uhren-Tooltip (0.3.2)

- **Uhrzeit gut hervorgehoben** mit größerem Zahlenfont und Sekunden; darunter
  eigener Abschnitt **Spielsession** mit aktueller und letzter abgeschlossener Session
  im Format `hh:mm:ss`.
- Eine blau hervorgehobene WoW-Infozeile direkt nach dem Sessionblock
  (je eine freie Zeile davor und danach) erinnert an die Shift-Funktion.
  Während Shift gehalten wird, steht an derselben Position stattdessen die
  Überschrift **Spielzeit**; mit dem Loslassen erscheint der Hinweis wieder.
  Die folgende Spielzeitübersicht beginnt ebenfalls mit einer freien Zeile.
- Solange **Shift** gedrückt wird: Spielzeit des aktuellen Charakters und der aktuellen
  Stufe (**ausschließlich** serverseitige `/played`-Werte ohne lokale Hochrechnung) sowie die
  Summe der bisher gespeicherten Charakterwerte. Unter **Account gesamt** folgt eine
  nach Spielzeit sortierte Übersicht **aller erfassten Charaktere**: Name in Klassenfarbe,
  daneben dessen zuletzt bestätigte `/played`-Gesamtzeit in Tagen, Stunden und Minuten.
  Klasse und Fraktion werden beim Login je GUID erfasst. Für Klassenfarben wird
  `C_ClassColor.GetClassColor` mit einem Fallback verwendet; ein kleines
  Blizzard-Allianz-/Horde-Symbol steht vor dem Charakter. Für WoW Forever wird
  der vollständige Vor- und Nachname über `GetUnitName("player")` bevorzugt;
  bereits gespeicherte vollständige Namen werden nicht durch unvollständige
  Antworten überschrieben. Ältere Einträge ohne vollständigen Namen, Klassentoken
  oder Fraktion werden beim nächsten Login dieses Charakters vervollständigt. Nur Serverwerte zählen in dieser Aufstellung, keine lokalen
  Logout-Hochrechnungen. Anschließend folgt der 10 px hohe WoW-Tooltip-Trennstrich (`UI-TooltipDivider-Transparent`) im Glimpse-Stil mit 10 px Seitenabstand.
  Normales Mouseover fragt keine Spielzeit an. **Drücken von Shift während des
  Mouseovers** startet eine neue stille Serverabfrage (bei bereits gehaltenem Shift
  direkt beim Betreten des Uhrsymbols). Bis zur Serverantwort erscheint im Shift-Bereich
  ein Ladehinweis. Loslassen und erneutes Drücken von Shift lösen eine weitere Abfrage aus;
  das Verlassen der Uhr beendet die laufende Tooltip-Session.
- Accountweite `db.global.playtime.characters[GUID]`: getrennt vom auswählbaren
  Account-/Charakterprofil und daher profilübergreifend. Erstmalige Daten erscheinen nach
  der asynchronen Serverantwort; nicht erfasste Chars sind nicht in der Summe.
- Der Login beginnt die Sitzung, **/reload setzt sie nicht zurück**. `PLAYER_LOGOUT`
  wird von WoW auch beim UI-Reload ausgelöst; die Unterscheidung erfolgt beim nächsten
  `PLAYER_ENTERING_WORLD` anhand von `isReloadingUi`. Ein echter Logout schließt die
  Sitzung ab; die letzte Dauer wird beim nächsten Login je Charakter gespeichert.
  Alte Datensätze besitzen noch keinen letzten Sessionwert.
- Die Session wird als Zeitstempel in `db.global.playtime.characters[GUID].session`
  persistiert; ein Reload setzt `GetTime()` zurück, daher wird `time()` für
  Reload-übergreifende Dauerberechnungen verwendet. Frühere Sessions und Offlinezeit
  werden nicht doppelt in /played-Werte eingerechnet.
- Server liefert `TIME_PLAYED_MSG` als Antwort auf `RequestTimePlayed()`.
  Die erste automatische Anfrage findet **30 Sekunden nach einem echten Login** statt,
  danach alle **10 Minuten**. Ein normales Mouseover fragt **nicht** ab;
  Shift fordert einen frischen Serverwert an, sofern nicht schon eine Abfrage läuft.
  Bis zur Serverantwort zeigt der Shift-Tooltip »Lade /played…«.
  Drücken bzw. Loslassen von Shift aktualisiert den Tooltip sofort.
  Für automatische und per Shift ausgelöste Abfragen wird `TIME_PLAYED_MSG` während
  einer ausstehenden CPF-Anfrage gezielt nur auf den bereits registrierten
  Blizzard-Chatfenstern pausiert. Die WoW-Serverantwort erreicht CPF weiterhin;
  die Chat-Registrierungen werden nach der Antwort im nächsten Frame (oder bei
  Fehler/Timeout) wiederhergestellt. Das manuelle `/played` bleibt als Chatbefehl
  unverändert; keine globale Unterdrückung normaler Systemmeldungen.
- Der automatische Zyklus beginnt 30 Sekunden nach dem echten Login und läuft unabhängig von
  manuellen `/played`-Eingaben und Shift-Abfragen im 10-Minuten-Abstand weiter. Jede erfolgreiche
  `TIME_PLAYED_MSG`-Antwort aktualisiert den SavedVariables-Datensatz. Fehler und Timeouts werden abgefangen.
- Beim Logout werden der **letzte bestätigte WoW-Stand** für Gesamtzeit und aktuelle Stufe
  (`logoutConfirmedTotalPlayed`, `logoutConfirmedLevelPlayed`), der zugehörige
  Serverantwort-Zeitpunkt (`logoutConfirmedAt`) und der Snapshot-Zeitpunkt
  (`logoutSnapshotAt`) explizit im GUID-Datensatz gesichert.
  Da `PLAYER_LOGOUT` keine synchrone Serverantwort erlaubt, ist der bestätigte Stand
  höchstens so aktuell wie die letzte erfolgreiche Hintergrund-, Shift- oder `/played`-Abfrage.
- Beim Logout werden die bestätigten Serverwerte (`totalPlayed`, `levelPlayed`)
  **unverändert** je Charakter/GUID gespeichert. Zusätzlich wird der seit der letzten
  Serverantwort lokal fortgeschriebene **Logout-Endstand** in separaten Feldern
  (`logoutTotalPlayed`, `logoutLevelPlayed`, `logoutSavedAt`) abgelegt, weil WoW beim
  Logout keine synchrone `/played`-Abfrage garantiert. Die Shift-Accountsumme
  verwendet **nur** die zuletzt bestätigten Serverwerte aller erfassten Charaktere;
  die separat gespeicherte Logout-Schätzung fließt nicht in die angezeigte Summe ein.
- Technische Einschränkung: Wenn der Client keine `isReloadingUi`-Information liefert,
  wird nur bei einer sehr kurzen Ladeunterbrechung (bis 15 s) ein Reload vermutet.
  Ein außergewöhnlich schneller echter Re-Login kann dann nicht sicher unterschieden werden.

## Menü und Kopfzeile

- Eintrag im Blizzard AddonCompartment öffnet **Allgemein**, Mouseover zeigt
  die vorhandenen Klickkombinationen.
- Für das AceGUI-Optionsfenster gilt weiterhin der bewährte Logo-Code aus `0.3.1`.
  Die zwischenzeitliche experimentelle Tab-Umsortierung und das Text-Overlay sind wegen
  Darstellungsregressionen vorläufig zurückgenommen und müssen separat im Spiel geprüft werden.

### Bereits enthalten seit 0.3.8

- `Health/Bewegung`: absolute Minuten-Grenzen seit Login (persistente Sessionzeit,
  Reload übergreifend), ohne eigenen Ticker oder zusätzliche Serverabfragen.
- `Optionen → Effekte`: Timer/Alarme/Health besitzen eigene Bildschirmrand-
  Konfigurationen; altes Alarmprofil bleibt per Migration erhalten. Später sind
  Kategorien und pro Alarm abweichende Vorgaben möglich.
- Spielzeit-Tooltip: bei Shift direkt nach der Überschrift beginnen die Werte;
  der Divider entfällt, vor nachfolgenden Bedienungshinweisen bleibt eine Leerzeile.
- Der Shift-Infohinweis zeigt ein blau getöntes Blizzard-Icon.

### Farbwaehler und Effekttakt (ab 0.3.9-alpha.1)

Unter **Optionen → Effekte** bestehen eigene Reiter fuer Timer, Alarme und Health.

Standardwerte fuer neue Profile (Farbe, Effektart, Dauer eines Zyklus, Deckkraft):

| Bereich | Farbe | Effektart | Zyklus | Deckkraft |
|---|---|---|---|---|
| Timer | `3399FF` | Pulse | 1 Sekunde | 30 % |
| Alarme | `FF2619` | Pulse | 1 Sekunde | 30 % |
| Health | `5FFF4F` | Pulse | 1 Sekunde | 10 % |

Bereits gespeicherte individuelle Effekt-Einstellungen werden bei Updates nicht
ueberschrieben. Auch die Fallback-Werte ohne vollstaendiges Profil sind je Modul getrennt.
Die Oberfläche zeigt pro Modul zuerst „Bildschirmrand ... aufleuchten lassen“ und
„Nicht in Instanzen und Raids“. Darunter befindet sich ein Rahmen „Darstellung“ mit
Farbwähler, Dropdown Pulse/Static/Blink, Zyklusdauer 0,2–10 Sekunden und
Deckkraft 0–100 %. Die separate Farbvorschau-Zeile entfällt; der Farb-Button
zeigt den aktuellen Farbton. „Effekt jetzt testen“ zeigt bei **Timer und Alarmen**
nur den Bildschirmrand-Effekt; bei **Health** zusätzlich eine neutrale Health-Testmeldung
mit dem passenden Blizzard-Fraktionswappen (Allianz/Horde). Die Vorschau dauert
neun Sekunden und spielt keinen Ton und schreibt nicht in den Chat.
Bei Health ist die Instanzsperre immer aktiv und entsprechend schreibgeschützt.

Jeder Reiter bietet einen Blizzard-Farbpicker mit der aktuellen Farbe als Farbfeld (ohne separate Vorschau- oder HEX-Zeile),
ein Dropdown fuer **Pulse, Static oder Blink**, einen Slider fuer die Dauer eines
vollstaendigen Pulse-/Blink-Zyklus (**0,2–10 Sekunden in 0,1er-Schritten**;
bei Static deaktiviert) und einen Deckkraft-Slider (**0–100 %**). Einstellungen
bleiben im kompatiblen `effects.<modul>.spec`-Format gespeichert, inklusive
optionaler alter `ring`/`fill`/`both`-Formen. Der Sekundenwert wird zusaetzlich
als `periodSeconds` gehalten, damit das Umschalten nach Static ihn nicht verliert.
Vorheriges `glowSpeed` wird beim erstmaligen Bearbeiten beruecksichtigt.
Neue Sliderwerte steuern den Bildschirmrand unmittelbar ab der naechsten
Ausloesung (einschliesslich Test), ohne Ueberschreibung durch andere Module.
Alarm-/Timer-Ende-Glow der Uhr verwendet dieselbe Effektart und Zyklusdauer;
die Deckkraft des Uhrglows bleibt unabhaengig auf voller Sichtbarkeit.
Health-Bildschirm-Effekte bleiben in Kampf und Instanzen gesperrt. Die Health-Bildschirmmeldungen erscheinen mittig, mit einem leicht transparenten WoW-Kategorie-Icon hinter dem Text (Bewegung/Trinken/Augenpausen; alle Kategorien aktiv).

### Alarm-Wiederholungen und Effekte

Die Einstellung **Alarmton wiederholen** (`alarmRepeats`, 1–10) beeinflusst nur die
Anzahl der akustischen Wiedergaben mit zwei Sekunden Abstand. Beim Auslösen
eines Alarms werden Bildschirmmeldung, Uhren-Glow und aktivierter
Bildschirmrand-Effekt je **einmal** gestartet; ihre Lebensdauer beträgt
unabhängig von der Tonanzahl neun Sekunden. Pulsieren oder Blinken innerhalb
dieses Intervalls ist die separat konfigurierte Effektanimation und keine
Wiederholung durch `alarmRepeats`. Gilt auch für Timerablauf-Benachrichtigungen,
da beide `Clock:Alert` nutzen.

### Individuelle Alarmdarstellung (ab 0.3.11-alpha.1)

- **Alarmtyp:** Wecker, Event und Erinnerung mit unterschiedlichen originalen Blizzard-Icons. Standardtyp bestehender Alarme ist Wecker. Typ und Darstellung bleiben im Alarm-SavedVariable gespeichert.
- In der Bearbeitung und beim Anlegen eines Alarms erscheint direkt nach „Wiederholen“ der Schalter **Eigene Effektdarstellung**. Erst nach dessen Aktivierung wird der Rahmen **Darstellung** mit Farbwahl, Effektart (Pulse/Static/Blink), Zyklusdauer (0,2–10 s), Deckkraft (0–100 %) und Testknopf eingeblendet.
- Ohne aktivierte Überschreibung bleiben die Standardvorgaben unter **Optionen → Effekte → Alarme** gültig. Beim erstmaligen Einschalten werden die aktuellen Modulwerte kopiert. Späteres Ausschalten bewahrt die individuellen Werte, verwendet aber wieder die Modulvorgabe.
- Der globale Alarm-Bildschirmrand-Schalter und die Instanz-Ausnahme gelten weiterhin, auch wenn ein Alarm eigene Darstellungseinstellungen verwendet. Das Profil anderer Alarme wird nicht verändert.
- Bei eigener Effektfarbe werden Alarm-Übersicht und Alarm-Meldung in dieser Farbe gezeichnet. Das Typ-Icon erscheint in Optionsliste, Minimap-Mouseover und Bildschirmmeldung.
- Wochentage haben größere Toggle-Breiten in einer eigenen Reihe, damit Abkürzungen wie „Mo“ nicht mit Auslassungspunkten angezeigt werden.
- **Später:** Alarmkategorien können eigene Vorgaben erhalten; mögliche Priorität `Alarm > Kategorie > allgemeine Alarm-Effekte`. Die Kategorievorgaben sind noch nicht implementiert.

### Health-Untertabs und individuelle Kategorieeffekte (ab 0.3.12-alpha.1)

Die Health-Optionen haben getrennte Tabs für Bewegung, Trinken, Augenpausen und Allgemein. Pro Kategorie kann „Eigene Effektdarstellung“ aktiviert werden; erst danach erscheint der Darstellungsrahmen mit Farbe, Effektart, Zyklusdauer, Deckkraft und Vorschau. Beim ersten Aktivieren übernimmt die Kategorie die globalen Health-Effekte. Beim Ausschalten bleiben ihre eigenen Werte gespeichert, verwendet werden wieder die globalen Werte. Die übergeordnete Aktivierung und die Kampf-/Instanzsperre bleiben bestehen. Alle drei Kategorien lösen Erinnerungen nach ihrem konfigurierten Intervall aus. Der individuelle Effekt-Test zeigt den echten Erinnerungstext und das passende Icon der jeweiligen Kategorie, ohne den Terminplan zu verändern.

Das Alarmformular zeigt den Alarmtyp mit einem Drittel der Breite, den „Alle Tage“-Knopf links vor Mo–So sowie Tag, Monat und Jahr nebeneinander.


### Health-Bildschirmmeldung (ab 0.3.13-alpha.1)

Health-Meldungen erscheinen mit zentriertem Text in der Mitte des Bildschirms. Dahinter wird ein 200 × 200 Pixel großes Health-Kategorieicon angezeigt; die Transparenz beträgt standardmäßig 65 % und ist ebenso wie die vertikale Position konfigurierbar. Wie bisher erfolgt in Kampf und Instanzen nur eine Chat-Ausgabe, und die Bildschirmmeldung verschwindet nach 9 Sekunden.

Health besitzt drei aktive Kategorien: Bewegung, Trinken und Augenpausen. Die Hintergrund-Icons werden nach Fraktion gewählt und verwenden global die Icon-Einstellungen unter Optionen → Effekte → Health → Darstellung (Aktivierung, Transparenz und vertikale Position). Pro Kategorie erscheinen eigene Icon-Regler nur mit aktiviertem Haken „Eigene Effektdarstellung“. Text mit schwarzer Outline erscheint in der Effektfarbe; Kampf/Instanzen bleiben Chat-only.
