# OAP Debug 1.1 – Integration für Can't Play Forever

Technische Referenz: vom Nutzer bereitgestellter Quellcode `OAPDebug(1).zip`, insbesondere `OAPDebug/Core.lua`, `HelpUsage.lua`, `Monitor.lua`, `TabMetrics.lua`, `TabChat.lua` und `Errors.lua` (API_VERSION = 2). Keine internen Funktionen oder Tabellen von OAP werden aufgerufen.

## Grundregeln

- `## OptionalDeps: OAPDebug` lädt OAP bei Installation vor CPF. Ohne installiertes/geladenes OAP erscheint **kein Debug-Tab**, es gibt **keine technischen Debug-Ausgaben und keine Debug-Telemetrie**, und sämtliche Funktionen von CPF laufen unabhängig weiter.
- Mit geladenem OAP erhält CPF einen eigenständigen Hauptreiter **Debug** mit **Protokoll**, **Inspektor & Watch**, **Werkzeuge**. Der Reiter wird dynamisch über `Clock:IsOAPDebugAvailable()` erzeugt, nicht über einen dauerhaft sichtbaren deaktivierten Schalter.
- `Clock:Debug`, `Clock:OAPLog` und abgefangene Tick-Fehler gehen **nie** in den normalen Chat. Normale Spielermeldungen aus `Clock:Print` bleiben im Chat; OAP erhält auf Stufe `normal` oder höher eine *Kopie* im OAP-**Chat**-Tab (`OAPDebug.Chat` druckt selbst nichts).
- OAP fängt eigenständig echte Lua-Fehler, `LUA_WARNING` und verbotene Addon-Aktionen ab, ordnet sie dank `Register(..., {folder='CantPlayForever'})` dem Addon zu und zeigt sie im **Errors**-Tab. WoW kann daneben seine eigene Fehleranzeige verwenden.
- Sämtliche externen Aufrufe sind optional und geschützt. Keine zusätzlichen laufenden Ticker; Metriken und Zustandswerte werden höchstens einmal pro Sekunde aus dem vorhandenen Core-Tick aktualisiert.

## Accountweite Ausführlichkeit

| `global.oapLevel` | Log | Inspector/Watch/Chat | Metriken und Zeitmessung |
|---|---|---|---|
| `errors` | Fehler | nein | nein |
| `normal` | Fehler, Warnung, Info | ja | nein |
| `metrics` (**Standard**) | Fehler, Warnung, Info | ja | ja |
| `detailed` | zusätzlich Debug | ja | ja |

Bestehendes `global.oapLevel` wird nicht überschrieben. Ein früheres `global.debug=true` wird einmalig zu `detailed` migriert. OAP Debug selbst kann sein Log zusätzlich unabhängig filtern.

## Tatsächliche öffentliche OAP-API

Implementiert in `Core/OAPDebug.lua`:

- Registrierung: `OAPDebug.Register(source, {title, folder, color, icon})`.
- Protokoll: `OAPDebug.Log(source, 'Message {1}', 'warn', value)`; `Clock:Debug(fmt, ...)` übersetzt nur das alte printf-Format.
- Inspector: `OAPDebug.Inspect(source, label, value)` hält Tabellen live per Referenz; `OAPDebug.Show(source, 'inspect')` öffnet den Tab.
- Watch: `OAPDebug.Watch(source, label, tableOrFunction)` (Version 2) öffnet den Live-Monitor (Refresh 0,3 s **nur bei geöffnetem Fenster**), `OAPDebug.Unwatch(source, label)` entfernt ihn. Watch-Funktionen erzeugen kleine aktuelle Status-Tabellen, keine teuren Berechnungen.
- Native Metrics: `OAPDebug.Count`, `OAPDebug.Gauge`, `OAPDebug.StartTimer` / `StopTimer`, `OAPDebug.Time`. Messungen erscheinen direkt im **Metrics**-Tab mit Verlauf und den Zeiten/Anzahlen. `OAPSnapshot()` sendet Modulaktivitäten, Timerrestzeit, Weckeranzahl und den Status der Bewegungserinnerung.
- Chat-Kopie: `OAPDebug.Chat(source, text)` erfasst nur Nachrichten, die CPF ohnehin ausgeben würde.
- Navigation: `OAPDebug.Show(source, tab)` für `log`, `metrics`, `perf`, `frames`, `inspect`, `chat`, `errors`. Frame-Picker und Systemperformance gehören zum OAP-eigenen UI.

Die Methoden `Clock:OAPLog`, `Clock:OAPCounter`, `Clock:OAPGauge`, `Clock:OAPTime`, `Clock:OAPStartTimer`, `Clock:OAPStopTimer`, `Clock:OAPInspect`, `Clock:OAPWatch`, `Clock:OAPUnwatch`, `Clock:OAPShow` kapseln die fremde API. Sie erzeugen keine Ausgabe, wenn OAP nicht installiert ist. `Clock.oapTelemetry` ist nur eine zusätzliche optionale Inspector-Ansicht und ersetzt **nicht** mehr die nativen Metriken.

## Debug-Tab

**Protokoll:** Stufe für das gesamte Konto wählen; kein Schalter an anderer Stelle.

**Inspektor & Watch:** vordefinierte Inspector-Objekte (Module, Profil, Diagnosen, Health, Uhr-Frame); sechs Live-Watch-Ziele (Modulstatus, Timer, Wecker, Health, Profil, Diagnosen). Live-Watches werden **nur auf Knopfdruck** erstellt und können gezielt wieder entfernt werden. Sie brauchen die API-Version 2.

**Werkzeuge:** Direktbuttons für OAP Log, Metrics, Perf, Frames, Errors und Chat-Kopie. Weitere Funktionen wie Frame-Picker und OAP-Hilfe sind im Fremdaddon selbst verfügbar: `/oapd` und `/oapd help`.

## Instrumentierte CPF-Ereignisse

- `core.tick`, `tick.notice`, `tick.sound`, `tick.module.<id>`: echte native OAP-Zeitmessungen über `StartTimer`/`StopTimer` (mit Tick-Fehlerisolierung und Duplikatbegrenzung für Fehlerlogs).
- `core.ticks`, `modules.registered`, `profiles.changed`, `timer.started`, `timer.stopped`, `timer.expired`, `alarms.armed`, `alarms.disarmed`, `alarms.triggered`, `health.movement.due`, `health.movement.shown`: native OAP-Counter.
- `module.<id>`, `moduleCount`, `timerRunning`, `timerRemainingSec`, `alarmsArmed`, `movementPending`, `movementRemainingSec`: native OAP-Gauges (höchstens 1 Aktualisierung/Sekunde).
- `Clock.oapTelemetry`: ergänzende Inspector-Tabelle mit Countern, Gauges und Laufzeitstatistiken; nicht in CPF-SavedVariables geschrieben.

## Testmatrix

1. **OAP deaktiviert/nicht vorhanden:** Kein Debug-Tab, keine Debug-Meldungen, keine Telemetrie, normale Spielermeldungen und Addon-Funktion intakt.
2. **OAP aktiv:** Debug-Hauptreiter vorhanden; CPF als separate registrierte Quelle. `errors`/`normal`/`metrics`/`detailed` zeigen jeweils nur erlaubte Logs/Daten.
3. Timer starten/stoppen, Wecker schalten, Health-Bewegung auslösen: native Counter/Gauges im OAP-Metrics-Tab und ggf. Logs sichtbar.
4. **Inspektor:** Module/Profil/Frame öffnen; **Watch:** Timer abonnieren, Restzeit beobachten, Watch wieder entfernen.
5. **Werkzeuge:** jede OAP-Ansicht öffnet sich; normale CPF-Chatmeldungen werden nur mit OAP und ab Stufe Normal gespiegelt.
6. **Fehler:** Wiederholten Tick-Fehler simulieren (dedupliziert), danach erfolgreicher Tick und erneut Fehler (neue Meldung). Andere Module ticken weiter.
7. `/reload` und Profilwechsel: Accountweite Level-Einstellung sowie UI-Tabs bleiben korrekt. Ein realer WoW-Forever-Client-Test ist weiterhin erforderlich.
