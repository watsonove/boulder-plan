// Boulder-Niveau: Grad-Skalen (Fb/V), Einordnung in fünf Stufen, Erfahrung und Freigaben.
// Reine Logik ohne Browser-Abhängigkeiten (wird auch von den Tests genutzt).
// Grundlage: docs/training-research.md

/** Fontainebleau-Grade, wie Hallen sie nutzen (unter 6a mit a/b/c). */
export const FB_GRADES = ['3', '4a', '4b', '4c', '5a', '5b', '5c', '6a', '6a+', '6b', '6b+', '6c', '6c+',
  '7a', '7a+', '7b', '7b+', '7c', '7c+', '8a', '8a+', '8b', '8b+', '8c'];

/** V-Grad je Fb-Grad (verbreitete Umrechnung, z. B. Mammut/theCrag: 6a/6a+ = V3). */
const FB_TO_V = {
  '3': 'VB', '4a': 'V0', '4b': 'V0', '4c': 'V0', '5a': 'V1', '5b': 'V1', '5c': 'V2', '6a': 'V3', '6a+': 'V3',
  '6b': 'V4', '6b+': 'V4', '6c': 'V5', '6c+': 'V5', '7a': 'V6', '7a+': 'V7', '7b': 'V8', '7b+': 'V8',
  '7c': 'V9', '7c+': 'V10', '8a': 'V11', '8a+': 'V12', '8b': 'V13', '8b+': 'V14', '8c': 'V15',
};

export const V_GRADES = [...new Set(Object.values(FB_TO_V))];

export const fbToV = (fb) => FB_TO_V[fb] || null;

/** V → unteres Fb-Äquivalent (konservativ: Grenzfälle landen in der vorsichtigeren Stufe). */
export function vToFb(v) {
  return FB_GRADES.find((g) => FB_TO_V[g] === v) || null;
}

export const gradeIndex = (fb) => FB_GRADES.indexOf(fb);

/** Grad um n Stufen verschieben, an den Enden der Skala begrenzt. */
export function shiftGrade(fb, n) {
  const i = gradeIndex(fb);
  if (i < 0) return fb;
  return FB_GRADES[Math.max(0, Math.min(FB_GRADES.length - 1, i + n))];
}

/**
 * Platzhalter in Vorgabetexten durch Grade ersetzen: {G} = gewählter Grad, {G+1}, {G-2} …
 * „6b–6b“ (durch Begrenzung an der Skala) wird zu „6b“.
 */
export function fillGrades(text, fb) {
  if (!text || typeof text !== 'string' || !text.includes('{G')) return text;
  return text
    .replace(/\{G([+-]\d+)?\}/g, (_, d) => shiftGrade(fb, d ? Number(d) : 0))
    .replace(/(\d[abc]\+?|3)–(\d[abc]\+?|3)/g, (m, a, b) => (a === b ? a : m));
}

// ---------- Stufen ----------

export const LEVELS = [
  { id: 1, name: 'Einsteiger', range: 'bis 5a', vRange: 'VB–V1',
    plan: 'Technik, viel Bouldern, Projektieren und Grundkraft. Kein Hangboard, kein Campus.' },
  { id: 2, name: 'Aufbau', range: '5b–6a', vRange: 'V2–V3',
    plan: 'Technik und Projektieren, 4×4 und Circuits leicht. Ab 1 Jahr Erfahrung leichte Hangs mit Fußentlastung.' },
  { id: 3, name: 'Mittel', range: '6a+–6c', vRange: 'V4–V5',
    plan: 'Repeaters und Max Hangs mit Körpergewicht, Limit-Boulder am Board, Power und Kraftausdauer.' },
  { id: 4, name: 'Fortgeschritten', range: '6c+–7b', vRange: 'V6–V8',
    plan: 'Blocktraining: Max Hangs mit Zusatzgewicht, Board-Limit, Campus mit Füßen, Kraftausdauer.' },
  { id: 5, name: 'Leistung', range: 'ab 7b+', vRange: 'ab V9',
    plan: 'Wie Fortgeschritten mit höherer Intensität und mehr Sätzen, zusätzlich 7-53-Hangs.' },
];

export const levelInfo = (id) => LEVELS.find((l) => l.id === id) || LEVELS[3];

/** Stufe aus dem sicher gekletterten Fb-Grad. */
export function levelForGrade(fb) {
  const i = gradeIndex(fb);
  if (i < 0) return 4;
  if (i <= gradeIndex('5a')) return 1;
  if (i <= gradeIndex('6a')) return 2;
  if (i <= gradeIndex('6c')) return 3;
  if (i <= gradeIndex('7b')) return 4;
  return 5;
}

/** Klettererfahrung; gespeichert wird die Untergrenze in Jahren. */
export const EXPERIENCE = [
  { years: 0, label: 'Unter 1 Jahr', short: '< 1 J.' },
  { years: 1, label: '1–2 Jahre', short: '1–2 J.' },
  { years: 2, label: '2–4 Jahre', short: '2–4 J.' },
  { years: 4, label: 'Über 4 Jahre', short: '> 4 J.' },
];

/** Höchstens so viele Trainingstage pro Woche je Stufe (5 Tage erst ab „Mittel“). */
export const maxDaysForLevel = (level) => (level >= 3 ? 5 : 4);

/** Standardwerte für Pläne aus der Zeit vor der Niveau-Auswahl (Plan „7a+ → 7b/7b+“). */
export const LEGACY_PROFILE = { grade: '7a+', gradeScale: 'fb', level: 4, experience: 2, youth: false, fingerInjury: false };

/** Fehlende Niveau-Felder ergänzen. Gibt true zurück, wenn etwas geändert wurde. */
export function migrateSettings(settings) {
  if (!settings || settings.level != null) return false;
  Object.assign(settings, { ...LEGACY_PROFILE, ...pick(settings, Object.keys(LEGACY_PROFILE)) });
  settings.level = levelForGrade(settings.grade);
  return true;
}

function pick(o, keys) {
  const out = {};
  for (const k of keys) if (o[k] !== undefined && o[k] !== null) out[k] = o[k];
  return out;
}

/** Profil für die Plan-Generierung aus den Einstellungen. */
export function profileOf(s = {}) {
  const grade = FB_GRADES.includes(s.grade) ? s.grade : LEGACY_PROFILE.grade;
  return {
    grade,
    level: s.level ?? levelForGrade(grade),
    years: s.experience ?? LEGACY_PROFILE.experience,
    youth: !!s.youth,
    injury: !!s.fingerInjury,
  };
}

/**
 * Darf eine Übung (Bibliothekseintrag) in einem Profil eingeplant werden?
 * tryLevel = Stufe, deren Parameter gerade verwendet werden (beim Herunterstufen kleiner als profile.level).
 */
export function allowed(lib, profile, tryLevel = profile.level) {
  if (!lib) return false;
  if ((lib.minLevel ?? 1) > profile.level) return false;
  if ((lib.maxLevel ?? 5) < profile.level) return false;
  if ((lib.minYears ?? 0) > profile.years) return false;
  if (profile.youth && lib.noYouth) return false;
  // Fingerverletzung: fingerintensive Übungen eine Stufe leichter
  if (profile.injury && lib.fingerIntense && tryLevel >= profile.level) return false;
  return true;
}

/** Kurze Hinweise, warum Inhalte im Plan fehlen oder leichter sind. */
export function profileNotes(p) {
  const out = [];
  if (p.years < 1 && p.level >= 2) out.push('Unter 1 Jahr Erfahrung: noch kein Hangboard. Sehnen und Ringbänder passen sich langsamer an als Muskeln.');
  else if (p.years < 2 && p.level >= 4) out.push('Unter 2 Jahren Erfahrung: Hangboard nur mit Körpergewicht, kein Campus, keine einarmigen Negatives.');
  if (p.youth) out.push('Unter 18: kein Campus und kein Zusatzgewicht am Hangboard (Wachstumsfugen der Finger).');
  if (p.injury) out.push('Fingerverletzung in den letzten 6 Monaten: Finger-Übungen eine Stufe leichter. Bei Schmerz aufhören und ärztlich abklären.');
  return out;
}

/** Wert aus einer Stufen-Tabelle: höchster Schlüssel ≤ Stufe. */
export function byLevel(map, level) {
  if (!map) return undefined;
  const keys = Object.keys(map).map(Number).filter((k) => k <= level).sort((a, b) => a - b);
  return keys.length ? map[keys[keys.length - 1]] : undefined;
}
