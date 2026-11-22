# Polish-Log · Boulder Plan Redesign

Hinweis: `polish.py` und `design_lint.py check/compare` wurden übersprungen, weil Python-Playwright nicht installiert ist
(`pip install playwright && playwright install chromium`). Stattdessen Sichtprüfung im eingebauten Browser bei 1440 px,
mit 1,75-fachem Zoom auf die Telefone.

## Runde 1 · Richtungsentwürfe (2026-11-22)

### dir-1 · Das Board
1. Check-in: Die Griffe 1–2 leuchteten orange, 3–5 grün, gemischt in einer Reihe → jetzt eine Farbe je Wert (≤ 2 orange, sonst grün).
2. Board: Die Phasennamen waren abgeschnitten („Maxim“, „Delo“) → Kurzformen (Basis, Ruhe, Max, Power, Test) mit Trennstrich, breitere Spalte.
3. Heute: „6 × 6 Probleme“ war doppelt → bei Zähl-Übungen kein „n ×“-Präfix. Scrollbalken in den Telefonen ausgeblendet.

### dir-2 · Kreide
1. Die Strichliste (Signatur) war zu klein und zu körnig, offene Striche gestrichelt und unruhig → 40 px hoch, 4,5 px Strich, offene Striche ruhig und blass.
2. Die Kreidetextur fraß die Füllungen → Körnungsmaske abgeschwächt.
3. Tafel hatte unten 200 px Leere, im Telefon war ein Scrollbalken zu sehen → Höhe 1250, Scrollbalken aus.

### dir-3 · Fokus
1. Im Pausenring lief „Pause · tippen = weiter“ bei 180 px über den Kreis → zweizeilig, kleiner bei kleinen Ringen.
2. Beim großen „A“ im Hintergrund der Heute-Ansicht geprüft: Es überdeckt den Titel nicht (Titel max. 230 px breit).
3. Die Wochen-Ansicht ist absichtlich angeschnitten (zeigt nur die oberen Farbbänder); so lassen.

## Umsetzung Richtung „Fokus“ in web/ (2026-11-22)

### Runde 1
1. Großes Session-„A“ im Kopf überdeckte den Titel → Buchstabe 168 px, Titel und Meta-Zeilen mit fester Breitengrenze (100 % − 160 px).
2. Lange Übungsnamen im Fokus-Modus („Moonboard-Halteübung kleine Leisten“) nahmen 4 Zeilen ein und schoben die Navigation aus dem Bild → Schriftgröße nach Länge (44 / 36 / 30 px).
3. Scrollbalken unter den Satz-Knöpfen sichtbar → ausgeblendet.

### Runde 2
1. KW-Titel in der Wochenansicht brach auf zwei Zeilen um → kleiner, kein Umbruch.
2. Emoji-Icons (Kacheln, Hinweise, Leer-Zustände, Toasts) entfernt; Leer-Zustände als großes Wort („Ruhetag.“, „Bald.“).
3. Kompletter Durchlauf geprüft: Check-in → leichte Variante → Fokus alle Übungen → Session erledigt, keine JS-Fehler.

Offen/nicht geprüft: echtes iPhone (Safari-Rendering der variablen Schriftbreite, Haptik), Lint-Skripte (Python-Playwright fehlt).

## Wiedererkennungs-Test (Augenmaß)
- dir-2 gegen Structured: Die Zeitachse mit Kapseln ist übernommen. Rosa, Pastell-Icons und runde Icon-Kapseln fehlen; Graphit, Kreide und Strichlisten sind eigen. Nicht als „neue Version von Structured“ erkennbar.
- dir-3 gegen Bevel: Farbe pro Kategorie, die den ganzen Bildschirm färbt, ist übernommen. Kein Himmel, keine weißen Karten, keine Prozent-Ringe; die breite, schwere Schrift und der Daumen-Knopf sind eigen.
