# Boulder Plan – Redesign · Spec & Richtungskarten

## Spec (gemeinsame Grundlage aller drei Richtungen)

- **Was:** Redesign der bestehenden Web-App „Boulder Plan“ (PWA, iPhone, Home-Bildschirm). 12-Wochen-Bouldertrainingsplan 7a+ → 7b/7b+, Sessions A–E/T, Übungen abhaken (auch pro Satz), Check-in, Kalender, Plan, Fortschritt, Einstellungen.
- **Wer & wo:** ein Kletterer (Board-Training: Kilter, Moonboard, Hantel, Ringe, optional Halle). Benutzt die App **mitten im Training**: Kreide an den Fingern, Telefon liegt auf der Matte oder Bank, Pausen von 2–4 min zwischen Sätzen, oft schlechtes Hallenlicht.
- **Kernbotschaften:** (1) Was ist heute dran, wie weit bin ich? (2) Jeder Satz ist ein Tap. (3) Wo stehe ich in den 12 Wochen? (4) Wie fit bin ich heute (Check-in) – was folgt daraus?
- **Tonalität:** konzentriert, sportlich, ehrlich; kein Motivations-Kitsch.
- **Format (für alle drei gleich):** iPhone 15 Pro (393 × 852), Darstellung auf einer 1440 px breiten Präsentationstafel mit 3–4 bedienbaren Telefonen. **Dark Mode Pflicht.** Tap-Flächen ≥ 48 px, Fließtext ≥ 14 px, Labels ≥ 12 px.
- **Inhalt (echt, aus plan_seed.json):** Woche 5 · Maximalkraft · Montag, 24. November · Session A „Limit & Finger“: Warm-up-Routine 20 min · Max Hangs 20 mm 6 × 10 s, Pause 3 min, +15–20 kg, RPE 9 · Moonboard 40° Limit-Boulder 6 Probleme, 7a+–7b+ · Gewichtete Klimmzüge 5 × 3, +25–35 kg · Cool-down. Woche: Mo A, Di B, Do C, Sa D, sonst optional E. Check-in Schlaf 4 · Energie 3 · Finger 4.
- **Bilder:** Keine Fotos nötig. Der Inhalt ist ein Plan, keine Bildwelt; ein Kletterfoto wäre Dekoration (Ehrlichkeitstest). Hauptdarsteller sind Daten- und Programmgrafik.
- **Annahmen (nicht nachgefragt):** Dark Mode bleibt; Sprache Deutsch; keine Marke/Logo vorhanden; bestehende Funktionen bleiben, das Redesign ändert Form und Hierarchie.

## Sechs Kandidaten

### 1 · Bester Designer (mutig) · Wim Crouwel / Total Design → „Das Board“ ✅ gebaut als dir-1
- **Geliehen (Mechanismus):** Raster als einziges Ordnungsprinzip, Koordinaten statt Überschriften (Crouwels Rastersysteme, New-Alphabet-Denken).
- **Selbst gewachsen:** Ein Kilter-/Moonboard *ist* ein Raster aus Löchern mit LED-Ringen (Spalten A–K, Reihen 1–18). Der 12-Wochen-Plan wird zu einem Board: 12 Reihen = Wochen, 7 Spalten = Tage, jede Session ein beleuchteter Griff. Farben sind die LED-Farben (Magenta, Cyan, Grün, Orange) auf mattem Schwarz mit T-Nut-Lochraster.
- **Hauptdarsteller:** programmatisches Board-Raster mit leuchtenden Griff-Ringen.
- **Skelett:** Plan = Board; Heute = Liste, deren Checkboxen LED-Ringe sind, Sätze = Griffe einer Reihe.
- **Mut:** Der Plan-Tab ist kein Kalender, sondern ein „Problem“, das man 12 Reihen hochklettert.
- **Form aus dem Inhalt:** Das Trainingsgerät selbst (das Board) ist die Oberfläche.

### 2 · Bester Designer (still) · Kenya Hara → „Kreide“ ✅ gebaut als dir-2 (kombiniert mit Kandidat 3)
- **Geliehen:** Leere als Material, das Material selbst ist der Held (Hara: „Weiß“, Muji-Haltung).
- **Selbst gewachsen:** Das Material des Kletterns ist Magnesia. Sätze werden als **Kreide-Striche** gezählt (wie Kletterer Versuche an die Wand strichen: |||| mit Querstrich). Graphit-Grund, kreideweiße Linien, eine einzige warme Akzentfarbe für „heute / du bist hier“.
- **Hauptdarsteller:** handgezogene Strichlisten und eine Kreidekurve.
- **Mut:** Fast keine Rahmen und Karten, nur Linien auf dunklem Grund.

### 3 · Realer Bezug · Structured (App Store Awards Finalist, id 1499198946) → in dir-2 eingeflossen
- **Referenztafel:** `refs/appstore/Structured-Daily-Planner-Todo.jpg` (selbst angesehen).
- **Geliehen (ein Mechanismus):** Ein Tag ist eine senkrechte Achse; jede Aufgabe ist eine Kapsel auf der Achse, deren **Länge der Dauer entspricht**.
- **Nicht geliehen:** Rosa Grund, runde Pastell-Icons, Icon-in-Kapsel, Wochenleiste mit Farbpunkten.
- **Selbst gewachsen:** Die Session A dauert ~2 h: Warm-up 20, Max Hangs 25, Limit 60, Klimmzüge 18, Cool-down 8 min → die Achse zeigt, wo die Zeit hingeht (das Limit-Bouldern ist der lange Block). Ein Bezug zu Kreide statt zu Pastell.

### 4 · Realer Bezug · Bevel (App Store Awards Finalist 2026, id 6456176249) → in dir-2 und dir-3
- **Referenztafel:** `refs/appstore/Bevel-AI-Health-Coach.jpg` (selbst angesehen).
- **Geliehen (Mechanismus):** (a) Erst das Urteil in Klartext („Time to take it easy“), dann die Zahl. (b) Jede Kategorie besitzt eine Farbe, und **beim Eintreten färbt sich der ganze Bildschirm** in diese Farbe.
- **Nicht geliehen:** Himmel-/Wolkenhintergründe, weiße Karten mit Schatten, runde Prozent-Ringe, Pastell.
- **Selbst gewachsen:** Check-in-Urteil wird ein Kletter-Satz („Heute ziehen.“ / „Heute schonen.“); die vier Session-Farben färben jeweils den ganzen Fokus-Bildschirm.

### 5 · Sekunden-Roulette (App Nr. 2, S = 25) · Liquid Glass → nicht gebaut (Alternative)
- Schwebende Glasflächen über Inhalt. Hier gibt es kein Bild-Inhalt, über dem Glas schweben könnte; Glas über Verläufen wäre Dekoration. Als Alternative angeboten: Glas-Werkzeugleiste über dem Board aus Richtung 1.

### 6 · Sekunden-Roulette (Ost Nr. 2) · Song-Holzdruck-Satzspiegel → nicht gebaut (Alternative)
- Senkrechte Spalten mit Linienrahmen wie eine Druckseite der Song-Zeit; die 12 Wochen als 12 senkrechte Spalten mit Randnotizen. Gefahr „zu viel Requisite“ für eine Sport-App; als Alternative angeboten.

## Ausgewählt (drei Vollentwürfe)

| | Richtung | Quellen | Hauptbildschirm-Form | Signatur | Farbe beantwortet | Stimme |
|---|---|---|---|---|---|---|
| dir-1 | **Das Board** | Crouwel (+ Kilter/Moon-Board als Inhalt) | Raster 12 × 7 | LED-Griff-Ring als Checkbox | Welcher Session-Typ | Koordinaten, Mono, knapp („W5 · A“) |
| dir-2 | **Kreide** | Hara + Structured + Bevel (a) | Senkrechte Zeitachse mit Kapseln | Kreide-Strichliste pro Satz | Nur „heute / du bist hier“ | ruhig, Satz in Klartext |
| dir-3 | **Fokus** | Bevel (b) + Paradigma 08 (Bedienbarkeit) | Eine Übung pro Bildschirm | Daumen-großer Satz-Knopf mit Pausenring | Welche Session (ganzer Bildschirm) | laut, groß, Imperativ |
