// Trainingslogik: Plan aus plan_seed.json erzeugen, Status berechnen, Termine verschieben.

import { today, addDays, mondayOf, daysBetween, restText, num, WD } from './dates.js';
import { state, save, uid } from './store.js';
import { FB_GRADES, profileOf, allowed, fillGrades, byLevel, migrateSettings } from './levels.js';

export let seed = null;

export async function loadSeed() {
  const res = await fetch('./plan_seed.json');
  if (!res.ok) throw new Error('plan_seed.json nicht gefunden');
  seed = await res.json();
}

/** Für Tests: Seed direkt setzen. */
export function setSeed(s) {
  seed = s;
}

/** Stufe des aktuellen Plans (alte Pläne: 4 = Fortgeschritten). */
export const curLevel = () => state.settings?.level ?? 4;

/**
 * Stufenabhängiger Wert: Schlüssel 1–2 gelten für Einsteiger/Aufbau, der Standardwert ab Stufe 3,
 * sofern es keinen eigenen Schlüssel 3/4/5 gibt (Stufe 4 fällt immer auf den Standardwert zurück).
 */
function leveled(dflt, map, lvl) {
  if (!map) return dflt;
  return byLevel({ 3: dflt, ...map, 4: map[4] ?? dflt }, lvl) ?? dflt;
}

// ---------- Farben & Lookups ----------

/** Jede Session besitzt eine Farbe: hue = Akzent, mid/deep = Bildschirmverlauf (Richtung „Fokus“). */
export const TYPE_THEME = {
  A: { hue: '#FF4646', mid: '#6E0E16', deep: '#3D070C' },
  B: { hue: '#4D82FF', mid: '#132B6B', deep: '#09173D' },
  C: { hue: '#FF9324', mid: '#6B3306', deep: '#3A1A02' },
  D: { hue: '#A874FF', mid: '#35196E', deep: '#1C0D3D' },
  E: { hue: '#2ECCA9', mid: '#0B3D33', deep: '#04201B' },
  T: { hue: '#F5C518', mid: '#544406', deep: '#2B2303' },
};
export const TYPE_COLORS = Object.fromEntries(Object.entries(TYPE_THEME).map(([k, v]) => [k, v.hue]));
/** CSS-Variablen für eine Session-Farbe (inline style). */
export const typeVars = (t) => `--hue:${TYPE_THEME[t].hue};--mid:${TYPE_THEME[t].mid};--deep:${TYPE_THEME[t].deep}`;
const NAMED = {
  red: '#ef4444', orange: '#f97316', yellow: '#eab308', green: '#22c55e', mint: '#2ecca9', teal: '#14b8a6',
  cyan: '#06b6d4', blue: '#3b82f6', indigo: '#6366f1', purple: '#a855f7', pink: '#ec4899', gray: '#8e8e93',
};

/** Phase mit stufenabhängigem Namen und Beschreibung. */
export function phase(id, lvl = curLevel()) {
  const p = seed.phases.find((x) => x.id === id);
  return p ? { ...p, ...leveled({}, p.byLevel, lvl) } : p;
}
export const phaseColor = (id) => NAMED[phase(id)?.color] || NAMED.gray;
export const colorNamed = (name) => NAMED[name] || NAMED.gray;
/** Woche mit stufenabhängigem Wochenfokus. */
export function weekInfo(w, lvl = curLevel()) {
  const x = seed.weeks.find((y) => y.week === w);
  return x ? { ...x, focus: leveled(x.focus, x.focusByLevel, lvl) } : x;
}
/** Titel des Session-Typs; stufenabhängig, mit Halle ggf. abweichend (z. B. Technik-Tag). */
export function typeTitle(t, hasGym = state.settings?.hasGym, lvl = curLevel()) {
  const st = seed.sessionTypes[t];
  if (!st) return t;
  const v = { ...st, ...leveled({}, st.byLevel, lvl) };
  return (hasGym && v.gymTitle) || v.title || t;
}
export const isFinger = (t) => t === 'A' || t === 'C';
export const totalWeeks = () => seed.weeks.length;

export const STATUS_LABEL = { open: 'Offen', partial: 'Teilweise', done: 'Erledigt', skipped: 'Übersprungen' };

export const CATEGORY_TITLES = {
  warmup: 'Aufwärmen', fingers: 'Fingerkraft', board: 'Board', gym: 'Halle', technique: 'Technik', strength: 'Zugkraft',
  antagonist: 'Antagonisten & Schultern', core: 'Core', mobility: 'Mobility & Regeneration',
};

/** Wochen gruppiert nach aufeinanderfolgenden Phasen. */
export function phaseBlocks() {
  const blocks = [];
  for (const w of [...seed.weeks].sort((a, b) => a.week - b.week)) {
    const last = blocks[blocks.length - 1];
    if (last && last.phase.id === w.phase) last.weeks.push(w.week);
    else blocks.push({ phase: phase(w.phase), weeks: [w.week] });
  }
  return blocks;
}

/** Übungsbibliothek nach Kategorie (ohne Benchmarks). */
export function libraryGroups() {
  const order = Object.keys(CATEGORY_TITLES);
  const groups = {};
  for (const [key, ex] of Object.entries(seed.exercises)) {
    if (ex.category === 'benchmark') continue;
    (groups[ex.category] ||= []).push({ key, ex });
  }
  return Object.keys(groups)
    .sort((a, b) => order.indexOf(a) - order.indexOf(b))
    .map((cat) => ({ cat, title: CATEGORY_TITLES[cat] || cat, items: groups[cat].sort((a, b) => a.ex.name.localeCompare(b.ex.name, 'de')) }));
}

// ---------- Planwochen ----------

export const planStart = (s) => mondayOf(s.startDate);
export const weekStart = (w, s) => addDays(planStart(s), (w - 1) * 7 + (s.shiftDays || 0));
export const weekDates = (w, s) => Array.from({ length: 7 }, (_, i) => addDays(weekStart(w, s), i));

export function resolvedWeekdays(wds, n) {
  const u = [...new Set((wds || []).filter((d) => d >= 1 && d <= 7))].sort((a, b) => a - b);
  if (u.length === n) return u;
  return [...(seed.weekLayouts[n]?.defaultWeekdays || [1, 2, 4, 6])].sort((a, b) => a - b);
}

/** Session-Typ des i-ten Trainingstags einer Woche. Slots mit mehreren Typen wechseln wochenweise. */
export function typeForSlot(i, week, layout) {
  const slots = layout.weekOverrides?.[week] || layout.slots;
  if (!slots.length) return null;
  const slot = slots[i % slots.length];
  if (!slot.length) return null;
  return slot[(week - 1) % slot.length];
}

/** Alle Sessions der 12 Wochen gemäß Einstellungen. */
export function blueprints(s) {
  const layout = seed.weekLayouts[s.daysPerWeek];
  if (!layout) return [];
  const wds = resolvedWeekdays(s.weekdays, s.daysPerWeek);
  const out = [];
  for (const info of seed.weeks) {
    const start = weekStart(info.week, s);
    wds.forEach((wd, i) => {
      const type = typeForSlot(i, info.week, layout);
      if (type) out.push({ date: addDays(start, wd - 1), week: info.week, phaseId: info.phase, type, optional: false });
    });
    if (s.showMobility) {
      for (let wd = 1; wd <= 7; wd++) {
        if (!wds.includes(wd)) out.push({ date: addDays(start, wd - 1), week: info.week, phaseId: info.phase, type: 'E', optional: true });
      }
    }
  }
  return out.sort(byDate);
}

function applies(e, week, ph, opts) {
  if (e.onlyIf === 'gym' && !opts.hasGym) return false;
  if (e.onlyIf === 'hangboard' && !opts.hasHangboard) return false;
  if (e.onlyPhases && !e.onlyPhases.includes(ph)) return false;
  if (e.exceptPhases && e.exceptPhases.includes(ph)) return false;
  if (e.onlyWeeks && !e.onlyWeeks.includes(week)) return false;
  if (e.exceptWeeks && e.exceptWeeks.includes(week)) return false;
  return true;
}

const OVERRIDE_FIELDS = [['key', 'exercise'], ['sets', 'sets'], ['reps', 'reps'], ['rest', 'rest'], ['intensity', 'intensity'],
  ['weight', 'weight'], ['minutes', 'minutes'], ['notes', 'notes'], ['core', 'core'], ['limit', 'limit'], ['skip', 'skip'], ['noYouth', 'noYouth']];
/** Diese Felder werden je Phase (phases, gymPhases) bzw. als Ganzes (quick, noHangboard, gym) zusammengeführt. */
const PER_PHASE = ['phases', 'gymPhases'];
const MERGED = ['quick', 'noHangboard', 'gym'];

function mergeSpec(base, o) {
  const out = { ...base };
  for (const [k, v] of Object.entries(o)) {
    if (PER_PHASE.includes(k)) {
      const m = { ...(base[k] || {}) };
      for (const [pk, pv] of Object.entries(v || {})) m[pk] = { ...(m[pk] || {}), ...pv };
      out[k] = m;
    } else if (MERGED.includes(k)) {
      out[k] = { ...(base[k] || {}), ...v };
    } else {
      out[k] = v;
    }
  }
  return out;
}

/**
 * Eintrag einer Session-Vorlage für eine Stufe auflösen.
 * parametersByLevel wird aufsteigend bis zur Stufe zusammengeführt; setzt eine Stufe eine neue Übung (exercise),
 * beginnt sie wieder beim Grundeintrag – so erben z. B. Repeaters keine Werte vom Projektieren der Einsteiger.
 */
export function specForLevel(entry, level) {
  const { parametersByLevel: pbl, ...base } = entry;
  let spec = { ...base };
  if (!pbl) return spec;
  for (const k of Object.keys(pbl).map(Number).sort((a, b) => a - b)) {
    if (k > level) break;
    spec = mergeSpec(pbl[k].exercise !== undefined ? { ...base } : spec, pbl[k]);
  }
  return spec;
}

/** Parameter für Woche/Phase: Grundwerte → Phase → Hangboard-Ersatz → Halle (gym, dann gymPhases). */
function resolveParams(spec, ph, opts) {
  const p = {
    key: spec.exercise, sets: spec.sets ?? 1, reps: spec.reps ?? '', rest: spec.rest ?? 0, intensity: spec.intensity ?? '',
    weight: spec.weight ?? null, minutes: spec.minutes ?? 10, notes: spec.notes ?? '', core: !!spec.core, limit: !!spec.limit, skip: !!spec.skip,
  };
  const apply = (o) => {
    if (!o) return;
    for (const [k, src] of OVERRIDE_FIELDS) if (o[src] !== undefined) p[k] = o[src];
  };
  apply(spec.phases?.[ph]);
  if (!opts.hasHangboard) apply(spec.noHangboard);
  if (opts.hasGym) {
    apply(spec.gym);
    apply(spec.gymPhases?.[ph]);
  }
  return p;
}

const levelOk = (e, level) => (e.minLevel ?? 1) <= level && (e.maxLevel ?? 5) >= level;

/**
 * Übungen einer Session für Woche/Phase und Profil.
 * Ist die Übung einer Stufe im Profil nicht erlaubt (zu wenig Erfahrung, unter 18, Fingerverletzung),
 * wird der Eintrag mit den Parametern der nächstniedrigeren Stufe aufgelöst – bis zur Mindeststufe des Eintrags.
 * Passt keine Stufe, entfällt der Eintrag.
 * opts = Einstellungen (hasHangboard, hasGym, level, grade, experience, youth, fingerInjury)
 */
export function makeExercises(type, week, ph, opts) {
  const prof = profileOf(opts);
  const o = { hasHangboard: !!opts.hasHangboard, hasGym: !!opts.hasGym };
  const out = [];
  for (const entry of seed.sessions[type] || []) {
    if (!levelOk(entry, prof.level)) continue;
    for (let L = prof.level; L >= (entry.minLevel ?? 1); L--) {
      const spec = specForLevel(entry, L);
      if (!applies(spec, week, ph, o)) break;
      const p = resolveParams(spec, ph, o);
      if (p.skip || !p.key) break;
      // Variante mit Zusatzgewicht (z. B. Ersatz ohne Hangboard) ist für unter 18 gesperrt
      if (!allowed(seed.exercises[p.key], prof, L) || (prof.youth && p.noYouth)) continue;
      out.push(buildExercise(p, spec.benchmark, spec.quick, prof.grade));
      break;
    }
  }
  return out;
}

export function buildExercise(p, benchmark = null, quick = null, grade = null) {
  const lib = seed.exercises[p.key];
  const sets = Math.max(1, p.sets);
  const g = (t) => (grade ? fillGrades(t, grade) : t);
  return {
    id: uid(), key: p.key, name: lib?.name || p.key,
    info: (lib?.description || '') + (p.notes ? `\n\nHinweis: ${g(p.notes)}` : ''),
    category: lib?.category || 'custom', sets, reps: g(p.reps), rest: p.rest, intensity: g(p.intensity),
    weight: p.weight, minutes: p.minutes, core: p.core, limit: p.limit, benchmark: benchmark || null,
    alternatives: [...(lib?.alternatives || [])], notes: '', done: false, setsDone: Array(sets).fill(false),
    custom: false, quickSets: quick?.sets ?? null, quickReps: g(quick?.reps) ?? null, quickMinutes: quick?.minutes ?? null,
  };
}

/** opts = Einstellungen bzw. { hasHangboard, hasGym, level, … } */
export function makeSession(bp, opts) {
  const lvl = profileOf(opts).level;
  return {
    id: uid(), date: bp.date, originalDate: bp.date, week: bp.week, phaseId: bp.phaseId, type: bp.type,
    title: typeTitle(bp.type, !!opts.hasGym, lvl), optional: bp.optional, skipped: false, light: false, quick: false,
    moved: false, edited: false, checkIn: null, completedAt: null, notes: '',
    exercises: makeExercises(bp.type, bp.week, bp.phaseId, opts),
  };
}

// ---------- Timer & Hinweise je Übung ----------

/**
 * Timer-Art einer Übung: Intervall (Arbeit/Pause × Wdh.), Satzpause (Countdown nach „Satz fertig“) oder keiner.
 * Wird aus der Übungsbibliothek gelesen, damit auch Sessions aus älteren Plänen und getauschte Übungen passen.
 */
export function exTimer(e) {
  const t = e.timer || seed?.exercises[e.key]?.timer;
  if (t?.type === 'interval') return { type: 'interval', work: t.work, rest: t.rest ?? 0, reps: t.reps ?? 1 };
  return { type: e.rest > 0 ? 'set' : 'none' };
}

/** Sicherheitshinweise aus der Übungsbibliothek. */
export const exWarnings = (e) => seed?.exercises[e.key]?.warnings || [];

// ---------- Übungen ----------

/** Geplante Sätze (Wenig-Zeit-Modus nutzt die Kurzform). */
export const plannedSets = (e, s) => (s.quick ? Math.min(e.quickSets ?? e.sets, e.sets) : e.sets);
/** Effektive Sätze (leichte Variante: −1 Satz). */
export function effSets(e, s) {
  const b = Math.max(1, plannedSets(e, s));
  return s.light && b > 1 ? b - 1 : b;
}
export const effReps = (e, s) => (s.quick ? e.quickReps ?? e.reps : e.reps);
export const effMinutes = (e, s) => (s.quick ? e.quickMinutes ?? e.minutes : e.minutes);
export function doneSets(e, s) {
  const n = effSets(e, s);
  return e.done ? n : e.setsDone.slice(0, n).filter(Boolean).length;
}
export const exProgress = (e, s) => (e.done ? 1 : doneSets(e, s) / Math.max(1, effSets(e, s)));

export function toggleExercise(e) {
  e.done = !e.done;
  e.setsDone = Array(Math.max(e.sets, 1)).fill(e.done);
}

export function toggleSet(e, s, i) {
  while (e.setsDone.length < e.sets) e.setsDone.push(false);
  if (i >= e.setsDone.length) return;
  if (e.done) e.setsDone = e.setsDone.map(() => true);
  e.setsDone[i] = !e.setsDone[i];
  e.done = e.setsDone.slice(0, effSets(e, s)).every(Boolean);
}

export function resizeSets(e) {
  if (e.done) {
    e.setsDone = Array(Math.max(e.sets, 1)).fill(true);
    return;
  }
  const a = e.setsDone.slice(0, e.sets);
  while (a.length < e.sets) a.push(false);
  e.setsDone = a;
}

/** Nach Moduswechsel: Abschluss pro Übung neu berechnen. */
export function syncCompletion(s) {
  for (const e of s.exercises) {
    if (e.setsDone.length) e.done = e.setsDone.slice(0, effSets(e, s)).every(Boolean);
  }
  refreshCompleted(s);
}

/** "6 × 10 s · Pause 3 min · +15–20 kg · RPE 9" */
export function prescription(e, s, { noWeight = false } = {}) {
  const parts = [];
  const n = effSets(e, s);
  const r = effReps(e, s);
  if (n > 1) parts.push(r ? `${n} × ${r}` : `${n} Sätze`);
  else if (r) parts.push(r);
  if (e.rest > 0) parts.push('Pause ' + restText(e.rest));
  if (e.intensity) parts.push(e.intensity);
  if (!noWeight && e.weight !== null && e.weight !== undefined && e.weight !== '') parts.push((e.weight > 0 ? '+' : '') + num(e.weight) + ' kg');
  return parts.join(' · ');
}

// ---------- Sessions ----------

export const byDate = (a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : (a.optional ? 1 : 0) - (b.optional ? 1 : 0));
export function sortSessions() {
  state.sessions.sort(byDate);
}

export const findSession = (id) => state.sessions.find((s) => s.id === id);
export const sessionsOn = (d) => state.sessions.filter((s) => s.date === d).sort(byDate);

export const visible = (s) => s.exercises.filter((e) => !(s.quick && !e.core) && !(s.light && e.limit));
export function required(s) {
  const v = visible(s);
  const c = v.filter((e) => e.core);
  return c.length ? c : v;
}
export function progress(s) {
  const v = visible(s);
  return v.length ? v.reduce((a, e) => a + exProgress(e, s), 0) / v.length : 0;
}
export function isDone(s) {
  const r = required(s);
  return r.length > 0 && r.every((e) => e.done);
}
export function status(s) {
  if (s.skipped) return 'skipped';
  if (isDone(s)) return 'done';
  if (progress(s) > 0) return 'partial';
  return 'open';
}
export const hasProgress = (s) => s.skipped || s.edited || !!s.checkIn || s.exercises.some((e) => e.done || e.setsDone.some(Boolean));
export const estMinutes = (s) => visible(s).reduce((a, e) => a + effMinutes(e, s), 0);
export const isMissed = (s) => !s.optional && status(s) === 'open' && s.date < today();

export function refreshCompleted(s) {
  if (isDone(s)) s.completedAt ||= new Date().toISOString();
  else s.completedAt = null;
}

/** Woche der heutigen bzw. nächsten offenen Session; totalWeeks+1 = abgeschlossen. */
export function currentWeek() {
  const t = today();
  const main = state.sessions.filter((s) => !s.optional);
  const todays = main.find((s) => s.date === t) || state.sessions.find((s) => s.date === t);
  if (todays) return todays.week;
  const next = main.filter((s) => s.date > t && !s.skipped && !isDone(s)).sort(byDate)[0];
  if (next) return next.week;
  if (!main.length && state.settings) {
    const d = daysBetween(weekStart(1, state.settings), t);
    return d < 0 ? 1 : Math.min(Math.floor(d / 7) + 1, totalWeeks() + 1);
  }
  return totalWeeks() + 1;
}

export function planState() {
  const t = today();
  const main = state.sessions.filter((s) => !s.optional);
  if (!main.length) return { kind: 'running' };
  if (t < main[0].date) return { kind: 'notStarted', date: main[0].date };
  if (t > main[main.length - 1].date) return { kind: 'finished' };
  return { kind: 'running' };
}

// ---------- Terminplan ----------

/** Fingerintensive Sessions (A, C) mit weniger als 48 h Abstand zum Zieltag. */
export function fingerConflicts(s, date) {
  if (!isFinger(s.type)) return [];
  return state.sessions.filter((o) => o.id !== s.id && isFinger(o.type) && !o.skipped && Math.abs(daysBetween(o.date, date)) < 2);
}

export function checkMove(s, date) {
  const d = weekDates(s.week, state.settings);
  if (date < d[0] || date > d[6]) return { kind: 'outside' };
  const c = fingerConflicts(s, date);
  return c.length ? { kind: 'conflict', conflicts: c } : { kind: 'ok' };
}

export function moveSession(s, date) {
  s.date = date;
  s.moved = true;
  sortSessions();
  save();
}

/** Krank/Urlaub: alle nicht erledigten Sessions ab heute um X Tage verschieben. */
export function pausePlan(days) {
  const t = today();
  for (const s of state.sessions) if (s.date >= t && !isDone(s)) s.date = addDays(s.date, days);
  state.settings.shiftDays = (state.settings.shiftDays || 0) + days;
  sortSessions();
  save();
}

export function skipWeek(w) {
  for (const s of state.sessions) if (s.week === w && !isDone(s)) s.skipped = true;
  save();
}

/** Nächster Tag ab heute ohne andere Pflicht-Session und ohne 48-h-Konflikt. */
export function nextFreeDay(s) {
  const t = today();
  for (let i = 0; i < 21; i++) {
    const d = addDays(t, i);
    if (state.sessions.some((o) => o.id !== s.id && !o.optional && !o.skipped && o.date === d)) continue;
    if (fingerConflicts(s, d).length) continue;
    return d;
  }
  return null;
}

export function makeUp(s) {
  const d = nextFreeDay(s);
  if (!d) return null;
  s.date = d;
  s.moved = true;
  s.skipped = false;
  sortSessions();
  save();
  return d;
}

/** Zukünftige, noch unberührte Sessions neu erstellen (nach Änderung der Einstellungen). */
export function rebuildFuture() {
  const s = state.settings;
  const t = today();
  const from = Math.max(1, currentWeek());
  state.sessions = state.sessions.filter((x) => !(x.date >= t && !hasProgress(x)));
  for (const bp of blueprints(s)) {
    if (bp.date < t || bp.week < from) continue;
    const exists = state.sessions.some((x) => x.week === bp.week && x.type === bp.type && (bp.type !== 'E' || x.date === bp.date));
    if (!exists) state.sessions.push(makeSession(bp, s));
  }
  sortSessions();
  save();
}

/** Alle Sessions löschen und neu erstellen (Benchmarks bleiben). */
export function regenerateAll() {
  const s = state.settings;
  s.shiftDays = 0;
  state.sessions = blueprints(s).map((bp) => makeSession(bp, s));
  save();
}

/** "Mo: A · Di: B · Do: C · Sa: D" */
export function layoutPreview(wds, n) {
  const layout = seed.weekLayouts[n];
  if (!layout) return '';
  const days = [...wds].sort((a, b) => a - b);
  if (days.length !== n) return `Bitte genau ${n} Tage wählen.`;
  return days.map((wd, i) => `${WD[wd - 1]}: ${layout.slots[i % layout.slots.length].join('/')}`).join(' · ');
}

/** Warnungen, wenn A/C-Tage weniger als 48 h auseinanderliegen (inkl. So → Mo). */
export function layoutWarnings(wds, n) {
  const layout = seed.weekLayouts[n];
  if (!layout || wds.length !== n) return [];
  const days = [...wds].sort((a, b) => a - b);
  const finger = days.filter((wd, i) => layout.slots[i % layout.slots.length].some(isFinger));
  const out = [];
  for (let i = 0; i < finger.length; i++) {
    for (let j = i + 1; j < finger.length; j++) {
      const diff = finger[j] - finger[i];
      if (Math.min(diff, 7 - diff) < 2) out.push(`${WD[finger[i] - 1]} & ${WD[finger[j] - 1]}: fingerintensive Sessions mit weniger als 48 h Abstand.`);
    }
  }
  return out;
}

// ---------- Statistik ----------

export function weekStats(cur) {
  return seed.weeks.map((w) => {
    const rel = state.sessions.filter((s) => s.week === w.week && !s.optional && !s.skipped);
    const done = rel.filter(isDone).length;
    return { week: w.week, done, total: rel.length, rate: rel.length ? done / rel.length : 0, color: phaseColor(w.phase), future: w.week > cur };
  });
}

/** Serie: erledigte Pflicht-Sessions in Folge. Übersprungene sind neutral, verpasste brechen die Serie. */
export function streaks() {
  const t = today();
  const rel = state.sessions.filter((s) => !s.optional && !s.skipped).sort(byDate);
  let longest = 0;
  let run = 0;
  for (const s of rel) {
    if (isDone(s)) longest = Math.max(longest, ++run);
    else if (s.date < t) run = 0;
  }
  let current = 0;
  for (const s of [...rel].reverse()) {
    if (isDone(s)) { current++; continue; }
    if (s.date >= t) continue;
    break;
  }
  return { current, longest };
}

export function totals() {
  const t = today();
  const main = state.sessions.filter((s) => !s.optional && !s.skipped);
  return { done: main.filter(isDone).length, due: main.filter((s) => s.date <= t || isDone(s)).length };
}

// ---------- Benchmarks ----------

export const GRADES = FB_GRADES.slice(1);

export const BENCH = {
  maxHang: {
    title: (hb) => (hb ? 'Max Hang 20 mm (10 s)' : 'Board-Halteübung (7 s)'),
    instr: (hb) => (hb
      ? 'Last, die du 10 s an der 20-mm-Leiste im Halbkrimp halten kannst: Zusatzgewicht positiv, Entlastung negativ.'
      : 'Maximales Zusatzgewicht für 7 s an deiner festen Moonboard-Position (immer dieselben Griffe).'),
    grade: false, unit: 'kg', step: 1.25,
  },
  pullupMax: { title: () => 'Klimmzüge (max. Wdh.)', instr: () => 'Saubere Klimmzüge mit Körpergewicht am Stück.', grade: false, unit: 'Wdh.', step: 1 },
  pullup3RM: { title: () => '3RM gewichtete Klimmzüge', instr: () => 'Zusatzgewicht, mit dem du genau 3 saubere Klimmzüge schaffst.', grade: false, unit: 'kg', step: 1.25 },
  moonGrade: { title: () => 'Höchster Moonboard-Grad', instr: () => 'Höchster gekletterter Grad am Moonboard 40° in der Testsession.', grade: true },
  kilterGrade: { title: () => 'Grad-Pyramide', instr: () => 'Höchster gekletterter Grad in der Testsession (Kilter im selben Winkel oder Halle).', grade: true },
};

/** Benchmarks, die im aktuellen Plan vorkommen (alte Pläne: alle außer den neuen). */
export function benchKinds() {
  const used = new Set();
  for (const s of state.sessions) for (const e of s.exercises) if (e.benchmark) used.add(e.benchmark);
  for (const b of state.benchmarks) used.add(b.kind);
  const kinds = Object.keys(BENCH).filter((k) => used.has(k));
  return kinds.length ? kinds : Object.keys(BENCH).filter((k) => k !== 'pullupMax');
}

export const benchResult = (kind, week) => state.benchmarks.find((b) => b.kind === kind && b.week === week) || null;

export function benchDisplay(r, kind) {
  if (!r) return '–';
  if (BENCH[kind].grade) return r.grade || '–';
  if (r.value === null || r.value === undefined) return '–';
  const unit = BENCH[kind].unit || 'kg';
  return (unit === 'kg' && r.value > 0 ? '+' : '') + num(r.value) + ' ' + unit;
}

export function benchDelta(kind, a, b) {
  if (!a || !b) return null;
  if (BENCH[kind].grade) {
    const i1 = GRADES.indexOf(a.grade);
    const i2 = GRADES.indexOf(b.grade);
    if (i1 < 0 || i2 < 0) return null;
    const d = i2 - i1;
    const unit = Math.abs(d) === 1 ? 'Grad' : 'Grade';
    return { text: d === 0 ? '±0' : `${d > 0 ? '+' : ''}${d} ${unit}`, positive: d >= 0 };
  }
  if (a.value == null || b.value == null) return null;
  const d = b.value - a.value;
  return { text: `${d > 0 ? '+' : ''}${num(d)} ${BENCH[kind].unit || 'kg'}`, positive: d >= 0 };
}

export function upsertBenchmark(kind, week, value, grade, note) {
  let r = benchResult(kind, week);
  if (!r) {
    r = { kind, week };
    state.benchmarks.push(r);
  }
  Object.assign(r, { value, grade, note, date: new Date().toISOString() });
  save();
}

// ---------- Export / Import / Kalender ----------

export function backupJSON() {
  return JSON.stringify({
    app: 'boulderplan', formatVersion: 1, exportedAt: new Date().toISOString(),
    settings: state.settings, sessions: state.sessions, benchmarks: state.benchmarks,
  }, null, 2);
}

export function importJSON(text) {
  const d = JSON.parse(text);
  if (!d || !d.settings || !Array.isArray(d.sessions)) throw new Error('Kein gültiges Boulder-Plan-Backup.');
  state.settings = { ...d.settings, planGenerated: true };
  migrateSettings(state.settings);
  state.sessions = d.sessions;
  state.benchmarks = Array.isArray(d.benchmarks) ? d.benchmarks : [];
  sortSessions();
  save();
}

function icsEscape(s) {
  return String(s).replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\r?\n/g, '\\n');
}

function icsFold(line) {
  const out = [];
  let rest = line;
  while (rest.length > 60) {
    out.push(rest.slice(0, 60));
    rest = ' ' + rest.slice(60);
  }
  out.push(rest);
  return out.join('\r\n');
}

/** Kalenderdatei (.ics) mit allen offenen Trainingstagen inkl. Erinnerung – für die iOS-Kalender-App. */
export function buildICS() {
  const s = state.settings;
  const [hh, mm] = (s.reminderTime || '17:30').split(':');
  const stamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
  const t = today();
  const lines = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//Boulder Plan//DE', 'CALSCALE:GREGORIAN', 'METHOD:PUBLISH', 'X-WR-CALNAME:Boulder Plan'];
  let count = 0;
  for (const x of state.sessions) {
    if (x.optional || x.skipped || isDone(x) || x.date < t) continue;
    count++;
    const d = x.date.replace(/-/g, '');
    const desc = `Woche ${x.week} · ${phase(x.phaseId)?.name || ''}\n` + visible(x).map((e) => `• ${e.name}: ${prescription(e, x)}`).join('\n');
    lines.push(
      'BEGIN:VEVENT', `UID:${x.id}@boulderplan`, `DTSTAMP:${stamp}`, `DTSTART:${d}T${hh}${mm}00`,
      `DURATION:PT${Math.max(30, estMinutes(x))}M`, icsFold(`SUMMARY:${icsEscape(`${x.type} – ${x.title}`)}`),
      icsFold(`DESCRIPTION:${icsEscape(desc)}`),
      'BEGIN:VALARM', 'ACTION:DISPLAY', 'DESCRIPTION:Bouldertraining', 'TRIGGER:PT0M', 'END:VALARM', 'END:VEVENT',
    );
  }
  lines.push('END:VCALENDAR');
  return { text: lines.join('\r\n'), count };
}
