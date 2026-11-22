# Boulder Plan als Web-App aufs iPhone bringen

Die App besteht nur aus den Dateien in diesem Ordner `web/`. Sie muss einmal unter einer
HTTPS-Adresse liegen; danach installierst du sie auf dem iPhone und sie läuft offline.
Deine Trainingsdaten werden **nur auf dem iPhone** gespeichert – der Server sieht sie nie.

## 1. Online stellen (kostenlos, einmalig, ca. 5 Minuten)

### Variante A: GitHub Pages
1. Auf github.com ein kostenloses Konto anlegen.
2. Oben rechts **+ → New repository**, Name z. B. `boulder-plan`, **Public**, „Create repository“.
3. Auf der Repo-Seite **„uploading an existing file“** anklicken und den **Inhalt** des Ordners `web/`
   (also `index.html`, `sw.js`, `plan_seed.json`, `manifest.webmanifest` und die Ordner `css`, `js`, `icons`)
   ins Browserfenster ziehen → **Commit changes**.
4. **Settings → Pages**: unter „Branch“ `main` und `/ (root)` wählen → **Save**.
5. Nach ca. 1 Minute steht oben die Adresse, z. B. `https://DEINNAME.github.io/boulder-plan/`.

Das Repo ist öffentlich – es enthält aber nur den App-Code und den Trainingsplan, keine persönlichen Daten.

### Variante B: Netlify Drop
1. app.netlify.com/drop öffnen und kostenloses Konto anlegen (ohne Konto wird die Seite nach kurzer Zeit gelöscht).
2. Den Ordner `web/` ins Browserfenster ziehen → du bekommst sofort eine `https://…netlify.app`-Adresse.

## 2. Auf dem iPhone installieren
1. Die Adresse in **Safari** öffnen.
2. **Teilen-Symbol** (Quadrat mit Pfeil) → **„Zum Home-Bildschirm“** → Hinzufügen.
3. Ab jetzt die App **immer über das Symbol auf dem Home-Bildschirm** öffnen. Sie startet im Vollbild und
   funktioniert auch ohne Internet. (Safari selbst hat einen getrennten Speicher – dort siehst du deine Daten nicht.)

## 3. Gut zu wissen
- **Erinnerungen:** Web-Apps können ohne Server keine Mitteilungen planen. Unter
  *Einstellungen → Erinnerungen* erzeugt die App eine Kalenderdatei mit allen offenen Trainingstagen
  (inkl. Hinweis zur gewählten Uhrzeit) – im Teilen-Menü „Kalender“ wählen bzw. die Datei öffnen und
  „Alle hinzufügen“. Nach größeren Plan-Änderungen erneut übernehmen und alte Termine vorher löschen.
- **Backup:** *Einstellungen → Fortschritt exportieren* sichert alles als JSON (z. B. in „Dateien“/iCloud Drive).
  Wenn du die App löschst oder die Adresse wechselst, kannst du so alles wieder importieren.
- **Adresse nicht ändern:** Die Daten hängen an der Web-Adresse. Bei einem Umzug vorher exportieren.
- **Updates:** Lädst du geänderte Dateien hoch (z. B. eine angepasste `plan_seed.json`), übernimmt die App sie
  beim übernächsten Öffnen. Neue Plan-Inhalte wirken auf bestehende Sessions erst nach
  *Einstellungen → Plan komplett neu erstellen*.
- **Haptik:** Ab iOS 18 gibt es beim Abhaken ein kurzes haptisches Feedback, auf älteren Versionen nicht.

## Option „Kommerzielle Boulderhalle verfügbar“
Einstellbar beim ersten Start und unter *Einstellungen → Plan*. Mit Halle ändert sich:

| Session | Phase | Ohne Halle | Mit Halle |
|---|---|---|---|
| A Limit & Finger | alle | Board | unverändert (Moonboard-Limit einzeln gegen „Hallen-Limit-Boulder“ tauschbar) |
| B Kraft | Basis, Max, Power | – | + optional „Freies Bouldern“ 30–45 min (zählt nicht für „erledigt“) |
| C Kilter Power | Power | – | + Koordinations-/Dyno-Boulder in der Halle |
| D Kraftausdauer | Basis, Deload | Kilter 4×4 | Hallen-4×4 (gemischte Stile) |
| D Kraftausdauer | Maximalkraft | Kilter 4×4 | unverändert |
| D Kraftausdauer | Power | Linked Boulders (Board) | Hallen-Circuits |
| T Technik (5 Tage) | alle | Kilter | Technik & Volumen in der Halle |

„Freies Bouldern“ entfällt in Deload- und Testwochen und wird bei „Wenig Zeit“ sowie in der leichten
Variante (schlechter Check-in) ausgeblendet. Beim Umschalten werden nur zukünftige, noch nicht begonnene Sessions angepasst.

In `plan_seed.json` steuern das drei Felder pro Übungseintrag:
- `"onlyIf": "gym"` – Übung gibt es nur mit Halle
- `"gym": { … }` – Ersatz/Änderung mit Halle (alle Phasen)
- `"gymPhases": { "base": { … } }` – Ersatz/Änderung mit Halle nur in bestimmten Phasen

## Lokal testen (am PC)
Im Ordner `Boulder App` ausführen: `python -m http.server 8765 --directory web`, dann
`http://localhost:8765` im Browser öffnen (Entwicklertools → Handy-Ansicht).
