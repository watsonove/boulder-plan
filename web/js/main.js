// Einstieg: lädt Daten, rendert, verarbeitet alle Interaktionen.

import { ui } from './ui.js';
import { state, load, save, saveSoon } from './store.js';
import * as P from './plan.js';
import * as D from './dates.js';
import * as L from './levels.js';
import * as T from './timer.js';
import { currentView, topbar, tabbar, sheetHTML } from './views.js';

const $ = (sel) => document.querySelector(sel);

// ---------- Haptik ----------
// iOS Safari kennt navigator.vibrate nicht. Ab iOS 18 löst ein umgeschalteter
// <input type="checkbox" switch> ein kurzes haptisches Feedback aus – das nutzen wir.
let hapticLabel = null;
function haptic() {
  try {
    if (navigator.vibrate) { navigator.vibrate(15); return; }
    if (!hapticLabel) {
      hapticLabel = document.createElement('label');
      hapticLabel.setAttribute('aria-hidden', 'true');
      hapticLabel.style.display = 'none';
      const input = document.createElement('input');
      input.type = 'checkbox';
      input.setAttribute('switch', '');
      hapticLabel.appendChild(input);
      document.body.appendChild(hapticLabel);
    }
    hapticLabel.click();
  } catch { /* kein Haptik-Support */ }
}

// ---------- Rendering ----------

let lastScrollTarget = null;

/** Session-Farbe auf den ganzen Bildschirm legen (oder neutral). */
function applyTint(type) {
  const root = document.documentElement;
  const t = type ? P.TYPE_THEME[type] : null;
  if (t) {
    root.style.setProperty('--hue', t.hue);
    root.style.setProperty('--mid', t.mid);
    root.style.setProperty('--deep', t.deep);
    document.body.dataset.tint = type;
  } else {
    delete document.body.dataset.tint;
  }
  document.querySelector('meta[name="theme-color"]')?.setAttribute('content', t ? t.mid : '#0B0B0C');
}

function render(resetScroll = false) {
  const y = resetScroll ? 0 : window.scrollY;
  const v = currentView();
  applyTint(v.tint);
  $('#topbar').innerHTML = v.bare ? '' : topbar(v);
  $('#topbar').hidden = !!v.bare;
  $('#main').innerHTML = v.html;
  $('#tabbar').innerHTML = tabbar();
  $('#tabbar').hidden = !!v.noTabs;
  document.body.classList.toggle('no-tabs', !!v.noTabs);
  document.body.classList.toggle('bare', !!v.bare);
  document.body.classList.toggle('tm-work', !!v.work);
  window.scrollTo(0, y);
  // Plan-Tab: beim ersten Öffnen zur aktuellen Woche scrollen
  if (resetScroll && v.scrollTo && lastScrollTarget !== v.scrollTo) {
    lastScrollTarget = v.scrollTo;
    requestAnimationFrame(() => document.getElementById(v.scrollTo)?.scrollIntoView({ block: 'center' }));
  }
}

function renderSheet() {
  $('#sheet-root').innerHTML = sheetHTML();
  document.body.classList.toggle('sheet-open', !!ui.sheet);
}

function openSheet(sheet) {
  ui.sheet = sheet;
  renderSheet();
}

function closeSheet() {
  ui.sheet = null;
  renderSheet();
}

function confirmDialog(title, message, buttons, opts = {}) {
  openSheet({ type: 'confirm', title, message, buttons, ...opts });
}

function info(message, title = '') {
  confirmDialog(title, message, [{ label: 'OK', style: 'primary', run: () => {} }], { noCancel: true });
}

let toastTimer = null;
function toast(text) {
  const el = $('#toast');
  el.textContent = text;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2200);
}

function push(route) {
  ui.stacks[ui.tab].push(route);
  render(true);
}

/** Session und Übung zu data-Attributen holen. */
function ctx(ds) {
  const s = ds.sid ? P.findSession(ds.sid) : null;
  const e = s && ds.eid ? s.exercises.find((x) => x.id === ds.eid) : null;
  return { s, e };
}

function newDraft() {
  const s = state.settings;
  if (!s) {
    return {
      step: 1, startDate: D.nextMondayOrToday(), daysPerWeek: 4, weekdays: [1, 2, 4, 6], hasHangboard: false, hasGym: false, showMobility: true, pauseDays: 7,
      grade: '6a', gradeScale: 'fb', experience: 1, youth: false, fingerInjury: false,
    };
  }
  return {
    startDate: s.startDate, daysPerWeek: s.daysPerWeek, weekdays: [...s.weekdays], hasHangboard: s.hasHangboard, hasGym: !!s.hasGym, showMobility: s.showMobility, pauseDays: 7,
    grade: s.grade, gradeScale: s.gradeScale || 'fb', experience: s.experience, youth: !!s.youth, fingerInjury: !!s.fingerInjury,
  };
}

/** Niveau-Felder aus dem Entwurf für die Einstellungen. */
function profileFields(d) {
  return { grade: d.grade, gradeScale: d.gradeScale, level: L.levelForGrade(d.grade), experience: d.experience, youth: !!d.youth, fingerInjury: !!d.fingerInjury };
}

/** Bei Stufe < 3 sind höchstens 4 Trainingstage erlaubt. */
function clampDays(d) {
  if (d.daysPerWeek > L.maxDaysForLevel(L.levelForGrade(d.grade))) {
    d.daysPerWeek = 4;
    d.weekdays = [...P.seed.weekLayouts[4].defaultWeekdays];
  }
}

// ---------- Dateien teilen ----------

/** Datei über das iOS-Teilen-Menü anbieten, sonst als Download. Muss direkt aus einem Tap aufgerufen werden. */
function shareFile(name, mime, text) {
  const file = new File([text], name, { type: mime });
  if (navigator.canShare && navigator.canShare({ files: [file] })) {
    navigator.share({ files: [file], title: name }).catch((err) => {
      if (err.name !== 'AbortError') downloadFile(file);
    });
  } else {
    downloadFile(file);
  }
}

function downloadFile(file) {
  const url = URL.createObjectURL(file);
  const a = document.createElement('a');
  a.href = url;
  a.download = file.name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 10000);
}

// ---------- Aktionen ----------

const A = {
  // Navigation
  tab({ tab }) {
    if (ui.tab === tab) ui.stacks[tab] = [];
    ui.tab = tab;
    if (tab === 'settings') ui.draft = newDraft();
    if (tab === 'plan') lastScrollTarget = null;
    render(true);
  },
  back() { ui.stacks[ui.tab].pop(); render(true); },
  openSession({ sid }) { push({ view: 'session', id: sid }); },
  openDay({ date }) { push({ view: 'day', date }); },
  openWeek({ week }) { push({ view: 'week', week: Number(week) }); },
  openMissed() { push({ view: 'missed' }); },
  todaySel({ sid }) { ui.todaySel = sid; render(); },

  // Abhaken
  expand({ eid }) {
    if (ui.expanded.has(eid)) ui.expanded.delete(eid); else ui.expanded.add(eid);
    render();
  },
  toggleEx(ds) {
    const { s, e } = ctx(ds);
    const was = P.isDone(s);
    P.toggleExercise(e);
    P.refreshCompleted(s);
    haptic();
    save();
    render();
    if (!was && P.isDone(s)) toast('Session erledigt. Stark.');
  },
  toggleSet(ds) {
    const { s, e } = ctx(ds);
    const was = P.isDone(s);
    P.toggleSet(e, s, Number(ds.i));
    P.refreshCompleted(s);
    haptic();
    save();
    render();
    if (!was && P.isDone(s)) toast('Session erledigt. Stark.');
  },
  // Fokus-Modus
  openFocus({ sid }) {
    const s = P.findSession(sid);
    const vis = P.visible(s);
    const first = vis.findIndex((e) => !e.done);
    push({ view: 'focus', id: sid, idx: first < 0 ? 0 : first });
  },
  focusGo({ i }) {
    const top = ui.stacks[ui.tab][ui.stacks[ui.tab].length - 1];
    if (!top || top.view !== 'focus') return;
    const n = P.visible(P.findSession(top.id)).length;
    top.idx = Math.max(0, Math.min(Number(i), n - 1));
    render(true);
  },
  // „Satz fertig“: Satz abhaken, danach startet die Satzpause
  focusSet(ds) {
    const { s, e } = ctx(ds);
    unlockAudio();
    const was = P.isDone(s);
    completeSet(s, e);
    haptic();
    save();
    if (!e.done && e.rest > 0) startTimer(s, e, T.restTimer(e.rest, Date.now()));
    else if (ui.timer?.eid === e.id) stopTimer();
    render();
    if (!was && P.isDone(s)) toast('Session erledigt. Stark.');
    else if (e.done) toast(`${e.name} erledigt`);
  },
  // Intervall starten (z. B. Repeaters 7/3 × 6)
  tmStart(ds) {
    const { s, e } = ctx(ds);
    unlockAudio();
    startTimer(s, e, T.intervalTimer(P.exTimer(e), Date.now()));
    signal('work');
    render();
  },
  tmToggle() {
    const t = ui.timer?.t;
    if (!t) return;
    unlockAudio();
    if (t.paused) T.resume(t, Date.now()); else T.pause(t, Date.now());
    haptic();
    render();
  },
  tmSkip() {
    const t = ui.timer?.t;
    if (!t) return;
    T.skip(t, Date.now());
    haptic();
    timerTick();
  },
  tmAdjust({ d }) {
    const t = ui.timer?.t;
    if (!t) return;
    T.adjust(t, Number(d), Date.now());
    haptic();
    timerTick();
    render();
  },
  focusUndo(ds) {
    const { s, e } = ctx(ds);
    const n = P.effSets(e, s);
    if (e.done) {
      e.done = false;
      e.setsDone = Array(Math.max(e.sets, 1)).fill(false).map((_, i) => n > 1 && i < n - 1);
    } else {
      const last = e.setsDone.slice(0, n).lastIndexOf(true);
      if (last >= 0) e.setsDone[last] = false;
    }
    if (ui.timer?.eid === e.id) stopTimer();
    P.refreshCompleted(s);
    save();
    render();
  },
  focusWeight(ds) {
    const { s, e } = ctx(ds);
    e.weight = Math.round(((e.weight ?? 0) + Number(ds.d)) * 100) / 100;
    s.edited = true;
    haptic();
    save();
    render();
  },

  toggleQuick(ds) { const { s } = ctx(ds); s.quick = !s.quick; P.syncCompletion(s); haptic(); save(); render(); },
  toggleLight(ds) { const { s } = ctx(ds); s.light = !s.light; P.syncCompletion(s); haptic(); save(); render(); },

  // Check-in
  openCheckIn(ds) {
    const { s } = ctx(ds);
    openSheet({ type: 'checkin', sid: s.id, v: { sleep: 3, energy: 3, fingers: 3, ...(s.checkIn || {}) } });
  },
  rate({ k, n }) { ui.sheet.v[k] = Number(n); haptic(); renderSheet(); },
  applyCheckIn({ light }) {
    const s = P.findSession(ui.sheet.sid);
    s.checkIn = { ...ui.sheet.v };
    s.light = light === '1';
    P.syncCompletion(s);
    save();
    closeSheet();
    render();
    toast(s.light ? 'Leichte Variante aktiv' : 'Viel Erfolg!');
  },

  // Verschieben
  openMove(ds) { openSheet({ type: 'move', sid: ds.sid, pending: null }); },
  moveTo({ date }) {
    const s = P.findSession(ui.sheet.sid);
    if (date === s.date) { closeSheet(); return; }
    if (P.fingerConflicts(s, date).length) { ui.sheet.pending = date; haptic(); renderSheet(); return; }
    P.moveSession(s, date);
    closeSheet();
    render();
    toast(`Verschoben auf ${D.fmtWdShort(date)}`);
  },
  cancelPending() { ui.sheet.pending = null; renderSheet(); },
  confirmMove() {
    const s = P.findSession(ui.sheet.sid);
    const date = ui.sheet.pending;
    P.moveSession(s, date);
    closeSheet();
    render();
    toast(`Verschoben auf ${D.fmtWdShort(date)}`);
  },

  // Session-Menü
  sessionMenu({ sid }) {
    const s = P.findSession(sid);
    const buttons = [
      { label: 'Check-in', run: () => A.openCheckIn({ sid }) },
      { label: 'Verschieben', run: () => A.openMove({ sid }) },
      { label: 'Nachholen (nächste freie Lücke)', run: () => A.makeUp({ sid }) },
      { label: 'Übung hinzufügen', run: () => A.addExercise({ sid }) },
      s.skipped
        ? { label: 'Wiederherstellen', run: () => { s.skipped = false; save(); render(); } }
        : { label: 'Überspringen', style: 'danger', run: () => A.skipSession({ sid }) },
      { label: 'Fortschritt zurücksetzen', style: 'danger', run: () => A.resetSession({ sid }) },
    ];
    confirmDialog(`${s.type} – ${s.title}`, D.fmtLong(s.date), buttons);
  },
  makeUp({ sid }) {
    const s = P.findSession(sid);
    const d = P.makeUp(s);
    render();
    if (d) info(`${s.type} – ${s.title} liegt jetzt auf ${D.fmtLong(d)}.`, 'Nachgeholt');
    else info('In den nächsten drei Wochen gibt es keine freie Lücke ohne 48-h-Konflikt.', 'Keine Lücke gefunden');
  },
  skipSession({ sid }) {
    const s = P.findSession(sid);
    s.skipped = true;
    haptic();
    save();
    render();
  },
  skipAllMissed() {
    confirmDialog('Alle verpassten Sessions überspringen?', '', [{
      label: 'Alle überspringen', style: 'danger',
      run: () => { state.sessions.filter(P.isMissed).forEach((s) => { s.skipped = true; }); save(); render(); },
    }]);
  },
  resetSession({ sid }) {
    confirmDialog('Fortschritt zurücksetzen?', 'Alle Haken, der Check-in und die Modi dieser Session werden entfernt.', [{
      label: 'Zurücksetzen', style: 'danger',
      run: () => {
        const s = P.findSession(sid);
        s.exercises.forEach((e) => { e.done = false; e.setsDone = Array(Math.max(e.sets, 1)).fill(false); });
        Object.assign(s, { checkIn: null, light: false, quick: false, skipped: false, completedAt: null });
        save();
        render();
      },
    }]);
  },
  skipWeek({ week }) {
    confirmDialog(`Woche ${week} überspringen?`, 'Alle noch offenen Sessions dieser Woche werden als übersprungen markiert.', [{
      label: 'Überspringen', style: 'danger', run: () => { P.skipWeek(Number(week)); render(); },
    }]);
  },

  // Übungen bearbeiten
  addExercise({ sid }) { openSheet({ type: 'edit', sid, eid: null }); },
  editExercise({ sid, eid }) { openSheet({ type: 'edit', sid, eid }); },
  saveExercise() {
    const s = P.findSession(ui.sheet.sid);
    const val = (id) => document.getElementById(id).value;
    const name = val('f-name').trim();
    if (!name) { document.getElementById('f-name').focus(); return; }
    let e = ui.sheet.eid ? s.exercises.find((x) => x.id === ui.sheet.eid) : null;
    if (!e) {
      e = P.buildExercise({ key: 'custom', sets: 1, reps: '', rest: 0, intensity: '', weight: null, minutes: 10, notes: '', core: false, limit: false });
      e.key = `custom-${e.id}`;
      e.custom = true;
      e.category = 'custom';
      s.exercises.push(e);
    }
    e.name = name;
    e.info = val('f-info');
    e.core = document.getElementById('f-core').checked;
    e.reps = val('f-reps');
    e.rest = Math.max(0, Math.round(D.parseNum(val('f-rest')) ?? 0));
    e.intensity = val('f-intensity');
    e.weight = D.parseNum(val('f-weight'));
    e.minutes = Math.max(1, Math.round(D.parseNum(val('f-minutes')) ?? 10));
    e.notes = val('f-notes');
    const sets = Math.max(1, Math.round(D.parseNum(val('f-sets')) ?? 1));
    if (sets !== e.sets) { e.sets = sets; P.resizeSets(e); }
    s.edited = true;
    P.refreshCompleted(s);
    save();
    closeSheet();
    render();
  },
  deleteExercise({ sid, eid }) {
    const s = P.findSession(sid);
    const e = s.exercises.find((x) => x.id === eid);
    confirmDialog(`„${e.name}“ löschen?`, 'Die Übung wird nur aus dieser Session entfernt.', [{
      label: 'Löschen', style: 'danger',
      run: () => { s.exercises = s.exercises.filter((x) => x.id !== eid); s.edited = true; P.refreshCompleted(s); save(); render(); },
    }]);
  },
  swapExercise({ sid, eid }) { openSheet({ type: 'swap', sid, eid }); },
  doSwap({ key }) {
    const s = P.findSession(ui.sheet.sid);
    const e = s.exercises.find((x) => x.id === ui.sheet.eid);
    const lib = P.seed.exercises[key];
    const alts = new Set([...e.alternatives, e.key, ...(lib.alternatives || [])]);
    alts.delete(key);
    e.alternatives = [...alts].filter((k) => P.seed.exercises[k]);
    Object.assign(e, { key, name: lib.name, info: lib.description, category: lib.category, done: false, setsDone: Array(Math.max(e.sets, 1)).fill(false) });
    if (lib.defaultReps) e.reps = lib.defaultReps;
    if (lib.defaultIntensity) e.intensity = lib.defaultIntensity;
    s.edited = true;
    P.refreshCompleted(s);
    haptic();
    save();
    closeSheet();
    render();
    toast(`Getauscht: ${lib.name}`);
  },

  // Benchmarks
  openBench({ kind, week }) {
    const sh = { type: 'bench', kind, week: Number(week) };
    loadBench(sh);
    openSheet(sh);
  },
  benchWeek({ week }) { ui.sheet.week = Number(week); loadBench(ui.sheet); renderSheet(); },
  saveBench() {
    const sh = ui.sheet;
    const isGrade = P.BENCH[sh.kind].grade;
    const value = isGrade ? null : D.parseNum(document.getElementById('b-value').value);
    const grade = isGrade ? document.getElementById('b-grade').value : null;
    P.upsertBenchmark(sh.kind, sh.week, value, grade, document.getElementById('b-note').value);
    haptic();
    closeSheet();
    render();
    toast('Benchmark gespeichert');
  },

  // Stepper (+/−) in Formularen
  step({ target, d, min }) {
    const input = document.getElementById(target);
    const cur = D.parseNum(input.value) ?? 0;
    let next = Math.round((cur + Number(d)) * 100) / 100;
    if (min !== undefined) next = Math.max(Number(min), next);
    input.value = String(next).replace('.', ',');
    if (target === 'pause-days') ui.draft.pauseDays = next;
    haptic();
  },

  // Kalender
  calMode({ mode }) { ui.cal.mode = mode; render(); },
  calStep({ dir }) {
    const n = Number(dir);
    ui.cal.anchor = ui.cal.mode === 'month' ? D.addMonths(ui.cal.anchor, n) : D.addDays(ui.cal.anchor, 7 * n);
    render();
  },
  calToday() { ui.cal.anchor = D.today(); render(); },

  // Einstellungen & Onboarding
  onbStep({ step }) { ui.draft.step = Number(step); render(true); },
  draftScale({ scale }) {
    ui.draft.gradeScale = scale;
    if (state.settings) { state.settings.gradeScale = scale; save(); }
    haptic();
    render();
  },
  draftGrade({ g }) {
    if (!L.FB_GRADES.includes(g)) return;
    ui.draft.grade = g;
    clampDays(ui.draft);
    haptic();
    render();
  },
  draftExp({ y }) { ui.draft.experience = Number(y); haptic(); render(); },
  draftDays({ n }) {
    const days = Number(n);
    ui.draft.daysPerWeek = days;
    ui.draft.weekdays = [...P.seed.weekLayouts[days].defaultWeekdays];
    haptic();
    render();
  },
  draftWd({ wd }) {
    const d = ui.draft;
    const day = Number(wd);
    if (d.weekdays.includes(day)) d.weekdays = d.weekdays.filter((x) => x !== day);
    else if (d.weekdays.length < d.daysPerWeek) d.weekdays = [...d.weekdays, day].sort((a, b) => a - b);
    else { toast(`Höchstens ${d.daysPerWeek} Tage – erst einen abwählen.`); return; }
    haptic();
    render();
  },
  createPlan() {
    const d = ui.draft;
    clampDays(d);
    state.settings = {
      startDate: D.mondayOf(d.startDate), daysPerWeek: d.daysPerWeek, weekdays: [...d.weekdays].sort((a, b) => a - b),
      hasHangboard: d.hasHangboard, hasGym: d.hasGym, showMobility: d.showMobility, shiftDays: 0, reminderTime: '17:30', theme: 'dark', planGenerated: true,
      ...profileFields(d),
    };
    P.regenerateAll();
    ui.tab = 'today';
    haptic();
    render(true);
    navigator.storage?.persist?.();
    toast('Plan erstellt – viel Erfolg!');
  },
  applySettings() {
    const d = ui.draft;
    const s = state.settings;
    const full = D.mondayOf(d.startDate) !== D.mondayOf(s.startDate);
    confirmDialog('Änderungen übernehmen?', full
      ? 'Das Startdatum wurde geändert: Der gesamte Plan wird neu erstellt, der Fortschritt der Sessions geht verloren. Benchmarks bleiben erhalten.'
      : 'Zukünftige, noch nicht begonnene Sessions werden neu erstellt. Verschobene, aber unberührte Termine werden zurückgesetzt.', [{
      label: 'Übernehmen', style: 'primary',
      run: () => {
        clampDays(d);
        Object.assign(s, {
          startDate: D.mondayOf(d.startDate), daysPerWeek: d.daysPerWeek, weekdays: [...d.weekdays].sort((a, b) => a - b),
          hasHangboard: d.hasHangboard, hasGym: d.hasGym, showMobility: d.showMobility, ...profileFields(d),
        });
        if (full) P.regenerateAll(); else P.rebuildFuture();
        ui.draft = newDraft();
        render();
        toast(full ? 'Plan neu erstellt' : 'Zukünftige Sessions aktualisiert');
      },
    }]);
  },
  pausePlan() {
    const days = Math.max(1, Math.round(D.parseNum(document.getElementById('pause-days').value) ?? 7));
    confirmDialog('Plan pausieren?', `Alle noch offenen Sessions ab heute rücken ${days} Tage nach hinten.`, [{
      label: `Um ${days} Tage verschieben`, style: 'primary', run: () => { P.pausePlan(days); render(); toast(`Plan um ${days} Tage verschoben`); },
    }]);
  },
  regenerate() {
    confirmDialog('Plan komplett neu erstellen?', 'Alle Sessions inkl. Haken und Notizen werden gelöscht und neu angelegt. Benchmarks bleiben erhalten.', [{
      label: 'Neu erstellen', style: 'danger', run: () => { P.regenerateAll(); render(); toast('Plan neu erstellt'); },
    }]);
  },
  exportData() {
    shareFile(`BoulderPlan-Backup-${D.today()}.json`, 'application/json', P.backupJSON());
  },
  importData() {
    confirmDialog('Backup importieren?', 'Alle aktuellen Sessions und Benchmarks werden durch den Inhalt der Datei ersetzt.', [{
      label: 'Datei auswählen', style: 'danger', run: () => document.getElementById('importFile').click(),
    }]);
  },
  icsShare() {
    const { text, count } = P.buildICS();
    if (!count) { info('Es gibt keine offenen Trainingstage mehr.'); return; }
    shareFile('BoulderPlan.ics', 'text/calendar', text);
  },
  icsOpen() {
    const { text, count } = P.buildICS();
    if (!count) { info('Es gibt keine offenen Trainingstage mehr.'); return; }
    downloadFile(new File([text], 'BoulderPlan.ics', { type: 'text/calendar' }));
  },

  // Sheets
  closeSheet() { closeSheet(); },
  sheetBtn({ i }) {
    const btn = ui.sheet.buttons[Number(i)];
    closeSheet();
    btn.run();
  },
};

// ---------- Pausen- und Intervall-Timer (Fokus-Modus) ----------
// Die Rechenlogik steckt in timer.js (Zeitstempel statt Zähler: läuft korrekt weiter, auch wenn das iPhone
// kurz gesperrt war). Hier: Anzeige aktualisieren, Ton, Vibration, Bildschirm anlassen.

/** Nächsten offenen Satz abhaken (bzw. die Übung, wenn sie nur einen Satz hat). */
function completeSet(s, e) {
  const n = P.effSets(e, s);
  if (n <= 1) {
    if (!e.done) P.toggleExercise(e);
  } else {
    const i = e.setsDone.slice(0, n).findIndex((x) => !x);
    if (i >= 0) P.toggleSet(e, s, i);
  }
  P.refreshCompleted(s);
}

let loop = null;
function startTimer(s, e, t) {
  ui.timer = { sid: s.id, eid: e.id, t };
  keepAwake(true);
  clearInterval(loop);
  loop = setInterval(timerTick, 200);
}

function stopTimer() {
  ui.timer = null;
  clearInterval(loop);
  loop = null;
  keepAwake(false);
}

function timerTick() {
  const tm = ui.timer;
  if (!tm) { stopTimer(); return; }
  const now = Date.now();
  let events = T.tick(tm.t, now);
  let changed = false;
  for (let guard = 0; events.length && guard < 20; guard++) {
    const next = [];
    for (const ev of events) {
      if (ev.type === 'warn') { signal('warn'); continue; }
      changed = true;
      if (ev.type === 'work') signal('work');
      else if (ev.type === 'pause') signal('pause');
      else if (ev.type === 'restDone') {
        signal('end');
        stopTimer();
        toast('Pause vorbei – nächster Satz');
      } else if (ev.type === 'setDone') {
        signal('end');
        const s = P.findSession(tm.sid);
        const e = s?.exercises.find((x) => x.id === tm.eid);
        if (!s || !e) { stopTimer(); continue; }
        const was = P.isDone(s);
        completeSet(s, e);
        save();
        if (!e.done && e.rest > 0) {
          // Satzpause beginnt am geplanten Ende des Satzes (nicht erst jetzt)
          tm.t = T.restTimer(e.rest, ev.at);
          next.push(...T.tick(tm.t, now));
        } else {
          stopTimer();
          if (!was && P.isDone(s)) toast('Session erledigt. Stark.');
          else toast(e.done ? `${e.name} erledigt` : 'Satz geschafft');
        }
      }
    }
    events = next;
  }
  if (changed) { if (!ui.sheet) render(); return; }
  // Schneller Weg: nur Ziffern und Balken aktualisieren
  const t = ui.timer?.t;
  if (!t) return;
  const el = document.getElementById('tm-time');
  const bar = document.getElementById('tm-bar');
  if (el) el.textContent = T.fmtTime(T.remaining(t, now), el.dataset.long === '1');
  if (bar) bar.style.width = `${(T.fraction(t, now) * 100).toFixed(1)}%`;
}

// Ton: Web Audio, muss einmal durch einen Tap freigeschaltet werden (iOS).
let actx = null;
function unlockAudio() {
  try {
    actx ||= new (window.AudioContext || window.webkitAudioContext)();
    if (actx.state !== 'running') actx.resume();
  } catch { actx = null; }
}

function beep(freq, dur, delay = 0, vol = 0.35) {
  if (!actx || actx.state !== 'running') return;
  try {
    const o = actx.createOscillator();
    const g = actx.createGain();
    const t0 = actx.currentTime + delay;
    o.type = 'sine';
    o.frequency.value = freq;
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(vol, t0 + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(g).connect(actx.destination);
    o.start(t0);
    o.stop(t0 + dur + 0.03);
  } catch { /* kein Ton */ }
}

/** warn = kurzer Ton 3/2/1 s vor Ende; work = Start einer Arbeitsphase; pause = Pause beginnt; end = Satz/Pause vorbei. */
function signal(kind) {
  const vib = (p) => { try { navigator.vibrate?.(p); } catch { /* iOS: keine Vibration */ } };
  if (kind === 'warn') { beep(880, 0.09); vib(40); return; }
  if (kind === 'work') { beep(1320, 0.14); beep(1320, 0.14, 0.18); vib([90, 60, 90]); }
  else if (kind === 'pause') { beep(660, 0.3); vib(160); }
  else { beep(1320, 0.18); beep(1760, 0.4, 0.22); vib([220, 100, 220]); }
  haptic();
}

// Bildschirm anlassen, solange ein Timer läuft (Screen Wake Lock API, iOS ab 16.4).
let wakeLock = null;
async function keepAwake(on) {
  try {
    if (on && !wakeLock && 'wakeLock' in navigator && document.visibilityState === 'visible') {
      wakeLock = await navigator.wakeLock.request('screen');
      wakeLock.addEventListener('release', () => { wakeLock = null; });
    } else if (!on && wakeLock) {
      const w = wakeLock;
      wakeLock = null;
      await w.release();
    }
  } catch { wakeLock = null; }
}

function loadBench(sh) {
  const r = P.benchResult(sh.kind, sh.week);
  sh.value = r?.value ?? 0;
  sh.grade = r?.grade || state.settings?.grade || '6a';
  sh.note = r?.note || '';
}

// Texteingaben speichern ohne neu zu rendern (Fokus bleibt erhalten)
const INPUT = {
  sessionNotes(el) { const { s } = ctx(el.dataset); s.notes = el.value; saveSoon(); },
  exNotes(el) { const { e } = ctx(el.dataset); e.notes = el.value; saveSoon(); },
  swapSearch(el) {
    const q = el.value.trim().toLowerCase();
    document.querySelectorAll('.swap-item').forEach((b) => { b.hidden = q && !b.dataset.name.includes(q); });
    document.querySelectorAll('.swap-group').forEach((g) => {
      g.hidden = (q && g.dataset.group === 'alts') || ![...g.querySelectorAll('.swap-item')].some((b) => !b.hidden);
    });
  },
};

const CHANGE = {
  draft(el) {
    const f = el.dataset.field;
    if (el.type === 'checkbox') ui.draft[f] = el.checked;
    else if (el.type === 'date') { if (!el.value) return; ui.draft[f] = el.value; }
    else ui.draft[f] = el.value;
    if (el.type === 'checkbox') haptic();
    render();
  },
  reminderTime(el) { if (el.value) { state.settings.reminderTime = el.value; save(); } },
  theme(el) { state.settings.theme = el.value; save(); applyTheme(); },
};

function applyTheme() {
  document.documentElement.dataset.theme = state.settings?.theme === 'system' ? 'system' : 'dark';
}

function onImportFile(input) {
  const file = input.files?.[0];
  input.value = '';
  if (!file) return;
  file.text().then((text) => {
    try {
      P.importJSON(text);
      ui.stacks = { today: [], calendar: [], plan: [], progress: [], settings: [] };
      ui.draft = newDraft();
      applyTheme();
      render(true);
      toast('Import erfolgreich');
    } catch (err) {
      info(`Die Datei ist kein gültiges Boulder-Plan-Backup.\n(${err.message})`, 'Import fehlgeschlagen');
    }
  });
}

// ---------- Drag & Drop (Wochenansicht) ----------
// Long-Press (0,4 s) auf eine Session-Karte startet das Ziehen; Loslassen über einem Tag verschiebt.

const drag = { timer: null, active: false, sid: null, ghost: null, startX: 0, startY: 0, target: null, suppressClick: false };

function dragStart(e) {
  const card = e.target.closest('[data-drag-sid]');
  if (!card || (e.pointerType === 'mouse' && e.button !== 0)) return;
  drag.sid = card.dataset.dragSid;
  drag.startX = e.clientX;
  drag.startY = e.clientY;
  drag.timer = setTimeout(() => {
    drag.active = true;
    haptic();
    const rect = card.getBoundingClientRect();
    const ghost = card.cloneNode(true);
    ghost.classList.add('ghost');
    ghost.style.width = `${rect.width}px`;
    ghost.style.left = `${rect.left}px`;
    ghost.style.top = `${rect.top}px`;
    ghost.dataset.offX = String(drag.startX - rect.left);
    ghost.dataset.offY = String(drag.startY - rect.top);
    document.body.appendChild(ghost);
    drag.ghost = ghost;
    card.classList.add('drag-source');
  }, 400);
}

function dragMove(e) {
  if (!drag.sid) return;
  if (!drag.active) {
    if (Math.hypot(e.clientX - drag.startX, e.clientY - drag.startY) > 10) dragCancel();
    return;
  }
  const g = drag.ghost;
  g.style.left = `${e.clientX - Number(g.dataset.offX)}px`;
  g.style.top = `${e.clientY - Number(g.dataset.offY)}px`;
  const under = document.elementFromPoint(e.clientX, e.clientY)?.closest('[data-drop-date]');
  if (under !== drag.target) {
    drag.target?.classList.remove('drop-target');
    under?.classList.add('drop-target');
    drag.target = under;
  }
  // Am Rand automatisch scrollen
  if (e.clientY < 90) window.scrollBy(0, -12);
  else if (e.clientY > window.innerHeight - 110) window.scrollBy(0, 12);
}

function dragEnd() {
  if (drag.active) {
    drag.suppressClick = true;
    setTimeout(() => { drag.suppressClick = false; }, 350);
    const date = drag.target?.dataset.dropDate;
    const s = P.findSession(drag.sid);
    dragCancel();
    if (s && date && date !== s.date) handleDrop(s, date);
    return;
  }
  dragCancel();
}

function dragCancel() {
  clearTimeout(drag.timer);
  drag.ghost?.remove();
  drag.target?.classList.remove('drop-target');
  document.querySelectorAll('.drag-source').forEach((el) => el.classList.remove('drag-source'));
  Object.assign(drag, { timer: null, active: false, sid: null, ghost: null, target: null });
}

function handleDrop(s, date) {
  const check = P.checkMove(s, date);
  if (check.kind === 'outside') {
    info(`Sessions lassen sich nur innerhalb ihrer Trainingswoche (Woche ${s.week}) verschieben. Für spätere Termine nutze „Nachholen“ im ⋯-Menü.`, 'Andere Woche');
    return;
  }
  if (check.kind === 'conflict') {
    const list = check.conflicts.map((o) => `${o.type} – ${o.title} (${D.fmtWdShort(o.date)})`).join(', ');
    confirmDialog('Weniger als 48 h Erholung', `Fingerintensive Sessions (A, C) sollten mindestens 48 h auseinanderliegen: ${list}`, [{
      label: 'Trotzdem verschieben', style: 'danger', run: () => { P.moveSession(s, date); render(); toast(`Verschoben auf ${D.fmtWdShort(date)}`); },
    }]);
    return;
  }
  P.moveSession(s, date);
  haptic();
  render();
  toast(`Verschoben auf ${D.fmtWdShort(date)}`);
}

// ---------- Monats-Wischgeste ----------

let swipe = null;
function swipeStart(e) {
  if (!e.target.closest('[data-swipe="month"]') || ui.sheet) { swipe = null; return; }
  swipe = { x: e.clientX, y: e.clientY };
}
function swipeEnd(e) {
  if (!swipe) return;
  const dx = e.clientX - swipe.x;
  const dy = e.clientY - swipe.y;
  swipe = null;
  if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy) * 1.5) {
    drag.suppressClick = true;
    setTimeout(() => { drag.suppressClick = false; }, 300);
    A.calStep({ dir: dx < 0 ? 1 : -1 });
  }
}

// ---------- Events ----------

function bindEvents() {
  document.addEventListener('click', (e) => {
    if (drag.suppressClick) { e.preventDefault(); e.stopPropagation(); return; }
    const el = e.target.closest('[data-action]');
    if (!el || el.disabled) return;
    const fn = A[el.dataset.action];
    if (!fn) return;
    e.preventDefault();
    fn({ ...el.dataset }, el);
  }, true);

  document.addEventListener('input', (e) => {
    const k = e.target.dataset?.input;
    if (k) INPUT[k]?.(e.target);
  });

  document.addEventListener('change', (e) => {
    if (e.target.id === 'importFile') { onImportFile(e.target); return; }
    const k = e.target.dataset?.change;
    if (k) CHANGE[k]?.(e.target);
  });

  document.addEventListener('pointerdown', (e) => {
    if (ui.tab === 'calendar' && ui.cal.mode === 'week') dragStart(e);
    swipeStart(e);
  });
  document.addEventListener('pointermove', dragMove);
  document.addEventListener('pointerup', (e) => { dragEnd(); swipeEnd(e); });
  document.addEventListener('pointercancel', () => { dragCancel(); swipe = null; });
  // Während des Ziehens darf iOS nicht scrollen
  document.addEventListener('touchmove', (e) => { if (drag.active) e.preventDefault(); }, { passive: false });
  // Kontextmenü beim Long-Press auf Karten unterdrücken
  document.addEventListener('contextmenu', (e) => { if (e.target.closest('[data-drag-sid]')) e.preventDefault(); });

  // Beim Zurückkehren in die App: Timer nachholen, Bildschirm wieder anlassen, neu zeichnen (z. B. neuer Tag)
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) return;
    if (ui.timer) { timerTick(); keepAwake(true); }
    if (!ui.sheet) render();
  });
}

// ---------- Start ----------

async function init() {
  load();
  // Pläne aus der Zeit vor der Niveau-Auswahl: Fortgeschritten (7a+), 2–4 Jahre Erfahrung
  if (L.migrateSettings(state.settings)) save();
  applyTheme();
  try {
    await P.loadSeed();
  } catch (err) {
    $('#main').innerHTML = `<div class="empty"><div class="big-emoji">⚠️</div><p>Die Plan-Daten konnten nicht geladen werden.<br>${err.message}</p></div>`;
    return;
  }
  ui.draft = newDraft();
  bindEvents();
  render(true);
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('./sw.js').catch(() => {});
}

init();
