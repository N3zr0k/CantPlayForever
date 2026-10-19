# Health – Stand 0.5.0-latest.1

Das optionale Modul ist standardmäßig ausgeschaltet (Allgemein → Module → Health). Die drei Erinnerungskategorien **Bewegung**, **Trinken** und **Augenpausen** sind innerhalb des Moduls standardmäßig aktiviert.

| Kategorie | Standardintervall | Regler | Bildmotiv | Effektfarbe Allianz / Horde |
|---|---:|---|---|---|
| Bewegung | 45 Minuten | 5–180 (Schritt 5) | Stiefel mit Allianz- bzw. Horde-Symbol | `5FFF4F` / `F4A34C` |
| Trinken | 30 Minuten | 5–120 (Schritt 5) | Allianz- bzw. Horde-Krug | `3399FF` / `FF5844` |
| Augenpause | 20 Minuten | 5–60 (Schritt 5) | Wind-/Blätter-Auge für beide Fraktionen | `FFFFFF` / `FFFFFF` |

Schlafenszeit wurde aus den Optionen entfernt und löst keine Erinnerung aus.

## Darstellung

Unter **Optionen → Effekte → Health → Darstellung** gibt es **keinen globalen Farbwähler** mehr. Die drei Health-Kategorien verwenden immer ihre festgelegten, fraktionsabhängigen Standardfarben (Tabelle oben). Eine andere Farbe kann ausschließlich mit aktiviertem **Eigene Effektdarstellung** in der jeweiligen Kategorie gewählt werden. Frühere globale Farbwerte werden nicht mehr angewendet; bereits gespeicherte individuelle Farben bleiben erhalten. Die allgemeine Health-Testmeldung verwendet ein festes neutrales Grün (`5FFF4F`).

Unter **Optionen → Effekte → Health → Darstellung** befinden sich die **allgemeinen** Icon-Einstellungen: **Hintergrund-Icon anzeigen** (standardmäßig an), bei eingeschaltetem Icon **Transparenz** (0–100 %, Standard 65 %) und **Icon-Position (Y-Achse)** (−120 bis +120, Standard +65 px). Diese gelten für **alle drei Kategorien**, ohne dass der globale Bildschirmrand-Effekt aktiviert sein muss.

In den Health-Kategorie-Tabs erscheint ausschließlich der Schalter **Eigene Effektdarstellung**. Nur wenn er eingeschaltet ist, werden unter **Darstellung** die individuellen Optionen für Effektfarbe/Animation/Dauer/Deckkraft, **Icon ein/aus, Transparenz und Y-Position** eingeblendet. Diese Kategorie verwendet dann ihre gespeicherten Werte; ohne Haken gelten wieder die globalen Icon-Einstellungen. Früher unter den Kategorien gespeicherte Icon-Werte werden für eine aktivierte individuelle Darstellung berücksichtigt. Beim ersten Einschalten werden fehlende Einzelwerte aus der bisherigen Kategorie-Einstellung oder aus der globalen Einstellung übernommen. Beim Ausschalten bleiben die Einzelwerte für ein späteres Reaktivieren gespeichert.

Die transparenten Texturen liegen unter `CantPlayForever/Media/Health/*.tga` und werden automatisch anhand von `UnitFactionGroup('player')` ausgewählt.

Die Meldung steht exakt mittig über dem transparenten Icon. Der Text ist 24 px groß, benutzt eine schwarze `THICKOUTLINE`-Kontur sowie Schlagschatten und wird in der jeweiligen Health-Effektfarbe angezeigt. Pro Kategorie können Farbe, Pulse/Static/Blink, Zyklus und Deckkraft mit **Eigene Effektdarstellung** individuell gespeichert werden. Ohne aktivierte Einzelkonfiguration wird immer die jeweilige zum Icon passende Standardfarbe verwendet, unabhängig von älteren global gespeicherten Farbwerten. Individuelle Farben bleiben erhalten. Für den Rand-Effekt muss die globale Health-Effektaktivierung eingeschaltet sein.

## Standardtexte (ab 0.3.23-alpha.1)

Jede Erinnerung zeigt zufällig ein festes Titel/Text-Paar (DE/EN/FR):

- **Bewegung:** 10 Paare, z. B. „Bewegungs-Debuff!“.
- **Trinken:** 10 Paare, z. B. „Mana auffüllen!“.
- **Augenpause:** 6 Übungen (Fernblick, Blinzelpause, Warme Hände, Augen-Yoga, Augenmassage, Ernährung) mit je 2 Textvarianten. Der Titel ist der Übungsname mit Ausrufezeichen („Fernblick!“); Titel und Text gehören immer zur selben Übung.

Die Quelle der Standardtexte steht ganz unten im jeweiligen Health-Reiter (Bewegung: gesund.bund.de; Trinken: dge.de und bzfe.de; Augenpause: dak.de), nicht in der Meldung. Eigene Texte erhalten den allgemeinen Kategorietitel. Der frühere Schalter „Tonfall der Sprüche“ und die fraktionsabhängigen Bewegungssprüche entfallen.

## Timing und Sicherheitsregeln

Der vorhandene zentrale Sekundentakt berechnet fällige Erinnerungen auf Basis der beim Login gespeicherten Sessionzeit. `/reload` setzt diese nicht zurück. Bei Terminen, die höchstens fünf Minuten auseinanderliegen (**±5 Minuten einschließlich der Grenze**), zählt für **Bildschirmmeldung, Ton und Leuchtrand** nur die Erinnerung mit der höchsten Priorität: **1. Trinken, 2. Bewegung, 3. Augenpause**. Niedriger priorisierte Kategorien lösen weiterhin ihre Chatnachrichten aus, sofern Chat aktiviert ist, und ihre nächsten normalen Intervalle bleiben unverändert. Die Entscheidung berücksichtigt auch höher priorisierte Termine, die erst in bis zu fünf Minuten anstehen, und erfolgt ohne zusätzliche Ticker.

Beispiel: Trinken 20:00, Bewegung 20:04, Augenpause 20:06 → Bildschirm und Effekte zeigen nur Trinken (die Augenpause liegt außerdem innerhalb des Zeitfensters der Bewegung). Chatmeldungen für die jeweils fälligen Kategorien bleiben möglich.

Im Kampf und in Instanzen (auch Dungeon, Raid, Arena, Schlachtfeld) werden Health-Erinnerungen **nur im Chat** angezeigt, ohne Bildschirmanzeige, Leuchtrand oder Ton. Bereits aktive Anzeigen verschwinden beim Kampf- oder Instanzeintritt.

## Dateien

- `Modules/Health/{Messages,Notice,Reminders,Options,TextEditor}.lua`: Texte, Bildschirmdarstellung, Session-Timing, AceConfig-Untertabs sowie das mehrzeilige Eingabefeld ohne zusätzlichen Annehmen-Knopf.
- `Core/ScreenGlow.lua`: individuelle Farbwahl und fraktionsabhängige, zum Icon passende Fallbackfarben.
- `Media/Health/*.tga`: die Grafikdateien je Fraktion (Bewegung, Trinken, Augenpause); PNG-Quellen in `docs/images/health/`.
- `Modules/Health/Locales/{deDE,enUS,frFR}.lua`: vollständige Lokalisierung.

Der Ingame-Test unter WoW Forever steht noch aus.

## Testvorschau (ab 0.3.17-alpha.1)

**Optionen → Effekte → Health → Effekt jetzt testen** zeigt für neun Sekunden eine neutrale Health-Meldung mit den eigens gestalteten transparenten Allianz- oder Horde-Wappen, den globalen Icon-Einstellungen und dem globalen Health-Bildschirmrand-Effekt. **Health → Bewegung/Trinken/Augenpausen → Eigene Effektdarstellung → Effekt jetzt testen** zeigt dagegen den echten aktuellen Kategorie-Erinnerungstext, das kategorietypische fraktionsabhängige Icon und die individuellen Farb-/Effekt-/Icon-Werte. Tests erzeugen keine Chatmeldung, keinen Ton und ändern keine Fälligkeit. Kampf/Instanzen unterdrücken auch Vorschauen.

Die Wappen des allgemeinen Health-Tests sind fraktionsabhaengig unter `CantPlayForever/Media/Health/faction_alliance.tga` und `faction_horde.tga` abgelegt. Die Quell-PNGs liegen unter `docs/images/health/`. Die Kategorie-Icons fuer echte Pausen bleiben unveraendert.

## Eigene Erinnerungstexte (ab 0.3.20-alpha.1)

In **Health → Bewegung / Trinken / Augenpausen → Eigene Texte** lassen sich pro
Kategorie beliebig viele persönliche Nachrichtentexte speichern. Ein Hauptschalter
**Eigene Texte verwenden** aktiviert/deaktiviert die eigene Textquelle.
**Mit Standardtexten mischen** erlaubt eine gleichgewichtete (50/50) Auswahl
zwischen eigenen und eingebauten Sprüchen; ohne diese Option werden
nur die aktivierten eigenen Texte verwendet. Wenn keine gültigen, aktiven eigenen
Texte vorhanden sind, greift das Addon automatisch auf Standardtexte zurück.

Die Liste verwendet dieselben Zahnrad-/Papierkorb-Bilder wie die Alarme. Jeder
Text besitzt einen separaten Ein/Aus-Haken, ein Bearbeiten-Zahnrad und einen
Papierkorb mit Löschbestätigung. Hinzufügen und Bearbeiten haben Speichern- und
Abbrechen-Aktionen. Die Daten werden im bestehenden AceDB-Profil unter
`health.<category>.customMessages` persistiert. Es gibt keine Default-Liste,
damit gelöschte Texte nach `/reload` nicht wieder auftauchen. Die Auswahl gilt
für Bildschirmmeldung, Chat, die Vorschaufunktion und alle Tonfälle, ohne
Zeitplan oder Kollisionsprioritäten zu verändern.

#### Textverwaltung (UI)

Eigene Texte werden in jeder Health-Kategorie analog zur Alarmübersicht verwaltet: Zuerst der kompakte Knopf „Neuen Text hinzufügen“ (eigene Zeile) mit mehrzeiligem Eingabefeld und ausschließlich **Speichern / Abbrechen** (kein eingebauter Annehmen-Knopf). Unter der Trennüberschrift **Gespeicherte Texte** folgt je Text eine Zeile mit Aktivierungshaken, Zahnrad, Papierkorb und Text. Zwischen Einträgen liegt ein Trenner; das Zahnrad öffnet ein eigenes Bearbeitungsfeld mit Speichern/Abbrechen. Die mehrzeiligen Eingaben ändern nur Entwurfsdaten; gespeicherte Texte werden erst über Speichern verändert.
