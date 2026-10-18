## 0.3.11-alpha.1 – Alarmtypen und individuelle Darstellung (gebaut)

- Standard für neue Profile: Health `5FFF4F, pulse, 1, 10`, Alarme `FF2619, pulse, 1, 30` und Timer `3399FF, pulse, 1, 30`.
- Nur die Defaults und Fallbacks angepasst; individuell gespeicherte Effekte bleiben erhalten. Die TOC- und Release-Version wurde nach Baufreigabe auf 0.3.11-alpha.1 gesetzt.

## 0.3.10-alpha.1 – Effektmenü und getrennte Tonwiederholungen (gebaut)

- Uhr-Tooltip: Das gruen vorgefaerbte Blizzard-Info-Symbol wird als eigene Tooltip-Textur zuerst mit `SetDesaturated(true)` entsaettigt und danach mit `SetVertexColor(0.30, 0.70, 1.00)` blau eingefaerbt. Die Textur wird bei Shift und Mouseleave ausgeblendet. Bei unbenannten Tooltips wird ein blaues `(i)` als Text verwendet.

# Can't play Forever 0.2.1 – WoW Forever

> **Aktueller Versionsstand (17.10.2026):** `0.3.13-alpha.1`, inklusive serverseitiger `/played`-Abfrage und Login-/Logout-Sessionerfassung. Die Patchnummer `z` wird für jeden neuen Build erhöht; x/y nur auf ausdrückliche Anweisung. Details: [OAPDebug.md](OAPDebug.md).

> **Historischer Stand (14.10.2026):** Das untenstehende Dokument enthält auch historische Konzepte und Dateinamen. Das früher geplante Modul **Wellness** heißt ab jetzt **Health**; `Modules/Health` ersetzt `Modules/Wellness`. Health ist weiterhin standardmäßig aus, aber nicht mehr gesperrt. Die Bewegungserinnerung ist der erste funktionsfähige Baustein. Die eigenen Schalter/Slider für Trinken, Augenpausen und Schlafenszeit sind vorbereitet. Details und weiterer Plan: [Health.md](Health.md). Die neue Version `0.3.0-alpha.1` wurde am 14.10.2026 vom Nutzer für den Repo-Build freigegeben.


AddOn für eine verschiebbare Blizzard-Uhr an der Minimap mit Alarm- und Timer-Funktionen.
Die Libraries Ace3, LibStub, CallbackHandler, LibDataBroker und LibDBIcon sind vollständig eingebettet.
**Uhrgrafik:** Die große Uhr verwendet `Artwork/ClockLarge.tga` (256 × 256, 32-Bit RGBA).
Diese Grafik wurde vom Nutzer als `clock.tga` bereitgestellt und für diesen Build
unverändert übernommen. Die Uhrzeit wird live durch das Addon darüber dargestellt.
Die drei festen Größen sind Klein (32), Mittel (64, Standard) und Groß (128 UI-Pixel).
Die TGA-Datei wird **nur per `SetTexture()`** geladen und darf nicht als Zeile
in `CantPlayForever.toc` stehen. Bei 32 px wird der originale LibDBIcon-Minimap-Kreis verwendet.

## Installation

1. `Interface/AddOns/BetterClock` entfernen/deaktivieren (alter Addonname).
2. ZIP entpacken nach `Interface/AddOns/`, sodass `CantPlayForever/CantPlayForever.toc` entsteht.
3. WoW neu starten.

**Speicherstände beim Umbenennen:** WoW speichert pro Addon in separaten Dateien.
Um die alten Wecker und Timer zu übernehmen, WoW vorher vollständig beenden und
im Ordner `WTF/Account/<ACCOUNT>/SavedVariables/` die vorhandene Datei
`BetterClock.lua` **kopieren** und die Kopie `CantPlayForever.lua` nennen.
Auch eine vorhandene `BetterClock.lua.bak` bitte vorher sichern. In der neuen
`CantPlayForever.lua` bleibt die Lua-Variable `BetterClockSettings` unverändert.
Wenn WoW schon einmal mit CantPlayForever gestartet wurde, zuerst dessen
`CantPlayForever.lua` sichern, bevor eine ältere Datei darüberkopiert wird.
Die Quelldatei `BetterClock.lua` sollte als Backup erhalten bleiben.

## Uhr

- **Uhrgröße:** Der Regler hat genau drei Positionen: **Klein (32 px)**, **Mittel (64 px)** und **Groß (128 px)**.
- **Klein (32 px):** Originaler 31 × 31 px LibDBIcon-Kreis mit vergrößertem, etwas tiefer gesetztem Blizzard-Uhrsymbol. Die Uhrzeit erscheint im Tooltip.
- **Mittel (64 px, Standard):** `Artwork/ClockLarge.tga` und dynamische Uhrzeit. Die **Kreismitte** ist am Minimap-Anker ausgerichtet; beim Ziehen bewegt sich die Uhr um die Minimap.
- **Groß (128 px):** Gleiche unveränderte TGA und dynamische Uhrzeit, **komplett von der Minimap getrennt**. Sie lässt sich frei mit der linken Maustaste ziehen und speichert ihre Bildschirmposition unabhängig von der Minimap-Position. Der Standort wird proportional zur Bildschirmauflösung gespeichert.
- Ein laufender Timer erscheint unter der Zeit als blaue Zahl: über 60 Sekunden als aufgerundete Gesamtminuten (einschließlich Stunden), bis 60 Sekunden als verbleibende Sekunden. Dieselbe Schriftart wie die Uhr, kleiner und mit Umriss.
- Beim Wechsel zwischen allen drei Größen bleiben beide Positionen erhalten. Für einen gespeicherten 128-px-Stand wird ausschließlich der separate Bildschirmanker verwendet.

## Bedienung

| Aktion | Funktion |
|---|---|
| Linksklick | Vorausgewählten Timer starten; erneuter Klick stoppt ihn |
| Rechtsklick | Optionen (Allgemein) öffnen |
| Strg + Linksklick | Alle ausgewählten Wecker aktivieren; weitere Klicks deaktivieren jeweils den nächsten Alarm |
| Shift + Mouseover | Aktuelle `/played`-Daten von WoW im Uhr-Tooltip anfordern und anzeigen |

- Mehrere Wecker können für unterschiedliche Uhrzeiten scharfgestellt werden.
  Jeder löst zum nächsten entsprechenden Zeitpunkt genau einmal aus.
- Beliebig viele Timer-Vorgaben speichern, aber nur eine gleichzeitig vorauswählen.
- Der Alarm erscheint in **genau zwei roten Zeilen**: `Can't play Forever` und die individuelle Nachricht.
- In **Allgemein** gibt es vier Blizzard-SoundKits: Wecker 1, Wecker 2, Wecker 3 und Bereitschaftscheck. Einstellbare Wiederholungsanzahl **1–10**, standardmäßig **2 Töne** mit etwa zwei Sekunden Abstand; Ton kann deaktiviert werden. Bei vielen Wiederholungen bleibt die Meldung entsprechend länger sichtbar. Feste Wecker und Timer nutzen dieselbe Meldung.
- Timer-Endzeit bleibt in der Datenbank nach `/reload` erhalten.

## Daten und Befehle

`## SavedVariables: BetterClockSettings` bleibt absichtlich gleich, damit die
Datenbankstruktur nicht umgebaut werden muss. In AceDB sind accountweiter und
charakterbezogener Speichermodus auswählbar.

- `/cpf` (oder `/bc`) – Alarm-Einstellungen.
- `/cpf settings` – Allgemeine Einstellungen.
- `/cpf timer 5` – Timer über fünf Minuten.
- `/cpf stop` – Aktuellen Timer stoppen.
- `/cpf test` – Alarmton und rote Bildschirmmeldung testen.
- `/cpf help` – Hilfe.

## Versionsstand und Tests

Version **0.2.1**, WoW Interface `16001`. Die Lua-Syntax, die eingebetteten
Abhängigkeiten und die Menülogik wurden außerhalb des Spiels geprüft.
Die große TGA wird zur Laufzeit über ihren Pfad geladen. Die Darstellung
muss im WoW-Forever-Client geprüft werden, insbesondere Rahmen und Zentrierung.


## Frühere Version 0.1.5
- Einstellbare Uhrgröße von 32 bis 128 UI-Pixeln (Standard: 84).
- Unter 64px Uhrsymbol statt schwer lesbarer Ziffern. Tooltip zeigt weiterhin Uhrzeit/Timer.
- Größengerechte, zentrierte Anzeige von Uhrzeit und Countdown; gleicher Font, blau mit Umriss.
- Minimap-Verankerung wird bei jedem Größenwechsel, Ziehen und nach LibDBIcon-Refresh neu berechnet.
- Bestehende Einstellungen `BetterClockSettings` bleiben erhalten; alte kleine Uhr wird auf 32px abgebildet.

## Version 0.1.6
- 32px-LibDBIcon-Uhrsymbol von 17 auf 19px vergrößert und 2px nach unten gerückt;
  bei 33–63px Symbol ebenfalls 2px größer und 2px tiefer.
- Laufender Tooltip aktualisiert Uhrzeit **und** Timer-Sekunden sekündlich ohne erneutes Mouseover.
- Aktivierte Alarme werden mit Alarmzeit und Nachricht grün im Tooltip angezeigt.
- Standard-Timer-Vorgaben werden nur für neue Profile einmalig angelegt, nicht mehr
  als automatisch regenerierende AceDB-Defaults. Änderungen und Löschungen bleiben
  über /reload erhalten. Das bestehende SavedVariables-Format bleibt kompatibel.
- WoW schreibt SavedVariables beim regulären Logout, Beenden oder /reload auf die Festplatte.

## Version 0.1.7
- Größen-Slider mit drei festen Stufen: Klein = 32 px (Original LibDBIcon), Mittel = 64 px (Minimap-Anker im Zentrum), Groß = 128 px (frei auf dem Bildschirm verschiebbar).
- Frei gespeicherte Position für 128 px getrennt von der LibDBIcon-Minimapposition; Position bleibt bei Umschalten, /reload und Auflösungsschwankungen relativ zur Bildschirmgröße erhalten.
- Alarmmeldung jetzt exakt zwei Zeilen: `Can't play Forever` und darunter die individuelle Alarmnachricht, beide rot.
- Vier echte WoW-SoundKits (Wecker 1, 2, 3, Bereitschaftscheck), über das Menü auswählbar.
- Wiederholungen von 1 bis 10 einstellbar, Standard zwei; etwa zwei Sekunden Abstand.
- Alarme und Timer werden weiterhin unter `BetterClockSettings` gespeichert.

**Hinweis zu 0.1.7:** Die großen Positionen gehören nun zum Bildschirm, nicht zur Minimap.
Der optische und akustische Test im Forever-Client steht noch aus.

## 0.1.8: Uhrpositionen und Größen-Slider

- Größen-Slider zeigt 32 px, 64 px oder 128 px anstelle interner Stufenwerte.
- Standardposition: 32 px = 180° von Norden (Süden), 64 px = 0° von Norden (Norden).
- 128 px = Bildschirm oben mittig (16 px Abstand oberhalb des 128-px-Kreises).
- Button **Position zurücksetzen** betrifft nur die gerade gewählte Größe.
- 32/64-px-Positionen werden unabhängig voneinander gespeichert. Die frei verschiebbare 128-px-Uhr bleibt ebenfalls separat gespeichert.
- Gespeicherte Positionen der Vorgängerversion werden beim Umstieg nach Möglichkeit beibehalten; der Reset stellt die neuen Standardpositionen her.


## 0.1.9 – Controls and localization / Steuerung und Sprachen / Commandes et langues

- DE: Linksklick startet/stoppt den vorausgewählten Timer. Shift+Linksklick aktiviert die ausgewählten Alarme und deaktiviert sie bei weiteren Klicks einzeln in zeitlicher Reihenfolge. Rechtsklick öffnet die Optionen.
- EN: Left-click starts/stops the selected timer. Shift+left-click arms selected alarms; subsequent clicks disarm the next due alarm one at a time. Right-click opens options.
- FR: Clic gauche pour démarrer/arrêter le minuteur sélectionné. Maj+clic gauche pour activer les alarmes ; les clics suivants désactivent une alarme à la fois, par ordre chronologique. Clic droit pour les options.

AceLocale-3.0 loads `enUS`, `deDE`, and `frFR` UI translations using the game client locale. Saved user-entered alarm messages and preset names are preserved without translation.


## 0.1.10 – Aufräumen / Cleanup

- Ungenutzte Bibliotheken AceEvent-3.0 und AceDBOptions-3.0 entfernt.
- LibStub-Testdateien und doppelt mitgelieferte LibStub-, CallbackHandler- und LibDataBroker-Kopien in LibDBIcon entfernt; die Addon-Größe sinkt deutlich.
- Doppelten Strg+Linksklick-Zweig entfernt (Verhalten unverändert: wie Linksklick).
- Keine Funktionsänderung, SavedVariables bleiben kompatibel.


## 0.1.11 – Original-Blizzard-Optik bei 64 px (experimentell)

- Die 64-px-Uhr kann jetzt Globus (`Interface\TimeManager\GlobeIcon`) und Bronzering (Atlas `UI-Frame-PortraitMetal-CornerTopLeft`) des Blizzard-Uhrfensters aus den Spieltexturen verwenden. Umschaltbar unter Uhr → „Original-Blizzard-Optik (64 px)“.
- Fehlt der Atlas im Client, wird automatisch die mitgelieferte `ClockLarge.tga` benutzt. 32 und 128 px bleiben unverändert.
- `/cpf ring` zeigt, ob der Ring-Atlas vorhanden ist und wie groß er ist (zum Feinjustieren der Ringgröße).
- Nicht im Spiel geprüft: Ringgröße und -position sind aus den Blizzard-Quelltexten abgeleitet bzw. geschätzt.


## 0.1.12
- Die experimentelle Original-Blizzard-Optik (64 px) ist jetzt standardmäßig aus (Opt-in unter Uhr), weil der Ring-Atlas im Test nicht wie erwartet aussah.
- `/cpf ring` zeigt zusätzlich eine Vorschau: den Ring-Atlas ungeschnitten (links) und den Globus (rechts). Erneut eingeben blendet sie aus.


## 0.1.13
- Ring-Zuschnitt anhand der `/cpf ring`-Vorschau neu vermessen (Ausschnitt x 3..66, y 6..69 des 95×95-Atlas), Rahmenleisten werden abgeschnitten. Original-Optik bei 64 px wieder standardmäßig an (abschaltbar).
- Ring wird jetzt als vollständiger Atlas in einem zuschneidenden Rahmen dargestellt (statt per SetTexCoord), weil der Ring im Test nicht sichtbar war.
- Kreismaske um den Ring, damit Rahmenleisten-Reste des Atlas nicht mehr sichtbar sind.
- Kreismaske neu zentriert (an der Vorschau vermessen), damit unten links keine Ecke mehr sichtbar ist.
- `/cpf ring`-Vorschau zeigt jetzt zusätzlich den fertigen Ring mit Maske und ohne Maske in doppelter Größe.
- Die Uhr liegt jetzt (Frame-Strata HIGH) über den übrigen Minimap-Symbolen und wird nicht mehr verdeckt.
- Verdeckt die Uhr (64/128 px) ein anderes sichtbares Minimap-Element, leuchtet der innere Kreis dauerhaft gelb. Geprüft wird einmal pro Sekunde.
- Kreismaske verkleinert (63 → 58,5), nach Vermessung der `/cpf ring`-Vorschau: Die Maske war effektiv ca. 5 % größer als der Ring.
- Verdeckungs-Hinweis: Mit Original-Optik leuchtet jetzt der Bronzering golden (statt gelber Fläche über dem Globus). Die Uhr liegt in der Strata FULLSCREEN mit hohem Frame-Level, also über den übrigen Minimap-Symbolen.
- Kreismaske neu vermessen (Durchmesser 60,5, Mitte um 2,5/0,6 verschoben): Sie war zu klein und saß zu weit links unten, wodurch oben rechts ein Teil des Rings abgeschnitten wurde.
- Verdeckungs-Hinweis: gelbes Leuchten wieder an der Stelle des blauen Mouseover-Leuchtens, jetzt doppelt additiv (intensiver, weniger transparent).
- Kreismaske nachjustiert (Durchmesser 61,5, Mitte 2,7/-0,8), damit der Ring unten rechts nicht mehr angeschnitten wird.
- Ring-Ausschnitt auf 67 px vergrößert (rechts war der Ring durch den Rahmen leicht abgeflacht), Maske entsprechend neu zentriert.
- Kreismaske um 0,5 px nach oben verschoben (`RING_MASK_DY` in Core.lua); der Ring selbst bleibt an seiner Original-Position.
- Kreismaske an allen Seiten 0,5 px kleiner (Durchmesser 60,3) und 0,5 px höher.
- Kreismaske unten 0,5 px größer (Breite 60,3, Höhe 60,8; Oberkante unverändert).
- Der Globus bekommt eine eigene Kreismaske (Durchmesser 57 px unter dem Ring): Die dunklen Ecken der Globus-Textur (abgerundetes Quadrat) ragten sonst hinter dem Ring heraus und sahen an der Minimap wie Schatten-Artefakte aus.
- Leichter schwarzer Schatten um den Ring (Konstanten `SHADOW_SIZE`, `SHADOW_ALPHA`, `SHADOW_DROP` in Core.lua), wie bei den Blizzard-Minimapsymbolen.
- Ringschatten dünner und dunkler (Durchmesser 62 statt 66, Deckkraft 0,7), damit er wie beim Mond-Symbol nur als schmale dunkle Kontur um den Ring erscheint.
- Verdeckungs-Leuchten ist jetzt orange statt grünlich-gelb (Textur wird entsättigt, dann orange eingefärbt).
- Leuchtzustände des inneren Kreises (Tabelle `GLOW_STATES` in Core.lua, Priorität von oben nach unten):
  Alarm/Timer ausgelöst = rot, schnelles Pulsieren; Timer in den letzten 10 Sekunden = orange, Pulsieren;
  Uhr verdeckt etwas = orange, dauerhaft; Wecker scharf = blau, langsames Blinken.
- Leuchten ohne feste Standardzustände: Wer etwas anzeigen will, ruft `Clock:SetGlow(key, spec, priorität)` mit den Werten auf, `Clock:ClearGlow(key)` beendet es. `spec` = `Farbcode, Typ, [Sekunden,] Prozent`, z. B. `FF8000, pulse, 2, 55` oder `FF8000, static, 80`; Typen `static`, `pulse` (weich), `blink` (hart). Es leuchtet der Eintrag mit der höchsten Priorität. Aktuell setzen Alarm (rot, Priorität 40), Timer-Ende (orange, 30) und Verdeckung (rot, dauerhaft, 80 %, 20) ihre Werte selbst.
- Alle Tests laufen über `/cpf probe`: `/cpf probe ring` (Ring-Vorschau), `/cpf probe glow FF8000, pulse, 2, 55` (10 Sekunden, `off` beendet), `/cpf probe alert` (Alarmmeldung). Die Befehle `/cpf ring` und `/cpf glow` entfallen.
- Statussymbole oben links am Ring (Tag/Nacht-Stil, kleiner, im Rington): Glocke = Wecker scharf, Taschenuhr = Timer läuft. Das blaue Blinken für „Wecker scharf" ist entfallen.
- Leuchten wird per Kreismaske (52 px) auf die Innenfläche des Rings begrenzt und liegt unter dem Ring.
- Tooltip neu gestaltet: Titel mit Uhr-Symbol, graue Beschriftungen mit heller Uhrzeit, Timer in Blau, aktive Wecker grün, Abstände zwischen den Abschnitten, Bedienhinweise zweispaltig (Taste in Gold, Wirkung hell).
- Statussymbole kleiner (18 statt 24 px) und weiter oben links am Ring.
- Leuchten: einfarbige, additive Fläche statt bläulicher Mouseover-Textur, damit die Farben exakt dem Farbcode entsprechen (vorher wirkte der Globus blaugrau).

### Tuning-Fenster (Entwicklung, Version bleibt 0.1.13)
- `/cpf probe tune` (oder `/cpftune`) öffnet das Tuning-Fenster: Ring-Ausschnitt, Ring-Maske, Globus-Maske, Schatten, Glow (Größe/X/Y) und Symbole (Glocke/Uhr) per +/- oder Werteingabe, Umschalt = Schritt x10, Schrittweite je Zeile änderbar.
- „Ausgabe kopieren“ zeigt alle Werte als Text (Strg+A, Strg+C) mit Markierung der geänderten Werte; „Alles zurücksetzen“ stellt die Standardwerte wieder her. Werte werden in `CPFTuneDB` gespeichert.
- Aufbau: `Probe/Tune.lua` ist allgemein (kennt CantPlayForever nicht), `Probe/CantPlayForeverBridge.lua` registriert die Werte. Als eigenes Addon: Ordner `Probe` mit eigener .toc (`SavedVariables: CPFTuneDB`) auslösen.
- Anzeigename überall „Can't play Forever“ (Tooltip, Optionen, Meldungen); Ordner/IDs bleiben `CantPlayForever`.
- Tooltip-Titel ohne Symbol.
- Das Tuning-Fenster arbeitet auf einer **Testbühne** (vergrößerter Nachbau der Uhr mit Schatten, Globus, Maske, Ring, Glow, Symbolen), nicht an der echten Uhr. „Auf Uhr anwenden“ überträgt die Werte; Laden und „Alles zurücksetzen“ wirken auch auf der Uhr.
- Glow-Form einstellbar: `GLOW_SHAPE` 0 = gefüllte Fläche, 1 = Ring (Mouseover-Textur, eingefärbt), 2 = beides; Ring mit eigener Größe und X/Y.
- Neu im Tuning: Uhrzeit-Text (Größe mit/ohne Timer, max. Breite, X/Y), Timer-Zahl (Größe, max. Breite, X/Y, anhängbarer Text hinter Minuten/Sekunden, z. B. „min“/„sec“), Indikator-Symbole (Farbe, Ring an/aus, Einzelfaktor je Symbol, Position). Die Bühne zeigt Beispieltexte; Timer an/aus und Minuten/Sekunden sind dort schaltbar.
- Übernommene Tuning-Werte (Standard jetzt): Symbole Glocke (-24/25) und Uhr (-32,5/7,5), Uhrzeit-Text Größe 25 (mit Timer 14,1), max. Breite 45, X -1, Y 1 (mit Timer 4,9), Timer-Zahl Größe 11,4, Y -9, Zusatztexte „min“/„sec“.
- Timer-Warnleuchten: in den letzten 10 Sekunden (`TIMER_WARN_SEC`) leuchtet ein blauer Ring, Größe 95 (`TIMER_WARN_GLOW = 3399FF, pulse, 1, 90, ring, 95px`; Priorität 25, unter Alarm/Timer-Ende, über „Uhr verdeckt“). Glow-Spec kennt jetzt optionale Zusätze `ring|fill|both` und `95px`; beides im Tuning-Fenster einstellbar.
- Alarm, Timer-Ende und „Uhr verdeckt“ leuchten fest als volle Fläche (`fill`, normale Größe), unabhängig vom globalen Wert `GLOW_SHAPE`; nur die Timer-Warnung nutzt den Ring (95px).
- Bearbeiten: gespeicherte Timer-Vorgaben lassen sich jetzt in den Optionen umbenennen und in Stunden/Minuten/Sekunden ändern; ein laufender Timer kann mit „Laufenden Timer auf diese Zeit setzen“ (Zeit aus dem Bereich „Neuen Timer starten“) auf eine neue Restzeit gesetzt werden. Alarme waren bereits bearbeitbar (Stunde, Minute, Text).
- Timer-Anzeige: ab mehr als 1 Stunde Restzeit wird in Stunden mit zwei Nachkommastellen angezeigt (1 h 5 min = 1,08) (Zusatztext `hrs`, `CD_SUFFIX_HRS`), darunter Minuten (`min`), in der letzten Minute Sekunden (`sec`).
- Der frühere orange Timer-Ende-Glow (letzte 10 s) ist entfernt: letzte 10 s = blauer Ring 95px, Ablauf = Alarm (rot, gefüllt, Standardgröße).
- Modul-Gerüst: neuer Optionsreiter „Module“ mit Schaltern für Clock (immer aktiv), Timer, Alarms sowie Wellness, Statistics und Events (geplant, gesperrt). Ausgeschaltete Module verschwinden aus den Optionen und von der Uhr (Prüfung, Symbole, Leuchten, Zahl); Zustand je Profil in `profile.modules`, Abfrage über `Clock:IsModuleEnabled(id)`, Liste in `Clock.MODULES`.


### Struktur (Modulsystem, geladen über XML)
```
CantPlayForever/            nur .toc, .xml und README.md im Hauptordner
  CantPlayForever.toc  ->  CantPlayForever.xml  ->  Libs, Core, Modules
  Core/                     nur Funktionen für alle Module: Core.lua (Addon, Profil, Module,
                            Slash), Alert.lua (Meldung/Ton), Options.lua (Optionsgerüst), Locales/
  Media/                    Texturen und Bilder (ClockLarge.tga)
  Libs/                     alle Bibliotheken
  Modules/<Name>/           je Modul ein Ordner mit <Name>.xml, Lua-Dateien, Options.lua, Locales/
    Clock/  Timer/  Alarms/ umgesetzt
    Wellness/  Statistics/  Events/   geplant (gesperrt unter Optionen > Module)
Frame_Debugger/             eigenes Entwicklungs-Addon (Tuning-Fenster, Testbühne, Rahmen-Diagnose, Testbefehle)
```
Ein Modul meldet sich mit `Clock:RegisterModule({id=..., OnInitialize, OnEnable, OnTick, OnChanged, OnRefresh, OnSlash, GetOptions})` an; die Ladereihenfolge in `Modules/Modules.xml` bestimmt die Reiterreihenfolge. Übersetzungen liegen im jeweiligen `Locales/`-Ordner (Kern: `Core/Locales`, sonst im Modul); AceLocale erweitert dieselbe Sprachtabelle.
- Das Probe-Modul ist jetzt ein eigenes Addon `Frame_Debugger` (früher CantPlayForever_Probe; Abhängigkeit: CantPlayForever, eigene SavedVariables `CPFTuneDB`).
- Ordnerumbau: `Artwork/` heißt jetzt `Media/`, `Options.lua` und `SizeSlider.lua` liegen in `Core/` bzw. `Modules/Clock/`, das Zip enthält beide Ordner.
- Bildschirmrand-Leuchten: Option unter Allgemein „Bildschirmrand bei Alarm leuchten lassen“ (standardmäßig aus). Nutzt die Vollbild-Textur `Interface\FullScreenTextures\LowHealth` (wie bei wenig Leben); Farbe/Art/Stärke per Leuchtzeile, Standard `FF2619, pulse, 1, 80`. Leuchtet, solange die Alarmmeldung sichtbar ist (Alarm und Timer-Ende).
- Bildschirmrand-Leuchten bleibt in Instanzen, Raids und Schlachtfeldern aus (Option „Nicht in Instanzen und Raids“, standardmäßig an).
- Optionen: „Allgemein“ hat jetzt die Unterreiter „Optionen“ (bisherige allgemeine Einstellungen) und „Module“. Bildschirmrand-Leuchten besteht aus vier Farbverlauf-Streifen (keine Bilddatei). Timer-Warnung (letzte 10 s) nutzt den Mouseover-Ring in Originalfarbe (`native`, `ring`, 95px).
- Timer-Einheiten sind lokalisiert (hrs/min/sec, Std/Min/Sek, h/min/s); die Textfelder im Tuning überschreiben sie, leer = Sprache.
- Optionsfenster: das eckige Titelschild ist durch ein rundes Logo (Globus mit Bronzering wie die Uhr) ersetzt; der Titel steht rechts daneben. Beim Schließen wird das Schild für andere Addons wiederhergestellt (`Modules/Clock/OptionsLogo.lua`).

- Anzeigename einheitlich „Can't play Forever“ (Tooltip, Optionen, Meldungen, .toc); Optionsfenster ohne Titeltext, unten die Version aus der .toc statt des Statuskastens.
- Tab-Logos: Das runde Logo im Optionsfenster wechselt mit dem Reiter. Bilder liegen als 256×256-TGA in `Media/Logos/` (clock_logo, alarm_logo, timer_logo, wellness_logo, pausen_logo, event-calender_logo); jedes Modul trägt sein Bild im `logo`-Feld seiner Registrierung. Allgemein zeigt `allgemein_logo` (Schriftzug), Reiter ohne Bild Globus mit Ring.
- Logos: alle Ringe auf identische Ringhöhe (191 von 256 px, Höhe des Allgemein-Rings) normalisiert, gleiche Anzeigegröße für alle Reiter.
- Optionen: Timer-Preset-Knopf wird beim laufenden Preset zu „Stoppen“ (activeTimer.presetID); jeder Alarm hat einen Aktiv-Schalter (Clock:SetAlarmArmed).
- Reiter Allgemein steht ganz vorne (order 0). ZIP wird erst nach OK des Nutzers neu gebaut.
- Allgemein > Optionen: Tab „Alarm“ mit Bereichen Speichern, Audio, Visualisierung.
- Uhr-Reiter: Hauptschalter oben, Bereiche Darstellung/Größe/Position, Größe als Klein/Mittel/Groß (ohne px), kein Beschreibungstext, Blizzard-Optik-Option entfernt (Code bleibt, nicht mehr einstellbar).
- Große Uhr: gleiche Grafik wie mittlere, Durchmesser 95 px statt 128 (alte 128-Profile werden auf 95 migriert).
- Einrastpunkte: mittel bei Minimap-Norden (±8°), groß oben mittig oder unten rechts (40 px), klein frei. Klein zeigt kein Icon (Platz für spätere Analoguhr).
- Analoguhr (Modules/Clock/AnalogClock.lua): Größe „Klein“ zeigt Punkte bei 12/3/6/9 Uhr und Stunden-/Minutenzeiger (kein Sekundenzeiger) (Linien, 1-s-Update, folgt Ortszeit/Serverzeit).
- Klein: eigener Zifferblatt-Hintergrund (ClockLarge-Grafik, wie mittel) statt LibDBIcon-Rahmen/-Hintergrund; Punkte und Zeiger sind auf diesen Ring abgestimmt.
- Glow (Alarm, letzte Timer-Sekunden) wirkt jetzt auch bei der kleinen Uhr, unter der Analoguhr. Cover-Glow bleibt ab Mittel.
- Klein: letzte Timer-Sekunden füllen den ganzen Kreis blau (TIMER_WARN_GLOW_SMALL), sonst Ring wie gehabt.
- Schalter Analog/Digital (Uhr > Darstellung) für Mittel und Groß (Klein immer analog); Blizzard-Globus+Ring für alle drei Größen (skaliert, wie mittel); 
- Analog bei Mittel/Groß: Timer-Zahl bleibt sichtbar, hinter den Zeigern.
- Sekundenzeiger (rot) bei Mittel und Groß; Klein ohne.
- Analoguhr überarbeitet: elfenbeinfarbene Zeiger mit Schatten, rote Sekundenzeiger mit Gegengewicht, goldene runde Nabe und runde Punkte (12-Uhr-Punkt größer).
- Analoguhr: Mittel/Groß zeigen 12 Punkte (12/3/6/9 größer), Klein nur die vier großen.
- Analoguhr mit gezeichneten Grafiken (Media/Analog: Zeiger mit Kontur/Schatten, Nieten, Nabe), per SetRotation gedreht; Zeiger-Grafiken lassen sich in Media/Analog austauschen.
- Analoguhr: keine Nabe mehr; statt Nieten dezente dunkelbronzene Strichmarken (tick.tga) knapp innerhalb des Rahmens.
- Kleine Analoguhr (32 px) zurück auf die Linien-Version (eingefroren); Strichmarken bei Mittel/Groß mit Bronzematerial aus dem Atlas-Ring (Maske), Rückfall auf tick.tga.
- Striche bei Mittel/Groß jetzt als ein fertig gezeichnetes Zifferblattbild (dial_ticks.tga): zwölf gleich starke Striche am gemeinsamen äußeren Kreis, lange bei 12/3/6/9, ohne Maskendrehung.
- dial_ticks: Farbprofil aus dem vom Nutzer gelieferten Ringausschnitt (dunkle Kante, Bronze, Glanzkern), symmetrisch.
- Stundenzeiger so schmal wie der Minutenzeiger.
- Bildschirmrand-Glow pulsiert im Takt (Art und Periode) des Alarm-Glows der Uhr, gleiche Phase über GetTime().
- Kleine Uhr: jetzt wie Mittel/Groß mit gezeichneten, glatten Zeigern; vier dezente dunklere Punkte (dial_dots_small.tga) statt Linien-Version.
- Kleine Uhr: Ziffernblatt 1 px nach links/oben versetzt (SMALL_OFFSET_*), eigener kräftigerer Stundenzeiger (hand_hour_small.tga).
- Analoguhr: Sekundenzeiger ausgeblendet, solange ein Timer läuft.
- Kleine Uhr: Stundenzeiger etwas schmaler (hand_hour_small.tga), Minutenzeiger wie bei Mittel/Groß.
- Optionen: nur zwei Ebenen. Allgemein hat die Unterreiter „Alarme“ (Speichern/Audio/Visualisierung) und „Module“; der Zwischenreiter „Optionen“ entfällt.
- Optionen-Struktur: Hauptreiter Allgemein (Speichern, Module), Optionen (Uhr, Audio, Effekte), Alarme, Timer. Befehlsübersicht unter Allgemein > Speichern.
- allgemein_logo.tga ist jetzt das Stahl-Emblem „Can't Play Forever“; es erscheint bei Allgemein und Optionen (Ring gleich groß wie die anderen Logos).
- Logos neu (Media/Logos, alle Ringe gleich hoch): allgemein (Reiter Allgemein), optionen (Reiter Optionen), uhr (Optionen > Uhr), alarm, timer, pause (Wellness), kalender (Events). Alte Bilder clock/pausen/wellness/event-calender entfernt.
- Optionsfenster-Logo ohne Schatten/Rauten; Zuordnung fest: Allgemein=allgemein, Optionen=optionen, Alarme=alarm, Timer=timer; Unterreiter ändern das Logo nicht.
- Zwei Stahl-Rauten (diamond.tga, um 45° gedrehtes Quadrat wie in den Rahmenecken) am Übergang Kreis/Rahmenlinie; Werte DIAMOND_* in OptionsLogo.lua.
- /cpf frame: Diagnose der Fensterrand-Texturen (Raute in den Ecken) zum Nachbauen mit Spielgrafik.
- Raute im Optionen-Logo nutzt jetzt die Spielgrafik UI-Frame-DiamondMetal-CornerTopLeft (Fallback: eigene Raute).
- Raute: nur obere Atlas-Hälfte, Linie zum Kreis, rechts gespiegelt, entsättigt (DIAMOND_CROP/X/Y in OptionsLogo.lua).
- Raute: komplette Eckgrafik, 45° gedreht (Linien schräg zum Kreis), rechts TopRight-Atlas bzw. gespiegelt.
- Rauten im Optionen-Logo: Werte DIAMOND_X/Y/SIZE/R/G/B im Probe-Tuning-Fenster (/cpftune), Gruppe „Optionen-Logo Rauten“.
- Optionen-Logo: LOGO_X/LOGO_Y im Tuning (Standard Y 32, vorher 22).
- Rauten/Logo: Werte aus dem Tuning übernommen (Logo Y 24.5, Raute X 27/Y 0/Größe 30, Farbe 0.78/0.8/0.85, entsättigt).
- Rauten/Logo: neue Tuning-Werte (Logo Y 25, Raute X 28.5/Größe 34, Farbe 1.1/1.1/0.95, entsättigt).
- Optionen > Audio: Alarmton und Wiederholung je eine eigene Zeile.
- Audio: Knopf "Play" mit Text "Ausgewählten Ton anhören" daneben; Sprachprüfung: alle Schlüssel in en/de/fr vorhanden.

### Frame_Debugger und Debug-Meldungen (Version bleibt 0.1.13)
- Alle Tests und Diagnosen liegen im eigenen Addon `Frame_Debugger` (früher `CantPlayForever_Probe`; alten Ordner löschen): `/cpftune` bzw. `/cpf probe tune` (Tuning und Testbühne), `/cpf probe ring|glow|alert`, `/cpf frame` (Rahmen-Diagnose), `/cpf test` (Alarm testen). Ohne das Addon entfallen diese Befehle; die Tuning-Werte bleiben als Standard im Hauptaddon, gespeichert in `CPFTuneDB`.
- Das Hauptaddon enthält keine Test- und Diagnosecode mehr (Ring-Vorschau und Rahmen-Diagnose sind umgezogen). Der Knopf „Alarm jetzt testen“ in den Optionen bleibt.
- Debug-Meldungen: Schalter „Debug-Meldungen anzeigen“ unter Allgemein (account-weit, Standard aus). `Clock:Debug(format, ...)` schreibt nur bei eingeschaltetem Schalter in den Chat (Module, Timer, Wecker, Alarm, Optionen, Speichermodus).
- Kleine Uhr: Standard-Minimap-Rahmen der Bibliothek (Rahmen, dunkle Scheibe, Größe 31) statt eigenem Bronzering; Zifferblatt/Zeiger auf der Scheibe (T.SMALL_FACE/DX/DY im Frame_Debugger-Tuning, Gruppe "Kleine Uhr").
- Kleine Uhr: schwarzer Hintergrund; Punkte-Größe (SMALL_DOTS) und Zeigergröße (SMALL_HAND) getrennt im Tuning.
- Kleine Uhr: Zeiger als dünne Linien, Punkte als kleine Flächen (keine herunterskalierten Texturen); Länge/Dicke/Abstand in /cpftune (Gruppe "Kleine Uhr"), Mitte Y 0,5.
- Kleine Uhr: Punkte wieder als Textur (dial_dots_small, T.SMALL_DOTS), Zeiger bleiben dünne Striche.
- Kleine Uhr: Zeigerwerte aus dem Tuning übernommen (Stunde 5/1.5, Minute 10/0.75).
- Timer-Symbol an der Uhr: timer_icon.tga im Standardrahmen der Bibliothek, Rahmenfarbe (Standard entsättigt, 1.1/1.1/0.95) im Tuning (Gruppe Indikator-Symbole).
- Alarm-Symbol an der Uhr: alarm_icon.tga im selben Standardrahmen wie das Timer-Symbol (gleiche Rahmenfarbe, Größe/Lage ALARM_*).
- Timer- und Alarm-Symbol: Farbe je Symbol im Tuning (Entsättigen, Rot, Grün, Blau; Standard Originalfarbe).
- Alarm-Symbol: erscheint, sobald ein Wecker angelegt ist (normale Farbe); sind Wecker aktiviert, ist es grünlich (ALARM_ARMED_R/G/B im Tuning).
- Shift+Linksklick auf die Uhr deaktiviert Wecker jetzt von hinten: zuerst der am weitesten entfernte (auch einer, der erst morgen klingelt), zuletzt der, der heute noch am frühesten klingeln würde.
- Reihenfolge beim Deaktivieren mit Shift+Linksklick einstellbar (Optionen > Alarme): „Entferntester zuerst“ (Standard) oder „Nächster zuerst“ (Profilwert alarmDisarmOrder).
- Timer-/Alarm-Symbol größer (Faktor 1.6) und Bildgröße (Standard 22) und Rahmengröße (Standard 53) je Symbol einzeln einstellbar (TIMER_/ALARM_ICON_SIZE, _FRAME_SIZE).
- Symbole: Werte aus dem Tuning übernommen (Faktor 1, Alarm-Bildgröße 28, Rahmen nicht entsättigt).
- Symbole: weitere Tuning-Werte übernommen (Timer-Bildgröße 28, Timer-Symbol grün 0.25/1/0.25, aktiviertes Alarm-Symbol 0.25/1/0.25).
- Alarm-Symbol ohne aktivierte Wecker entsättigt (ALARM_ICON_DESAT = 1, Farbe ALARM_ICON_R/G/B).
- Timer-Symbol näher am Alarm-Symbol (TIMER_X -30.5, TIMER_Y 12, vorher -32.5/7.5).
- Gespeicherte Alarme als Zeile: Haken (aktiv), Name - Uhrzeit - täglich, Zahnrad klappt die Bearbeitung auf.
- Alarme: Modus täglich / Wochentage / festes Datum, Option "Wiederholen" (sonst einmalig); Disarm-Reihenfolge und Tooltip berücksichtigen Tage.
- Datumsalarme mit "Wiederholen" klingeln jährlich.
- Alarm-Reiter aufgeräumt: nur Anlegen + gespeicherte Alarme (Trennlinien, Bearbeitungsmaske im Rahmen); Reihenfolge Shift+Links unter Optionen > Alarme.
- Alarm anlegen aufklappbar (Button "Neuen Alarm anlegen"); Wochentage in einer eigenen Zeile.
- Bearbeiten-Button verwendet jetzt die Blizzard-Textur `Interface\Buttons\UI-OptionsButton`; per Desaturierung + VertexColor grau, bei Hover blau.
- Mülleimer-Symbol je Alarm mit Löschabfrage: nach Verfügbarkeit Blizzard-Atlas `common-icon-delete`, sonst `Media/Badges/delete_bin.tga`; bei Hover rot eingefärbt.
- Zahnrad/Mülleimer enger beieinander, grau und bei MouseOver farbig.
- Zeitplan neu: Wochentage immer sichtbar (Button "Alle Tage"), Datum mit Dropdowns und "Jeden Monat"/"Jedes Jahr"; Tag bei gesetzten Wochentagen ausgegraut. Alte Alarme werden migriert.
- Tag-Auswahl richtet sich nach Monat/Jahr (Februar, Schaltjahr); zu kurze Monate: Alarm am letzten Tag des Monats.
- Zeilen-Symbole: Bearbeiten und Löschen werden jetzt mit `SetDesaturated(true)` + `SetVertexColor` grau und bei Hover blau/rot eingefärbt; andere Zeilen-Symbole behalten ihre bisherige Bildlogik. Standard-Hervorhebung aus.
- Bearbeiten-Maske: Alle Tage (an/ab) vor den Tagen, Tag/Monat/Jahr mit Haken in einer Zeile, Alarmnachricht füllt die Zeile.
- Shift+Linksklick schaltet nur Alarme ab, die dafür ausgewählt sind.
- Optionsfenster nicht mehr in der Größe veränderbar (Anfasser unten rechts entfernt).
- Bearbeiten-Maske in fünf feste Zeilen gegliedert (Shift / Zeit+Nachricht / Tage / Datum / Wiederholen).
- Timer-Liste wie die Alarmliste: Kreis mit Haken (genau einer), Zahnrad, Mülleimer, Sanduhr (Start/Stopp), Bearbeitungsmaske im Rahmen; Hilfetext oben entfernt. Gemeinsame Zeilen-Symbole in Core/RowIcons.lua.
- Löschabfrage (für Alarme und Timer) und Shift-Reihenfolge jetzt unter Allgemein; Reiter Optionen > Alarme entfällt.
- Allgemein: Alarme als eigener Kasten (kein Reiter) mit Erklärtext und Shift-Reihenfolge.
- Timer: Sanduhr ganz vorn, Standard-Haken; Timer-Vorgabe als Button "Timer anlegen" über der Liste mit aufklappbarer Maske.
- Alarme: "Vorausgewählte aktivieren" entfernt; "Alle Wecker deaktivieren" als Button unten links neben Schließen (außerhalb des Scrollfensters).
- Effekte: Pulsgeschwindigkeit (Pulse pro Sekunde) einstellbar, gilt für Uhr- und Bildschirmrand-Leuchten.
- Standardwerte: Bildschirmrand-Leuchtzeile FF2619, pulse, 1, 30; Pulsgeschwindigkeit 1 Puls/s.

## 0.2.0
- Alarme mit Zeitplan (täglich, Wochentage, Datum, jeden Monat/jedes Jahr, Wiederholen), neue Alarm- und Timer-Listen mit Symbolen (Haken, Sanduhr, Zahnrad, Mülleimer) und aufklappbarer Bearbeitung, einstellbare Pulsgeschwindigkeit, feste Fenstergröße der Optionen; ZIP heißt jetzt `CantPlayForever_0.2.1.zip`.
- Option: Standard-Uhr von Blizzard ausblenden (Optionen > Uhr).
- Blizzard-Uhr: standardmäßig ausgeblendet, solange die eigene Uhr aktiv ist; bei abgeschalteter Uhr zeigt Blizzard seine wieder.

## 0.2.1
- Blizzard-Uhr an der Minimap wird standardmäßig ausgeblendet, solange die eigene Uhr aktiv ist (abschaltbar unter Optionen > Uhr).
- Stoppuhr: Strg+Rechtsklick auf die Uhr öffnet/schließt die Blizzard-Stoppuhr (Stopwatch_Toggle).
- Alt+Rechtsklick auf die Uhr öffnet das Menü der Original-Uhr (TimeManager_Toggle).

- OAP Debug: Debug-Tab nur bei geladenem OAP; verifizierte OAP-1.1-API integriert (Log, Inspect, Chat, Count, Gauge, Time, Start/StopTimer, Watch/Unwatch, Show). Native Metrics-Tab-Messungen und Live-Watches; ohne OAP keine eigene Debug-Ausgabe.

### OAP Debug 1.1 – Quellcodeprüfung (unreleased)
- Nutzer stellte das vollständige OAP-Debug-1.1-ZIP bereit. API_VERSION=2 in `Core.lua` bestätigt; `HelpUsage.lua` dokumentiert die Stufen errors/normal/metrics/detailed.
- Die früheren Metriken wurden auf native OAP-Counter/Gauges/Timer umgestellt; Inspector-Telemetrie bleibt ergänzend. Kein Debug-Tab, Debug-Output oder Debug-Telemetrie ohne geladenes OAP.
- Debug-Reiter um Inspector/Watch-Aktionen und Navigationsknöpfe für OAP-Tabs erweitert.
- `Clock:Print` bleibt Spieler-Chat-Ausgabe und wird ab Stufe Normal zusätzlich als Chat-Kopie an OAP gespiegelt.
- Realer Ingame-Test ausstehend.

## AddonCompartmentFrame (vorbereitet für 0.3.2-alpha.1)

Eigener registrierter Compartment-Eintrag: Klick öffnet das allgemeine Optionsmenü, Mouseover zeigt die Bedienung mit vorhandenen Uhr-Texten. Registrierung nur bei vorhandenem Blizzard-API und einmal pro geladenem Addon. Keine Veränderung des Minimap-Buttons. Ingame-Verifikation steht noch aus. Keine Versionsänderung/kein Repo-ZIP ohne separate Freigabe.

## 0.3.2-alpha.1 – Geplante Ingame-Prüfung

- Allgemein zeigt über dem in allen Tabs identischen, mittigen Uhrkreis den
  transparenten Schriftzug in ca. 50px Höhe; Tab-Abstände links/rechts prüfen,
  insbesondere mit/ohne Health und OAP Debug.
- Uhren-Tooltip: Aktuelle Session direkt unter Uhrzeit; Shift erweitert um
  Char-/Stufen-/Account-Spielzeit und Trennstrich; Switch-Shift live testen.
- Blizzard AddonCompartment: Eintrag, Klick öffnet Allgemein, Tooltip-Bedienung.
- `/played` liefert asynchron Serverdaten; auf erstes Login, Level-Up und `/reload`
  prüfen. Accountsumme umfasst nur bereits einmal angemeldete, erfasste Chars.

## Regression-Untersuchung 0.3.2-alpha.1 – Optionskopf und Minimap-Kollision

- Vergleich 0.3.1 vs. 0.3.2: `Modules/Clock/Glow.lua` und die ursprüngliche
  Minimap-Positionierung waren unverändert. Die neue `/played`-Routine lief jedoch
  ungeschützt vor `RunHook('OnTick')`; ein Fehler konnte damit den gesamten
  Modul-Ticker dieses Sekundenintervalls blockieren.
- `RegisterAddonCompartment()` wurde vor Anlage des Core-Tickers direkt aufgerufen.
  Ein API-Fehler dort konnte `OnEnable` abbrechen und dadurch die periodischen
  Kollisionstests ganz verhindern.
- In dieser Reparatur alle neuen potenziell fehlerhaften Einstiegspunkte über
  `GuardedTick` abgesichert. Ohne OAP Debug bleibt die Fehlerausgabe aus.
- Das Design von `OptionsLogo.lua` aus 0.3.1 wird **unverändert** eingesetzt.
  Dadurch sind die seit 0.3.2 gewünschten zusätzlichen Overlays und die
  symmetrische Aufteilung vorübergehend zurückgenommen. Erst in WoW prüfen,
  bevor das Design erneut schrittweise ergänzt wird.
- Noch nicht abschließend im Spiel verifiziert: prüfen, ob die 64-px-Uhr beim
  Verschieben über ein *sichtbares LibDBIcon*-Symbol erneut gelb leuchtet;
  die kleine 32-px-Uhr wird in `UpdateCoverGlow` bewusst nicht geprüft.
- Bei weiterem Ausfall in OAP Debug > Errors/Log nach neuen Einträgen suchen.

## 0.3.3-alpha.1 – Repo-Build

- Build auf Grundlage von `0.3.2-alpha.1` mit Regression-Hotfix.
- Keine weiteren Änderungen an AceGUI oder dessen Tab-Geometrie; stabiles OptionsLogo von `0.3.1-alpha.1`.
- `/played`, AddonCompartment und Options-Styling sind gegen Laufzeitfehler abgeschirmt, damit Clock-/Health-Ticker weiterlaufen können.
- Die Minimap-Überdeckung wird direkt nach Drag-Ende erneut geprüft.
- Die gewünschte separate Text-Einblendung ist aus Stabilitätsgründen noch nicht wiederhergestellt; Ingame-Prüfung weiterhin erforderlich.

## Spielzeit / Shift-Tooltip – Arbeitsstand nach 0.3.3-alpha.1

- Der bisherige Sessionbeginn in `InitializePlaytime` setzte sich bei jedem `/reload` zurück.
  Jetzt überlebt der Login-Zeitstempel in den kontoübergreifenden `SavedVariables`;
  `PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)` unterscheidet bei unterstützten
  Clients den Reload vom echten Login. `PLAYER_LOGOUT` allein ist dafür nicht geeignet.
- Die letzte abgeschlossene Session bleibt pro GUID erhalten. Auf einem neuen Login wird
  die letzte Logout-Zeit bestätigt; ein Reload darf diesen Wert nicht ersetzen.
- /played-Daten werden nur serverseitig übernommen (`TIME_PLAYED_MSG`) und zwischen
  Samples anhand des aktuellen Login-/Samplezeitpunkts hochgerechnet; kein Doppeltzählen
  nach Reload und keine Offlinezeit in der Accountsummierung.
- Beim Öffnen mit Shift beziehungsweise beim Drücken/Loslassen von Shift während des
  Mouseovers wird der Tooltip direkt aktualisiert; fehlende /played-Werte fordern
  `RequestTimePlayed` höchstens einmal pro Minute an.
- Lua-Simulation für Login, Reload, echten Logout, Shift, Serverantwort und 2 Charaktere
  hinzugefügt; zusätzlich den echten Forever-Client mit `/reload` und `/played` prüfen.


## 0.3.4-alpha.1 – Repo-Build

- Shift-Mouseover fragt bei neuem Hover die Spielzeitdaten beim WoW-Server ab und zeigt bis zur Antwort einen Ladehinweis. Charakter- und Stufen-Spielzeit werden im Shift-Tooltip nur aus einer bestätigten `TIME_PLAYED_MSG`-Antwort angezeigt.
- Die laufende Login-Session übersteht `/reload`; die vorherige Login-bis-Logout-Session bleibt separat pro Charakter erhalten.
- Beim Logout werden bestätigte Serverwerte pro Charakter-GUID accountweit gesichert und separat gekennzeichnete Logout-Endstände für Offline-Charaktere berücksichtigt.
- Es wurden keine weiteren Änderungen am AceGUI-Tablayout vorgenommen; Optionen-Logo bleibt auf dem restaurierten Stand von 0.3.1.
- Versionsprozess: keine individuellen Git-Patches mehr erstellen. Änderungen im Repo vorbereiten; Repo-ZIP ausschließlich nach expliziter Freigabe.
- Ingame-Tests für den asynchronen `/played`-Antwortweg und Reload-vs.-Login-Verhalten stehen noch aus.


## 0.3.5-alpha.1 – Repo-Build: Spielzeitformat und Tooltip-Trennlinie

- Die drei Shift-Zeilen (Charakter gesamt, aktuelle Stufe, Account gesamt) zeigen
  bestätigte WoW-`/played`-Werte in ganzen, lokalisierten **Tagen, Stunden, Minuten**
  (deDE/enUS/frFR); angefangene Minuten werden abgerundet, Singular/Plural stimmt.
- Aktuelle und letzte Login-Session bleiben `hh:mm:ss` (Sekunden sichtbar),
  Timer ebenfalls unverändert. Die Datenhaltung und `/played`-Abfrage bleiben gleich.
- Änderungen sind im Arbeitsstand vorbereitet; TOC-Version bleibt bis zur
  ausdrücklichen Baufreigabe auf 0.3.5-alpha.1.

## 0.3.6-alpha.1 – Tooltip-Gestaltung und accountweite Charakterliste

- Uhrzeit im Mouseover als große, helle Zahl mit goldener Beschriftung; eigener Abschnitt „Spielsession“ mit aktueller/letzter Session (`hh:mm:ss`).
- Shift öffnet einen klar abgesetzten Bereich „Spielzeit aus WoW“. Nach Charakter/Level und Account gesamt werden alle gespeicherten Charaktere mit Klassenfarbe und serverseitig bestätigter Spielzeit in Tagen/Stunden/Minuten aufgelistet. Der native Divider mit 10 px Seitenabstand beendet diesen Datenbereich.
- `Core/Playtime.lua` speichert den WoW-Klassentoken (`UnitClass` zweiter Rückgabewert) pro GUID; bei alten Datensätzen ohne Klassenzuordnung neutral bis zum nächsten Login.
- Accountsumme und Einzelliste zeigen nur bestätigte `TIME_PLAYED_MSG`-Werte; die beim Logout separat gespeicherten Schätzwerte werden nicht als `/played`-Werte ausgegeben.
- Ingame prüfen: Schrift-/Tabellenbreite bei mehreren Charakteren und langen Realm-Namen sowie korrekte Aktualisierung nach Serverantwort.

### Leise WoW-Spielzeitabfrage für Shift-Tooltip (umgesetzt 0.3.6-alpha.1)
- `RequestTimePlayed()` erzeugt `TIME_PLAYED_MSG`, das registrierte Blizzard-Chatfenster eigenständig als zwei Systemzeilen anzeigen; `CHAT_MSG_SYSTEM`-Chatfilter greifen dabei nicht.
- Beim eigenen Request werden nur die vorher tatsächlich registrierten `TIME_PLAYED_MSG`-Listener der Chatfenster temporär ausgesetzt, nicht andere Events oder Nachrichten. `Clock` erhält die Antwort weiterhin und speichert echte Serverwerte.
- Auf Event-Antwort wird die Registrierung zeitversetzt nach dem Event-Dispatch wiederhergestellt; ebenfalls sofort bei Request-Fehler oder spätestens nach 20 Sekunden Timeout. Manuelles `/played` außerhalb dieser sehr kurzen Zeitspanne funktioniert unverändert.
- Einschränkung: Eine gleichzeitig mit unserer ausstehenden Anfrage durch ein anderes Addon oder den Spieler ausgelöste `/played`-Antwort teilt dasselbe Event und lässt sich nicht zuverlässig von unserer Antwort unterscheiden; dafür bietet das WoW-API keine Anfragekennung.

### Vorbereitete Ergänzung nach 0.3.5 – Serverstand vor Logout (umgesetzt 0.3.6-alpha.1)
- Die `/played`-Serverwerte werden während aktiver Sessions nach jeder Antwort frühestens nach 10 Minuten still erneut angefragt; die bekannten Charakterdaten werden bei `TIME_PLAYED_MSG` sofort gespeichert.
- `PLAYER_LOGOUT` sichert ausdrücklich einen Snapshot des **letzten bestätigten** Serverwerts (Gesamt + Stufe) mit Antwort- und Logout-Zeitstempel je Charakter-GUID. Lokale Logout-Schätzungen bleiben separat und fließen nicht in die als `/played` gekennzeichneten Tooltipwerte ein.
- Beim Logout kann nicht auf eine neue Serverantwort gewartet werden. Folglich ist der Snapshot maximal so aktuell wie der letzte bestätigte Request. `/reload` bleibt innerhalb derselben Session.
- Lua-Simulation deckt periodischen Abruf, Serverantwort, finalen Logout-Snapshot und Stufen-Spielzeit ab.

### Überarbeitung des Abfrageverhaltens (umgesetzt 0.3.6-alpha.1)
- Echte Login-bis-Logout-Sessions bleiben auch bei `/reload` erhalten.
- **30 Sekunden nach echtem Login** erste automatische stille `RequestTimePlayed()`-Abfrage,
  anschließend **alle 10 Minuten**; nächster Zeitpunkt in `record.nextAutoPlayedAt`
  gespeichert, damit ein `/reload` die Abfragezeit nicht zurücksetzt.
- Reines Uhr-Mouseover fordert keine Spielzeit mehr an. **Shift drücken** bei geöffnetem
  Uhr-Tooltip fordert einen neuen echten Serverwert; bei bereits gedrücktem Shift wird
  beim Mouseover ebenfalls angefragt. Ein noch offener Hintergrund-Request wird mitbenutzt.
- `TIME_PLAYED_MSG` wird grundsätzlich verarbeitet: auch manuelles `/played` im Chat
  aktualisiert die accountweite GUID-Speicherung, ohne den manuellen Befehl umzuleiten.
  Manuelles `/played` bleibt im Chat sichtbar; bei zeitgleichem stillem CPF-Request
  sind die Antworten technisch nicht unterscheidbar.
- Automatische und Shift-Anfragen unterdrücken ihre Blizzard-Chat-Ausgabe kurzzeitig
  und stellen die Chat-Eventregistrierungen nach Antwort, Fehler oder Timeout wieder her.
- Ingame verifizieren: 30-Sekunden-Start, wiederkehrende 10-Minuten-Anfrage,
  Shift loslassen/erneut drücken, normales Mouseover, manuelles `/played`, `/reload`.

## 0.3.7-alpha.1: Tooltip und Charakteridentität

- Timer direkt unter der Uhrzeit; Shift-Überschrift nur „Spielzeit“.
- Klasse und Fraktion werden beim Login GUID-basiert gespeichert; die Anzeige nutzt die Klassenfarbe und das eingebaute Allianz-/Horde-Symbol. Alte Datensätze werden beim nächsten Login des jeweiligen Charakters ergänzt.
- Für WoW Forever den vollständigen Namen über `GetUnitName("player")` bevorzugen, da `UnitName`/`UnitFullName` je nach Clientversion nur den Vornamen liefern. Vollständige gespeicherte Namen bleiben gegen kürzere Antworten geschützt.
- Kein Repo-Build ohne ausdrückliche Freigabe.

## 0.3.7-alpha.1: Wecker-Tastenkürzel

- **Strg + Linksklick** auf die Minimap-Uhr aktiviert bzw. deaktiviert die ausgewählten Wecker nacheinander; ersetzt **Shift + Linksklick**.
- Einfacher Linksklick (auch mit Shift gehalten) startet/stoppt weiterhin den vorausgewählten Timer. Shift bei Mouseover bleibt für `/played` zuständig.
- Tooltip, Blizzard-AddonCompartment, allgemeine Bedienungshilfe und Alarmeinstellungen in deDE/enUS/frFR entsprechend angepasst.
- Strg + Rechtsklick (Stoppuhr), Alt + Rechtsklick (Original-Uhr) und Rechtsklick (Optionen) bleiben unverändert.

## 0.3.7-alpha.1: Dynamischer Shift-Hinweis im Uhr-Tooltip

- Direkt unter aktueller/letzter Session erscheint eine blaue Informationszeile mit Blizzards
  kleinem `Interface\FriendsFrame\InformationIcon` (13 px), lokalisiert in deDE/enUS/frFR.
- Eine Leerzeile trennt sie vom Sessionblock; unter der Hinweiszeile folgt eine weitere
  Leerzeile vor den Bedienungshinweisen oder aktiven Alarmen.
- Beim Halten von Shift ersetzt die Überschrift **Spielzeit** exakt die Hinweiszeile.
  Die eigentlichen `/played`-Werte beginnen mit einer Leerzeile Abstand unter der Überschrift.
- Der bereits vorhandene `MODIFIER_STATE_CHANGED`-Handler baut den Tooltip beim Drücken und
  Loslassen neu auf. Keine zusätzliche WoW-Serveranfrage allein durch den Hinweis.
- Ingame testen: Shift gedrückt beim Mouseover, Shift während Mouseover drücken/loslassen,
  Timer/Wecker aktiv, mehrsprachige Tooltiptexte. Keine ZIP-Ausgabe ohne Freigabe.

## 0.3.8-alpha.1 (gebaut)

Health-Intervall basiert jetzt ausschließlich auf dem vorhandenen Session-Timer
mit absoluten Login-Grenzen statt `GetTime()` nach Modulstart. Keine zusätzlichen
Ticks. Für voneinander unabhängige Bildschirmrand-Effekte existieren künftig
`profile.effects.timer`, `.alarms` und `.health`; beim ersten Laden des Profils
werden bisherige Bildschirmrand-Einstellungen den Alarmeffekten zugewiesen.
Spätere Auflösung von Alarm-Effekten: individueller Alarm > Alarmkategorie >
Standard `effects.alarms` (heute nur Standard). WoW-Tooltip-Verdichtung
und blaues Icon implementiert. Ingame-Test ausstehend.

### 0.3.8-alpha.1 – Health-Sicherheitsmodus und Tooltip-Farben

- Health-Bewegungserinnerungen bleiben auch im Kampf und in Instanzen pünktlich: die
  konfigurierten Bildschirmmeldungen werden in diesen Situationen ausschließlich im
  Chat ausgegeben. Keine Bildschirmanzeigen, Bildschirmrand-Glows oder Sounds.
- Bereits laufende Health-Anzeigen werden beim Kampfbeginn bzw. Zonenwechsel
  ausgeblendet (WoW-Events ohne neuen Ticker); zusätzlich schützt der Core-Tick.
- Vorherige `health.deferInCombat`/`health.deferInInstances`-Profilwerte werden
  nur zur Kompatibilität ignoriert, die nicht mehr passenden Optionsschalter entfernt.
- Uhrzeit im Tooltip wieder in normal großer, weißer Schrift; die einzelnen
  Charakter-Spielzeiten übernehmen jetzt dieselbe Klassenfarbe wie ihre Namen.
- Noch kein neues Repository-ZIP; Änderungen erst im Spiel prüfen.

## 0.3.9-alpha.1 – Effekte per Farbwaehler/Dropdown/Slider

Die rohe Glow-Spec-Eingabe wurde in allen drei Modultabs durch AceConfig `color`,
`select` und `range` ersetzt (Sekunden 0,2–10, Prozent 0–100). Der echte
Blizzard-Farbpicker ist ueber AceGUI eingebunden, eine dynamische HEX-/Farbfeld-
Vorschau zeigt den eingestellten Wert. `ScreenGlow.lua` ist die zentrale
Serialisierungsschicht; kompatible alte Glow-Specs und deren Formzusaetze bleiben
erhalten. Modulgeschwindigkeiten duerfen sich nicht mehr gegenseitig ueberschreiben.
Erstellt nach ausdruecklicher Build-Freigabe. Live-Test im Spiel steht aus.

## Alarmdarstellung – Architektur

Die zentrale Routine `ns.EffectAppearanceArgs` in `Core/ScreenGlow.lua` baut gemeinsame AceConfig-Controls sowohl für Modul-Effekte als auch alarmbezogene Überschreibungen. `alarm.effect` speichert `spec` und `periodSeconds`, `alarm.customEffect` aktiviert die Überschreibung; `alarm.alarmType` hat Werte `alarm|event|reminder`. Altbestände werden einmalig als `alarm` migriert. Die Runtime übergibt das Alarmobjekt an `Clock:Alert`, sodass keine globalen Einstellungen temporär überschrieben werden. Die globale `screenGlow`-Freigabe sowie `skipInstances` stehen weiterhin über der Effekt-Überschreibung.

## 0.3.12-alpha.1 – Health-Untertabs und individuelles Erscheinungsbild (gebaut)

- Health: eigene Untertabs für Bewegung, Trinken, Augenpausen, Schlafenszeit
  sowie Allgemein. Pro Kategorie eine unabhängig speicherbare, optionale
  Überschreibung des globalen Health-Effektstils (`customEffect` / `effect`).
  Standardwerte werden beim ersten Aktivieren kopiert, beim Deaktivieren
  bleiben individuelle Werte erhalten; im Spiel wirkt derzeit nur Bewegung,
  weitere Kategorien haben noch keine aktive Reminder-Logik.
- Globaler Health-Effekt-Schalter und Instanz-/Kampfsperre bleiben maßgeblich.
  Die Anzeige des Formulars (AceConfig) wird erst nach dem Haken eingeblendet.
- Alarmformular: Typfeld nur ein Drittel breit; „Alle Tage“ links vor sieben
  Wochentagen; Tag, Monat und Jahr bilden eine Zeile, die Checkboxen
  „jeden Monat/jedes Jahr“ folgen darunter.
- Keine zusätzliche Timer-Schleife. Versionsnummer und Repository-ZIP
  wurden nach ausdrücklicher Baufreigabe erstellt.

## 0.3.13-alpha.1 – zentrierte Health-Nachrichten mit Kategorie-Icon (gebaut)

- Gemeinsame Anzeige von `Reminders.lua` nach `Modules/Health/Notice.lua` ausgelagert, via `Health.xml` vor den Erinnerungen geladen.
- Frame exakt `UIParent CENTER (0, 0)` statt `CENTER (0, -115)`. WoW-Icon (144×144 px, 35 % Alpha) liegt unter dem mittig zentrierten, schattierten Text (`ARTWORK` vs. `OVERLAY`), TexCoord-Schnitt blendet Inventar-Icon-Ränder aus.
- Vorläufige Icons pro Health-Kategorie: Bewegung `Ability_Rogue_Sprint`, Trinken `INV_Drink_07`, Augenpausen `Ability_EyeOfTheOwl`, Schlafenszeit `Spell_Nature_Sleep`. Auswechselbar in einer zentralen Zuordnung, ohne weitere Medien-Dateien.
- Kein zusätzlicher Timer/Ticker, keine Profiländerung; vorhandene 9-Sekunden-Anzeige und Chat-only-Beschränkung in Kampf/Instanzen bleiben unverändert.

## 0.3.14-alpha.1
Health: Trinken/Augenpausen aktiviert, Schlafenszeit aus Optionen entfernt, fraktionsabhängige Icon-TGAs und feste Kategorie-Standardfarben bzw. individuelle Effektfarben, Icon-Ein/Aus + Transparenz, schwarzer Textumriss. Kein zusätzlicher Ticker.

## Vorgemerkt fuer 0.3.15-alpha.1 – Health-Kollisionsregel (noch kein Build)

Health-Planung: Priorität **Trinken > Bewegung > Augenpause**. Ein niedrigerer Termin im ±5-Minuten-Bereich um den nächsthöheren aktiven Termin wird ausgelassen (einschließlich der Grenze), noch bevor Nachricht/Ton/Glow ausgegeben werden. Dafür wird der geplante Sessionzeitpunkt aller eingeschalteten Kategorien geprüft, auch wenn der höherwertige Termin erst bevorsteht. Gleichzeitige Nachhol-Fälligkeiten nach einem verzögerten Core-Tick werden gemeinsam ausgewertet. `suppressed` und `lastSuppressedAt` werden nur im RAM geführt und unterdrückte Kategorien erhalten einen `health.<category>.suppressed`-OAP-Zähler. Keine zusätzlichen Timer oder SavedVariables. Lua-Runtime-Grenztests decken 4/5/6 Minuten, gleichzeitige Fälligkeit, deaktivierte Kategorien und Combat-Chat ab.

## Vorbereitung 0.3.16-alpha.1 – Icon-Darstellung zentral/individuell

Globaler Icon-Schalter, Transparenz und vertikale Y-Position gehören unter Optionen → Effekte → Health → Darstellung. In den einzelnen Kategorien erscheinen sie zusammen mit den Effektreglern nur bei aktivierter „Eigene Effektdarstellung“. Gespeichert unter `effects.health.icon*` bzw. `health.<category>.effect.icon*`; alte `health.<category>.icon*`-Werte werden für individuelle Einstellungen übernommen.

## 0.3.17-alpha.1 – Health-Vorschau (gebaut)

- Globale Health-Testfunktion zeigt einen neutralen Health-Beispieltext und das fraktionsabhängige Blizzard-Wappen in der eingestellten Farbe, Icon-Transparenz und Position.
- Eigene Health-Darstellung testet den echten Kategorietext, das passende Health-Icon sowie individuelle Effektparameter ohne Chat oder Ton. Die Vorschau läuft neun Sekunden; Kampf/Instanz verhindert die Darstellung.
- Ingame-Test steht weiterhin aus.

## 0.3.18-alpha.1 – eigene Fraktionswappen für Health-Tests (gebaut)

- Die allgemeine Health-Effektvorschau verwendet die neuen transparenten Allianz-/Hordewappen
  aus `Media/Health/faction_alliance.tga` und `faction_horde.tga`, nicht mehr die Blizzard-PVP-Textur.
- `GetHealthNoticeIcon(nil)` wählt das passende Motiv über `UnitFactionGroup('player')`.
  Bewegung, Trinken und Augenpausen behalten ihre Kategorie-Icons und die bisherigen
  individuellen Effekte sowie Y-Position/Deckkraft.
- 256×256 RGBA-TGAs und PNG-Dateien sind im vollständigen Repository enthalten.

## 0.3.19-alpha.1 – feste Health-Kategoriefarben (gebaut)

- Der globale Farbpicker unter Optionen → Effekte → Health → Darstellung ist entfernt.
- Bewegung und Trinken verwenden weiterhin Allianz-/Horde-spezifische Farbwerte, Augenpause Weiß.
- Alte globale Health-Farben werden ignoriert. Bestehende individuelle Kategorie-Farben bleiben erhalten.
- Andere globale Gesundheits-Effekteinstellungen und die allgemeine neutrale Health-Testfarbe bleiben erhalten.

## 0.3.20-alpha.1 – Eigene Health-Texte und einheitliche Listen-Icons (gebaut)

- Unter Health → Bewegung/Trinken/Augenpausen koennen beliebig viele eigene Nachrichten gespeichert, einzeln aktiviert, bearbeitet und geloescht werden. Optional 50/50-Mischung mit Standardtexten.
- In Health, Alarme und Timer wurden die Bedienelemente auf gemeinsam wiederverwendete Blizzard-Icon-Texturen umgestellt: Gear (blauer Hover) und Loeschen (roter Hover), mit Graustufen-Einfaerbung und AceGUI-Recycling-Schutz.
- Auf Wunsch des Nutzers wurde das komplette Repo erst nach Freigabe als ZIP erstellt; Ingame-Test steht noch aus.

## 0.3.21-alpha.1 – Überarbeitete Health-Textverwaltung (gebaut)
- Pro Kategorie kompakte Zeilen mit Aktivierungs-Haken, Blizzard-Zahnrad, Papierkorb und Text wie in der Alarmübersicht. Trennüberschrift „Gespeicherte Texte“ trennt Anlegen von der Liste.
- Multiline-Eingabe besitzt keinen eingebauten AceGUI-Annehmen-Knopf. Eingaben bleiben reine Entwürfe und werden erst durch „Speichern“ übernommen; „Abbrechen“ verwirft sie.
- Die gespeicherten Texte und ihre Aktivierungszustände bleiben nach /reload erhalten.
