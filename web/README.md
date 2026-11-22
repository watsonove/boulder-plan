# 🧗 Boulder Plan

Ein 12-wöchiger, periodisierter Bouldertrainingsplan als Web-App fürs iPhone – **abgestimmt auf dein Niveau**, vom Einsteiger (bis Fb 5a) bis zur Leistungsstufe (ab 7b+).
Der Plan erscheint als Kalender, an jedem Trainingstag hakst du die Übungen per Checkbox ab. Pausen und Hang-Intervalle laufen mit eingebautem Timer.

**➡️ App öffnen: https://watsonove.github.io/boulder-plan/web/**

- Funktioniert offline und lässt sich wie eine App auf dem Home-Bildschirm installieren
- Kein Login, kein Server: alle Trainingsdaten bleiben **nur auf deinem Gerät**
- Ohne Frameworks und externe Abhängigkeiten, nur HTML, CSS und JavaScript

---

## Installation auf dem iPhone

1. **https://watsonove.github.io/boulder-plan/web/** in **Safari** öffnen.
2. **Teilen-Symbol** (Quadrat mit Pfeil) → **„Zum Home-Bildschirm“** → **Hinzufügen**.
3. Die App ab jetzt **immer über das Symbol** öffnen und dort den Plan einrichten.

> Safari und die installierte App haben getrennte Speicher. Richte den Plan deshalb erst in der installierten App ein.

Auf Android funktioniert es genauso: in Chrome öffnen → Menü → **„App installieren“** bzw. **„Zum Startbildschirm hinzufügen“**.

---

## Niveau

Beim Erstellen des Plans wählst du den Grad, den du **aktuell sicher** boulderst (nicht dein Maximum) – in Fb oder V, die App rechnet um. Dazu kommen Klettererfahrung, „unter 18“ und „Fingerverletzung in den letzten 6 Monaten“.

| Stufe | Fb | V | Was der Plan enthält |
|---|---|---|---|
| Einsteiger | bis 5a | VB–V1 | Technik, Volumen, Projektieren, Grundkraft. Kein Hangboard, kein Campus. |
| Aufbau | 5b–6a | V2–V3 | Technik, Projektieren, 4×4 und Circuits leicht; ab 1 Jahr Erfahrung Hängen mit Fußentlastung |
| Mittel | 6a+–6c | V4–V5 | Repeaters und Max Hangs mit Körpergewicht, Board-Limit, Power, Kraftausdauer |
| Fortgeschritten | 6c+–7b | V6–V8 | Max Hangs mit Zusatzgewicht, Campus mit Füßen, einarmige Negatives |
| Leistung | ab 7b+ | ab V9 | wie Fortgeschritten, mehr Sätze, 7-53-Hangs |

- **Erfahrung:** Hangboard erst ab 1 Jahr; Zusatzgewicht am Hangboard, Campus und einarmige Negatives erst ab 2 Jahren. Fehlt die Erfahrung, nimmt die App die Variante der Stufe darunter.
- **Unter 18:** kein Campus, kein Zusatzgewicht am Hangboard (Wachstumsfugen).
- **Fingerverletzung:** alle Finger-Übungen eine Stufe leichter.
- Einsteiger und Aufbau trainieren höchstens 4 Tage pro Woche.
- Grade in den Vorgaben (Limit, 4×4, Deload …) werden aus deinem Grad berechnet.
- Pläne aus der Zeit vor der Niveau-Auswahl gelten automatisch als „Fortgeschritten · 7a+ · 2–4 Jahre“.

Die Recherche dahinter (Quellen, Widersprüche, Entscheidungen) steht in [`docs/training-research.md`](../docs/training-research.md).

## Der Plan

| Woche | Phase | Schwerpunkt |
|---|---|---|
Alle Stufen nutzen dasselbe Raster; Inhalte und Phasennamen hängen vom Niveau ab (Einsteiger/Aufbau in Klammern).

| Woche | Phase | Schwerpunkt |
|---|---|---|
| 1–3 | **Basis** (Technik & Volumen) | Volumen, Technik, Repeaters, Hypertrophie 3×8–10 · Benchmarks in Woche 1 |
| 4 | **Deload** | ca. 40 % weniger Volumen, keine Limit-Versuche |
| 5–7 | **Maximalkraft** (Projektieren & Grundkraft) | Limit-Boulder, Max Hangs, schwere Klimmzüge |
| 8 | **Deload** | regenerieren |
| 9–11 | **Power & Power-Ausdauer** (Dynamik & Ausdauer) | explosive Board-Boulder, Campus mit Füßen (ab Fortgeschritten), Linked Boulders, 30/30-Circuits |
| 12 | **Taper & Test** | frisch werden, Benchmarks aus Woche 1 wiederholen |

### Session-Typen

| | Session (ab Mittel) | Einsteiger/Aufbau |
|---|---|---|
| 🟥 **A** | Limit & Finger: Hangboard, Moonboard-Limit, Klimmzüge | Projektieren & Technik |
| 🟦 **B** | Kraft & Antagonisten: Klimmzüge, Lock-offs/Negatives, Dips, Bankdrücken, Ringe, Front Lever | Grundkraft & Antagonisten mit Körpergewicht |
| 🟧 **C** | Kilter Power: kurze explosive Boulder, ab Fortgeschritten Campus mit Füßen | Technik & Volumen |
| 🟪 **D** | Kraftausdauer & Volumen: 4×4, Linked Boulders, 30/30-Circuits | Ausdauer & Spiel (leichte Boulder-Runden) |
| 🟩 **E** | Mobility & Regeneration: optional, 20 min an freien Tagen | gleich |
| 🟨 **T** | Technik & Volumen: Zusatztag bei 5 Trainingstagen (ab Mittel) | – |

**Wochenaufteilung:** 3 Tage = A, B, C/D im Wechsel · 4 Tage = A, B, C, D (Standard: Mo, Di, Do, Sa) · 5 Tage = zusätzlich T.

**Equipment:** Kilterboard, Moonboard, Klimmzugstange, Gewichte, Hantelbank, Dip-Barren, Ringe.
- **Ohne Hangboard** werden Max Hangs automatisch durch Moonboard-Halteübungen ersetzt.
- **Mit kommerzieller Boulderhalle** wandern 4×4, Circuits und der Technik-Tag teilweise in die Halle. Nach Session B gibt es dann optional einen Block „Freies Bouldern“. Die Finger-Sessions A und C bleiben am Board.

**Benchmarks (Woche 1 vs. 12):** Grad-Pyramide; ab Mittel zusätzlich Max Hang 20 mm (bzw. Board-Halteübung), 3RM gewichtete Klimmzüge und höchster Moonboard-Grad; Einsteiger und Aufbau testen maximale Klimmzüge.

---

## Funktionen

**Design „Fokus“:** Jede Session besitzt eine Farbe (A Rot, B Blau, C Orange, D Violett, E Mint, T Gelb), die beim Öffnen den ganzen Bildschirm färbt. Große Schrift (Archivo Expanded), große Tap-Ziele – bedienbar mit Kreide an den Fingern.

**Fokus-Modus**
- Eine Übung pro Bildschirm: Name, Vorgabe, Sicherheitshinweise, Zusatzgewicht mit ±2,5-kg-Tasten
- **Satzpause:** daumengroßer Knopf „Satz fertig“ → Countdown der Pause mit Satzzähler („Als Nächstes: Satz 2/4“)
- **Intervall** (Repeaters 7/3, Max Hangs, 7-53, 30/30-Circuits): „Start“ → Arbeit und Pause wechseln automatisch. Arbeit = ganzer Bildschirm in Session-Farbe („Hängen“), Pause = dunkel. Nach dem letzten Durchgang wird der Satz abgehakt und die Satzpause startet.
- Pause/Weiter, Überspringen, ±15 s; riesige Ziffern, die man auch an der Wand liest
- Ton und (wo möglich) Vibration bei jedem Wechsel, kurze Töne 3, 2, 1 s vor Ende
- Der Bildschirm bleibt an, solange ein Timer läuft (Wake Lock). Der Timer rechnet mit Zeitstempeln und stimmt auch, wenn die App kurz im Hintergrund war.
- Fortschrittsbalken oben, „Danach“-Knopf zur nächsten Übung

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
- Niveau (Grad in Fb oder V, Erfahrung, unter 18, Fingerverletzung) – Änderungen erstellen die zukünftigen Sessions neu
- Startdatum, 3/4/5 Trainingstage, Wochentage, Hangboard, Halle, Mobility an freien Tagen
- **Plan pausieren**: alle offenen Sessions um X Tage verschieben
- **Erinnerungen über die Kalender-App** (.ics-Datei mit allen Trainingstagen)
- **Backup** als JSON exportieren und importieren

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
| `phases` | Phasen mit Name, Farbe, Beschreibung; `byLevel` für Namen je Stufe |
| `weeks` | Woche 1–12 → Phase + Wochenfokus; `focusByLevel` je Stufe |
| `sessionTypes` | Titel je Session-Typ; `byLevel` je Stufe |
| `weekLayouts` | Aufteilung bei 3/4/5 Tagen (`["C","D"]` = wochenweise im Wechsel), `minLevel` für 5 Tage |
| `exercises` | **Übungsdatenbank:** Beschreibung, Austauschübungen, `minLevel`, `minYears`, `fingerIntense`, `noYouth`, `warnings`, `timer` |
| `sessions` | Übungen je Session-Typ mit Sätzen, Wiederholungen, Pause (`rest` in Sekunden), Intensität, Dauer und `parametersByLevel` |

Felder in `exercises`:

| Feld | Wirkung |
|---|---|
| `minLevel` / `maxLevel` | Stufen 1–5, in denen die Übung eingeplant werden darf |
| `minYears` | Mindest-Klettererfahrung in Jahren |
| `fingerIntense: true` | bei „Fingerverletzung“ eine Stufe leichter |
| `noYouth: true` | nicht für unter 18 |
| `warnings: [ … ]` | Sicherheitshinweise in Liste und Fokus-Modus |
| `timer: { "type": "interval", "work": 7, "rest": 3, "reps": 6 }` | Intervall-Timer; ohne Angabe gibt es eine Satzpause, wenn die Übung eine Pause hat |

Felder pro Eintrag in `sessions`:

| Feld | Wirkung |
|---|---|
| `parametersByLevel: { "1": { … }, "3": { … } }` | Werte ab dieser Stufe; höhere Stufen erben von niedrigeren, außer sie setzen eine neue Übung (`exercise`) |
| `minLevel` / `maxLevel` | Eintrag nur in diesen Stufen |
| `core: true` | Kernübung: zählt für „erledigt“ und erscheint bei „Wenig Zeit“ |
| `limit: true` | wird in der leichten Variante ausgeblendet |
| `phases: { "max": { … } }` | Abweichung je Phase (auch `"exercise"` zum Ersetzen, `"skip": true` zum Weglassen) |
| `onlyPhases` / `exceptPhases` / `onlyWeeks` / `exceptWeeks` | wann die Übung vorkommt |
| `noHangboard: { … }` | Ersatz ohne Hangboard |
| `onlyIf: "gym"`, `gym: { … }`, `gymPhases: { … }` | Varianten mit Boulderhalle |
| `quick: { "sets": 3, "minutes": 25 }` | Kurzform für „Wenig Zeit“ |
| `benchmark: "maxHang"` usw. | zeigt den Button „Ergebnis eintragen“ |

In Texten steht `{G}` für deinen Grad, `{G+1}` / `{G-2}` für Grade darüber bzw. darunter.

Ist eine Übung für ein Profil nicht erlaubt (Stufe, Erfahrung, unter 18, Verletzung), nimmt die App die Werte der nächstniedrigeren Stufe desselben Eintrags; passt keine, entfällt der Eintrag.

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
css/styles.css        Design „Fokus“ (Session-Farben, große Tap-Flächen)
fonts/                Archivo + Inter (lokal, offline, OFL-Lizenz)
js/main.js            Start, Aktionen, Drag & Drop, Export/Import
js/views.js           Rendering aller Ansichten und Dialoge
js/plan.js            Plan-Generator nach Niveau, Status, 48-h-Regel, Statistik
js/levels.js          Grad-Skalen Fb/V, Stufen, Freigaben, Migration
js/timer.js           Rechenlogik für Satzpause und Intervall-Timer
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

## Tests

Im Projektordner (eine Ebene über `web/`), ohne Installation – nur Node.js 22 oder neuer:

```bash
npm test
```

Geprüft werden Grad-Umrechnung, Stufen, Migration, die Plan-Generierung für alle Stufen (mit/ohne Hangboard und Halle, Erfahrung, unter 18, Verletzung) und die Timer-Logik (Phasen, Hintergrund, Pause, ±15 s).

---

*Hinweis: Der Plan ist ein allgemeiner Trainingsvorschlag und ersetzt keine individuelle Beratung. Bei Schmerzen in Fingern, Ellbogen oder Schultern pausieren und ggf. ärztlich abklären lassen.*
