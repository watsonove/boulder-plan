# 🧗 Boulder Plan

Ein 12-wöchiger, periodisierter Bouldertrainingsplan als Web-App fürs iPhone – von **7a+ Richtung 7b/7b+**.
Der Plan erscheint als Kalender, an jedem Trainingstag hakst du die Übungen per Checkbox ab.

**➡️ App öffnen: https://watsonove.github.io/boulder-plan/**

- Funktioniert offline und lässt sich wie eine App auf dem Home-Bildschirm installieren
- Kein Login, kein Server: alle Trainingsdaten bleiben **nur auf deinem Gerät**
- Ohne Frameworks und externe Abhängigkeiten, nur HTML, CSS und JavaScript

---

## Installation auf dem iPhone

1. **https://watsonove.github.io/boulder-plan/** in **Safari** öffnen.
2. **Teilen-Symbol** (Quadrat mit Pfeil) → **„Zum Home-Bildschirm“** → **Hinzufügen**.
3. Die App ab jetzt **immer über das Symbol** öffnen und dort den Plan einrichten.

> Safari und die installierte App haben getrennte Speicher. Richte den Plan deshalb erst in der installierten App ein.

Auf Android funktioniert es genauso: in Chrome öffnen → Menü → **„App installieren“** bzw. **„Zum Startbildschirm hinzufügen“**.

---

## Der Plan

| Woche | Phase | Schwerpunkt |
|---|---|---|
| 1–3 | **Basis** | Volumen, Technik, Kraftausdauer, Hypertrophie 3×8–10 · Benchmarks in Woche 1 |
| 4 | **Deload** | ca. 40 % weniger Volumen, keine Limit-Versuche |
| 5–7 | **Maximalkraft** | Limit-Boulder, Max Hangs, schwere Klimmzüge 5×3 |
| 8 | **Deload** | regenerieren |
| 9–11 | **Power & Power-Ausdauer** | explosive Board-Boulder, Campus mit Füßen, Linked Boulders, 30/30-Circuits |
| 12 | **Taper & Test** | frisch werden, Benchmarks aus Woche 1 wiederholen |

### Session-Typen

| | Session | Inhalt |
|---|---|---|
| 🟥 **A** | Limit & Finger | Warm-up, Max Hangs 20 mm, Moonboard-Limit-Boulder, gewichtete Klimmzüge |
| 🟦 **B** | Kraft & Antagonisten | gewichtete Klimmzüge, Lock-off-Negatives, Dips, Bankdrücken, Ringe, Front Lever |
| 🟧 **C** | Kilter Power | kurze explosive Boulder 40–45°, in der Power-Phase Moonboard-Campus mit Füßen |
| 🟪 **D** | Kraftausdauer & Volumen | 4×4, Linked Boulders, 30/30-Circuits |
| 🟩 **E** | Mobility & Regeneration | optional, 20 min an freien Tagen |
| 🟨 **T** | Technik & Volumen | Zusatztag bei 5 Trainingstagen |

**Wochenaufteilung:** 3 Tage = A, B, C/D im Wechsel · 4 Tage = A, B, C, D (Standard: Mo, Di, Do, Sa) · 5 Tage = zusätzlich T.

**Equipment:** Kilterboard, Moonboard, Klimmzugstange, Gewichte, Hantelbank, Dip-Barren, Ringe.
- **Ohne Hangboard** werden Max Hangs automatisch durch Moonboard-Halteübungen ersetzt.
- **Mit kommerzieller Boulderhalle** wandern 4×4, Circuits und der Technik-Tag teilweise in die Halle. Nach Session B gibt es dann optional einen Block „Freies Bouldern“. Die Finger-Sessions A und C bleiben am Board.

**Benchmarks (Woche 1 vs. 12):** Max Hang 20 mm (bzw. Board-Halteübung), 3RM gewichtete Klimmzüge, höchster Moonboard-Grad, höchster Kilter-Grad.

---

## Funktionen

**Heute**
- Die heutige Session als Checkbox-Liste mit großen Tap-Flächen (auch mit Kreide an den Fingern bedienbar)
- Sätze einzeln abhakbar, Fortschrittsbalken, eine Session ist erledigt, wenn alle Kernübungen ★ abgehakt sind
- **Check-in** (Schlaf, Energie, Fingergefühl je 1–5): Bei niedrigen Werten wird die **leichte Variante** empfohlen (−1 Satz, keine Limit-Versuche)
- **„Wenig Zeit“**: nur Kernübungen in Kurzform (≈ 45 min)
- Verpasste Sessions **nachholen** (nächste freie Lücke) oder **überspringen**

**Kalender**
- Monatsansicht mit Fortschrittsringen in der Farbe des Session-Typs (offen, teilweise, erledigt, übersprungen)
- Wochenansicht mit **Drag & Drop**: Session gedrückt halten und auf einen anderen Tag ziehen
- Warnung, wenn fingerintensive Sessions (A, C) weniger als 48 h auseinanderliegen

**Plan**
- 12-Wochen-Übersicht nach Phasen, aktuelle Woche hervorgehoben
- Ganze Wochen überspringen (Krankheit, Urlaub)

**Fortschritt**
- Serie, Rekord, Abschlussquote gesamt und pro Woche
- Benchmarks Woche 1 und 12 im Vergleich

**Einstellungen**
- Startdatum, 3/4/5 Trainingstage, Wochentage, Hangboard, Halle, Mobility an freien Tagen
- **Plan pausieren**: alle offenen Sessions um X Tage verschieben
- **Erinnerungen über die Kalender-App** (.ics-Datei mit allen Trainingstagen)
- **Backup** als JSON exportieren und importieren
- Dunkles Design oder wie System

**Übungen anpassen:** Jede Übung lässt sich bearbeiten (Sätze, Wiederholungen, Pause, Intensität, Gewicht, Notiz) oder gegen eine Alternative tauschen (z. B. Kilter ↔ Moonboard). Eigene Übungen kannst du hinzufügen.

---

## Daten & Datenschutz

- Alles wird im lokalen Speicher des Browsers auf deinem Gerät abgelegt. Es gibt keinen Server, kein Tracking und kein Konto.
- Die Daten hängen an der Web-Adresse und an der installierten App. **Exportiere regelmäßig ein Backup** (Einstellungen → Fortschritt exportieren), z. B. in „Dateien“ oder iCloud Drive.
- Löschst du die App vom Home-Bildschirm, sind auch die Daten weg. Mit dem Backup lassen sie sich wiederherstellen.

---

## Den Plan anpassen

Der komplette Trainingsplan steht in **[`plan_seed.json`](plan_seed.json)**. Für Änderungen musst du keinen Code anfassen.

| Bereich | Bedeutung |
|---|---|
| `phases` | Phasen mit Name, Farbe, Beschreibung |
| `weeks` | Woche 1–12 → Phase + Wochenfokus |
| `sessionTypes` | Titel je Session-Typ |
| `weekLayouts` | Aufteilung bei 3/4/5 Tagen (`["C","D"]` = wochenweise im Wechsel) |
| `exercises` | Übungsbibliothek mit Beschreibung und Austauschübungen |
| `sessions` | Übungen je Session-Typ mit Sätzen, Wiederholungen, Pause (`rest` in Sekunden), Intensität, Dauer |

Felder pro Übung in `sessions`:

| Feld | Wirkung |
|---|---|
| `core: true` | Kernübung: zählt für „erledigt“ und erscheint bei „Wenig Zeit“ |
| `limit: true` | wird in der leichten Variante ausgeblendet |
| `phases: { "max": { … } }` | Abweichung je Phase (auch `"exercise"` zum Ersetzen) |
| `onlyPhases` / `exceptPhases` / `onlyWeeks` / `exceptWeeks` | wann die Übung vorkommt |
| `noHangboard: { … }` | Ersatz ohne Hangboard |
| `onlyIf: "gym"`, `gym: { … }`, `gymPhases: { … }` | Varianten mit Boulderhalle |
| `quick: { "sets": 3, "minutes": 25 }` | Kurzform für „Wenig Zeit“ |
| `benchmark: "maxHang"` usw. | zeigt den Button „Ergebnis eintragen“ |

**So spielst du Änderungen ein:**
1. Die geänderte Datei ins Repo hochladen.
2. Die App zweimal öffnen. Updates werden im Hintergrund geladen und greifen beim nächsten Start.
3. Auf bestehende Sessions wirken neue Inhalte erst nach **Einstellungen → Plan komplett neu erstellen**. Vorher ein Backup exportieren.

---

## Projektstruktur

```
index.html            App-Gerüst
manifest.webmanifest  Name, Icons, Vollbild-Modus
sw.js                 Service Worker (offline, Updates)
plan_seed.json        der komplette Trainingsplan
css/styles.css        Design (Dark Mode, große Tap-Flächen)
js/main.js            Start, Aktionen, Drag & Drop, Export/Import
js/views.js           Rendering aller Ansichten und Dialoge
js/plan.js            Plan-Generator, Status, 48-h-Regel, Statistik
js/store.js           lokale Speicherung
js/dates.js           Datums-Helfer
js/ui.js              UI-Zustand
icons/                App-Icons
```

## Lokal starten

```bash
python -m http.server 8765
```
Dann im Browser `http://localhost:8765` öffnen. In den Entwicklertools lässt sich die Handy-Ansicht aktivieren.

---

*Hinweis: Der Plan ist ein allgemeiner Trainingsvorschlag und ersetzt keine individuelle Beratung. Bei Schmerzen in Fingern, Ellbogen oder Schultern pausieren und ggf. ärztlich abklären lassen.*
