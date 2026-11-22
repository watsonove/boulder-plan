// HTML-Rendering aller Ansichten. Interaktion läuft über data-action-Attribute (siehe main.js).

import { ui } from './ui.js';
import { state } from './store.js';
import * as P from './plan.js';
import * as D from './dates.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const attrs = (o = {}) => Object.entries(o).map(([k, v]) => ` data-${k}="${esc(v)}"`).join('');

// ---------- Icons ----------

const svg = (d, size = 24, sw = 2.4) => `<svg viewBox="0 0 24 24" width="${size}" height="${size}" aria-hidden="true"><path d="${d}" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
export const ICON = {
  check: svg('M5 12.5l4.5 4.5L19 7.5', 28, 3.4),
  checkSmall: svg('M5 12.5l4.5 4.5L19 7.5', 20, 3.4),
  chevron: svg('M6 9l6 6 6-6', 20),
  back: svg('M15 5l-7 7 7 7', 26),
  right: svg('M9 5l7 7-7 7', 26),
  more: '<svg viewBox="0 0 24 24" width="28" height="28" aria-hidden="true"><circle cx="5" cy="12" r="2.2" fill="currentColor"/><circle cx="12" cy="12" r="2.2" fill="currentColor"/><circle cx="19" cy="12" r="2.2" fill="currentColor"/></svg>',
  today: svg('M9 6h11M9 12h11M9 18h11M4 6l1 1 2-2M4 12l1 1 2-2M4 18l1 1 2-2', 26, 2),
  calendar: svg('M4 6h16v14H4zM4 10h16M8 3v4M16 3v4', 26, 2),
  plan: svg('M4 5h16v4H4zM4 11h16v4H4zM4 17h10', 26, 2),
  progress: svg('M5 20V12M12 20V5M19 20v-9', 26, 2.6),
  settings: svg('M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0M14 4v4M8 10v4M16 16v4', 26, 2),
};

const TABS = [
  ['today', 'Heute', ICON.today], ['calendar', 'Kalender', ICON.calendar], ['plan', 'Plan', ICON.plan],
  ['progress', 'Fortschritt', ICON.progress], ['settings', 'Einstellungen', ICON.settings],
];

export function tabbar() {
  return TABS.map(([id, label, icon]) => `<button class="tab${ui.tab === id ? ' on' : ''}" data-action="tab" data-tab="${id}">${icon}<span>${label}</span></button>`).join('');
}

export function topbar(v) {
  const left = v.back ? `<button class="icon-btn" data-action="back" aria-label="Zurück">${ICON.back}</button>` : '';
  const right = v.menu ? `<button class="icon-btn" data-action="sessionMenu" data-sid="${v.menu}" aria-label="Mehr">${ICON.more}</button>` : (v.right || '');
  return `<div class="tb-side">${left}</div><div class="tb-title">${esc(v.title)}</div><div class="tb-side right">${right}</div>`;
}

// ---------- Bausteine ----------

export function badge(type, size = 44) {
  return `<span class="badge" style="--c:${P.TYPE_COLORS[type]};--s:${size}px">${type}</span>`;
}

/** Fortschrittsring: gestrichelt = offen, Teilring = teilweise, voll + ✓ = erledigt, grau + ✕ = übersprungen. */
export function ring(s, size = 34) {
  const st = P.status(s);
  const c = P.TYPE_COLORS[s.type];
  const r = size / 2 - 2;
  const C = 2 * Math.PI * r;
  const m = size / 2;
  let body = `<circle cx="${m}" cy="${m}" r="${r}" fill="${c}" fill-opacity="${st === 'skipped' ? 0.08 : 0.22}"/>`;
  if (st === 'open') body += `<circle cx="${m}" cy="${m}" r="${r}" fill="none" stroke="${c}" stroke-opacity=".75" stroke-width="2" stroke-dasharray="3 3"/>`;
  if (st === 'partial') {
    body += `<circle cx="${m}" cy="${m}" r="${r}" fill="none" stroke="${c}" stroke-opacity=".25" stroke-width="3"/>`;
    body += `<circle cx="${m}" cy="${m}" r="${r}" fill="none" stroke="${c}" stroke-width="3" stroke-linecap="round" stroke-dasharray="${(C * P.progress(s)).toFixed(1)} ${C.toFixed(1)}" transform="rotate(-90 ${m} ${m})"/>`;
  }
  if (st === 'done') body += `<circle cx="${m}" cy="${m}" r="${r}" fill="none" stroke="${c}" stroke-width="3"/>`;
  if (st === 'skipped') body += `<circle cx="${m}" cy="${m}" r="${r}" fill="none" stroke="currentColor" stroke-opacity=".45" stroke-width="1.5"/>`;
  const label = st === 'done' ? '✓' : st === 'skipped' ? '✕' : s.type;
  const color = st === 'skipped' ? 'currentColor' : c;
  body += `<text x="${m}" y="${m}" text-anchor="middle" dominant-baseline="central" font-size="${(size * 0.42).toFixed(0)}" font-weight="800" fill="${color}"${st === 'skipped' ? ' fill-opacity=".5"' : ''}>${label}</text>`;
  return `<svg class="ring" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" role="img" aria-label="${s.type} ${esc(s.title)}: ${P.STATUS_LABEL[st]}">${body}</svg>`;
}

function segmented(items) {
  return `<div class="seg">${items.map((i) => `<button class="${i.active ? 'on' : ''}" data-action="${i.action}"${attrs(i.data)}>${esc(i.label)}</button>`).join('')}</div>`;
}

function sessionCard(s, { showDate = true, drag = false } = {}) {
  const st = P.status(s);
  return `<button class="scard"${drag ? ` data-drag-sid="${s.id}"` : ''} data-action="openSession" data-sid="${s.id}">
    ${badge(s.type, 42)}
    <span class="grow">
      <span class="scard-title">${esc(s.title)}</span>
      ${showDate ? `<span class="muted small">${D.fmtLong(s.date)}</span>` : ''}
      <span class="muted xsmall">Woche ${s.week} · ${P.STATUS_LABEL[st]}${s.optional ? ' · optional' : ''}</span>
    </span>
    ${ring(s, 38)}
  </button>`;
}

function infoLine(icon, text, color) {
  return `<div class="info" style="--c:${color}"><span>${icon}</span><span>${esc(text)}</span></div>`;
}

function stepper(id, value, step, opts = {}) {
  return `<div class="stepper">
    <button data-action="step" data-target="${id}" data-d="${-step}"${opts.min !== undefined ? ` data-min="${opts.min}"` : ''}>−</button>
    <input id="${id}" inputmode="${opts.decimal ? 'decimal' : 'numeric'}" value="${esc(value)}" placeholder="${esc(opts.placeholder || '')}">
    <button data-action="step" data-target="${id}" data-d="${step}">+</button>
  </div>`;
}

function weekdayPicker(selected, action) {
  return `<div class="wd-picker">${D.WD.map((n, i) => `<button class="${selected.includes(i + 1) ? 'on' : ''}" data-action="${action}" data-wd="${i + 1}">${n}</button>`).join('')}</div>`;
}

function switchRow(label, checked, field, hint = '') {
  return `<label class="row-item switch-row"><span class="grow">${esc(label)}${hint ? `<span class="muted xsmall block">${esc(hint)}</span>` : ''}</span>
    <input type="checkbox" class="switch" data-change="draft" data-field="${field}"${checked ? ' checked' : ''}></label>`;
}

// ---------- Router ----------

export function currentView() {
  if (!state.settings?.planGenerated) return onboardingView();
  const stack = ui.stacks[ui.tab];
  const top = stack[stack.length - 1];
  if (top) {
    const back = true;
    if (top.view === 'session') {
      const s = P.findSession(top.id);
      if (s) return { title: s.title, back, menu: s.id, html: sessionBody(s) };
    }
    if (top.view === 'day') return { ...dayView(top.date), back };
    if (top.view === 'week') return { ...weekView(top.week), back };
    if (top.view === 'missed') return { ...missedView(), back };
  }
  switch (ui.tab) {
    case 'calendar': return calendarView();
    case 'plan': return planView();
    case 'progress': return progressView();
    case 'settings': return settingsView();
    default: return todayView();
  }
}

// ---------- Heute ----------

function todayView() {
  const t = D.today();
  const todays = P.sessionsOn(t);
  const missed = state.sessions.filter(P.isMissed);
  const s = todays.find((x) => x.id === ui.todaySel) || todays[0];
  const wk = s ? s.week : P.currentWeek();
  const wi = P.weekInfo(wk);

  let head = `<div class="today-head"><div class="title1">${D.fmtLong(t)}</div>`;
  if (wi) {
    head += `<div class="phase" style="color:${P.phaseColor(wi.phase)}">Woche ${wk} · ${esc(P.phase(wi.phase)?.name)}</div>`;
    head += `<div class="muted">${esc(s?.optional ? 'Ruhetag – optionale Mobility für die Regeneration.' : wi.focus)}</div>`;
  }
  head += '</div>';
  if (todays.length > 1) {
    head += segmented(todays.map((x) => ({ label: x.optional ? `${x.type} · optional` : `${x.type} · ${x.title}`, active: x.id === s.id, action: 'todaySel', data: { sid: x.id } })));
  }
  if (missed.length) head += missedBanner(missed.length);

  if (s) return { title: 'Heute', menu: s.id, html: head + sessionBody(s) };

  const st = P.planState();
  const next = state.sessions.find((x) => !x.optional && !x.skipped && x.date > t);
  const texts = {
    notStarted: ['📅', 'Bald geht’s los', `Dein 12-Wochen-Plan startet am ${st.date ? D.fmtLong(st.date) : ''}.`],
    finished: ['🏆', 'Plan abgeschlossen!', 'Stark! Trage deine Benchmarks aus Woche 12 im Tab „Fortschritt“ ein und vergleiche sie mit Woche 1.'],
    running: ['🌙', 'Ruhetag', 'Erholung ist Teil des Trainings. Finger, Schultern und Kopf regenerieren lassen.'],
  }[st.kind];
  let html = head + `<div class="empty"><div class="big-emoji">${texts[0]}</div><div class="title2">${texts[1]}</div><p class="muted">${esc(texts[2])}</p></div>`;
  if (next) html += `<h3 class="section">Nächste Session</h3>${sessionCard(next)}`;
  return { title: 'Heute', html };
}

function missedBanner(n) {
  return `<button class="banner" data-action="openMissed"><span class="warn-icon">⚠️</span><span class="grow"><b>${n === 1 ? '1 verpasste Session' : `${n} verpasste Sessions`}</b><span class="muted xsmall block">Nachholen oder überspringen</span></span>${ICON.right}</button>`;
}

// ---------- Session ----------

export function sessionBody(s) {
  const st = P.status(s);
  const c = P.TYPE_COLORS[s.type];
  const ph = P.phase(s.phaseId);
  const req = P.required(s);
  const vis = P.visible(s);
  const hidden = s.exercises.length - vis.length;
  const conflicts = P.fingerConflicts(s, s.date);

  let info = '';
  if (s.optional) info += infoLine('🌿', 'Optionale Session – zählt nicht in Statistik und Serie.', '#2ecca9');
  if (s.quick) info += infoLine('⏱', 'Wenig Zeit: nur Kernübungen in Kurzform (≈ 45 min).', '#eab308');
  if (s.light) info += infoLine('🐢', 'Leichte Variante: −1 Satz pro Übung, keine Limit-Versuche.', '#2ecca9');
  if (s.checkIn) info += infoLine('❤️', `Check-in: Schlaf ${s.checkIn.sleep} · Energie ${s.checkIn.energy} · Finger ${s.checkIn.fingers}`, '#ec4899');
  if (conflicts.length) info += infoLine('⚠️', 'Weniger als 48 h Abstand zu: ' + conflicts.map((o) => `${o.type} (${D.fmtWdShort(o.date)})`).join(', '), '#f97316');
  if (P.isMissed(s)) info += infoLine('⏰', 'Verpasst – über ⋯ „Nachholen“ oder „Überspringen“.', '#f97316');

  const tile = (label, icon, color, action, active) =>
    `<button class="tile${active ? ' on' : ''}" style="--c:${color}" data-action="${action}" data-sid="${s.id}"><span class="tile-icon">${icon}</span><span>${label}</span></button>`;

  return `
  <section class="card session-head">
    <div class="row">${badge(s.type, 54)}
      <div class="grow">
        <div class="title2">${esc(s.title)}</div>
        <div class="phase" style="color:${P.phaseColor(s.phaseId)}">Woche ${s.week} · ${esc(ph?.name)}</div>
        <div class="muted small">${D.fmtLong(s.date)}</div>
      </div>${ring(s, 48)}</div>
    <div class="pbar"><div style="width:${(P.progress(s) * 100).toFixed(0)}%;background:${c}"></div></div>
    <div class="row small"><span class="status st-${st}">${P.STATUS_LABEL[st]}</span><span class="grow"></span>
      <span class="muted">${req.filter((e) => e.done).length}/${req.length} Kern · ≈ ${P.estMinutes(s)} min</span></div>
    ${info}
  </section>
  <section class="tiles">
    ${tile(s.checkIn ? 'Check-in ✓' : 'Check-in', '❤️', '#ec4899', 'openCheckIn', !!s.checkIn)}
    ${tile('Wenig Zeit', '⏱', '#eab308', 'toggleQuick', s.quick)}
    ${tile('Leichte Variante', '🐢', '#2ecca9', 'toggleLight', s.light)}
    ${tile('Verschieben', '📅', '#3b82f6', 'openMove', false)}
  </section>
  <h3 class="section">Übungen</h3>
  <section class="card list">
    ${vis.map((e) => exerciseRow(s, e)).join('')}
    <button class="add-row" data-action="addExercise" data-sid="${s.id}">＋ Eigene Übung hinzufügen</button>
  </section>
  <p class="footnote">★ = Kernübung. Die Session gilt als erledigt, sobald alle Kernübungen abgehakt sind. Übung antippen zum Aufklappen (Sätze, Notiz, Tauschen).${hidden ? ` ${hidden} Übung(en) ausgeblendet (Wenig Zeit bzw. keine Limit-Versuche).` : ''}</p>
  <h3 class="section">Notizen zur Session</h3>
  <textarea class="notes" rows="3" data-input="sessionNotes" data-sid="${s.id}" placeholder="Wie lief’s? Beta, Gefühl, Gewichte …">${esc(s.notes)}</textarea>`;
}

function exerciseRow(s, e) {
  const open = ui.expanded.has(e.id);
  const n = P.effSets(e, s);
  const c = P.TYPE_COLORS[s.type];
  let more = '';
  if (open) {
    const sets = n > 1
      ? `<div class="muted xsmall label">Sätze abhaken</div><div class="sets">${Array.from({ length: n }, (_, i) => {
        const on = e.done || e.setsDone[i];
        return `<button class="setbtn${on ? ' on' : ''}" style="--c:${c}" data-action="toggleSet" data-sid="${s.id}" data-eid="${e.id}" data-i="${i}">${on ? ICON.checkSmall : i + 1}</button>`;
      }).join('')}</div>`
      : '';
    more = `<div class="ex-more">
      ${e.info ? `<p class="ex-info">${esc(e.info)}</p>` : ''}
      ${sets}
      <textarea class="notes small-notes" rows="2" data-input="exNotes" data-sid="${s.id}" data-eid="${e.id}" placeholder="Notiz (Gewicht, Gefühl, Beta …)">${esc(e.notes)}</textarea>
      <div class="btn-row">
        <button class="small-btn" data-action="editExercise" data-sid="${s.id}" data-eid="${e.id}">✏️ Bearbeiten</button>
        <button class="small-btn" data-action="swapExercise" data-sid="${s.id}" data-eid="${e.id}">⇄ Tauschen</button>
        ${e.benchmark ? `<button class="small-btn" data-action="openBench" data-kind="${e.benchmark}" data-week="${s.week >= 12 ? 12 : 1}">🏆 Ergebnis</button>` : ''}
        <button class="small-btn danger" data-action="deleteExercise" data-sid="${s.id}" data-eid="${e.id}">🗑</button>
      </div>
    </div>`;
  }
  return `<div class="ex${e.done ? ' done' : ''}">
    <div class="ex-top">
      <button class="check${e.done ? ' on' : ''}" style="--c:${c}" data-action="toggleEx" data-sid="${s.id}" data-eid="${e.id}" aria-label="${esc(e.name)} abhaken">${ICON.check}</button>
      <button class="ex-main" data-action="expand" data-eid="${e.id}">
        <span class="ex-name">${esc(e.name)}${e.core ? ' <span class="star">★</span>' : ''}${e.benchmark ? ' 🏆' : ''}</span>
        <span class="ex-pres">${esc(P.prescription(e, s))}</span>
        ${n > 1 ? `<span class="ex-sets" style="color:${c}">${P.doneSets(e, s)}/${n} Sätze</span>` : ''}
      </button>
      <span class="chev${open ? ' open' : ''}">${ICON.chevron}</span>
    </div>${more}
  </div>`;
}

// ---------- Verpasst / Tag / Woche ----------

function missedView() {
  const missed = state.sessions.filter(P.isMissed);
  let html = '';
  if (!missed.length) html = `<div class="empty"><div class="big-emoji">✅</div><div class="title2">Alles im Plan</div><p class="muted">Keine verpassten Sessions.</p></div>`;
  html += missed.map((s) => `<div class="card">
      ${sessionCard(s)}
      <div class="btn-row">
        <button class="btn primary" style="--c:${P.TYPE_COLORS[s.type]}" data-action="makeUp" data-sid="${s.id}">Nachholen</button>
        <button class="btn" data-action="skipSession" data-sid="${s.id}">Überspringen</button>
      </div></div>`).join('');
  if (missed.length > 1) html += `<button class="btn danger wide" data-action="skipAllMissed">Alle überspringen</button>`;
  html += `<p class="footnote">„Nachholen“ legt die Session in die nächste freie Lücke ab heute – ohne 48-h-Konflikt mit anderen Fingersessions.</p>`;
  return { title: 'Verpasste Sessions', html };
}

function dayView(date) {
  const list = P.sessionsOn(date);
  if (list.length === 1) return { title: D.fmtWdShort(date), menu: list[0].id, html: sessionBody(list[0]) };
  if (!list.length) return { title: D.fmtWdShort(date), html: `<div class="empty"><div class="big-emoji">🌙</div><div class="title2">Ruhetag</div><p class="muted">${D.fmtLong(date)}: keine Session geplant.</p></div>` };
  return { title: D.fmtWdShort(date), html: `<h3 class="section">${D.fmtLong(date)}</h3>` + list.map((s) => sessionCard(s, { showDate: false })).join('') };
}

function weekView(week) {
  const wi = P.weekInfo(week);
  const ph = P.phase(wi.phase);
  const list = state.sessions.filter((s) => s.week === week);
  const main = list.filter((s) => !s.optional);
  const opt = list.filter((s) => s.optional);
  let html = `<section class="card"><div class="phase" style="color:${P.phaseColor(wi.phase)}">${esc(ph.name)}</div><p>${esc(wi.focus)}</p><p class="muted small">${esc(ph.description)}</p></section>`;
  html += `<h3 class="section">Sessions</h3>` + main.map((s) => sessionCard(s)).join('');
  if (opt.length) html += `<h3 class="section">Optional: Mobility</h3>` + opt.map((s) => sessionCard(s)).join('');
  html += `<button class="btn danger wide" data-action="skipWeek" data-week="${week}">Woche überspringen</button>
    <p class="footnote">Markiert alle noch offenen Sessions dieser Woche als übersprungen (z. B. bei Krankheit oder Urlaub). Um den ganzen Plan zu verschieben, nutze „Plan pausieren“ in den Einstellungen.</p>`;
  return { title: `Woche ${week}`, html };
}

// ---------- Kalender ----------

function calendarView() {
  const c = ui.cal;
  let html = segmented([
    { label: 'Monat', active: c.mode === 'month', action: 'calMode', data: { mode: 'month' } },
    { label: 'Woche', active: c.mode === 'week', action: 'calMode', data: { mode: 'week' } },
  ]);
  const monday = D.mondayOf(c.anchor);
  const title = c.mode === 'month'
    ? D.fmtMonthYear(c.anchor)
    : `KW ${D.isoWeekNumber(monday)} · ${D.fmtShort(monday)} – ${D.fmtShort(D.addDays(monday, 6))}`;
  html += `<div class="cal-nav"><button class="icon-btn" data-action="calStep" data-dir="-1" aria-label="Zurück">${ICON.back}</button>
    <div class="cal-title">${esc(title)}</div>
    <button class="icon-btn" data-action="calStep" data-dir="1" aria-label="Weiter">${ICON.right}</button></div>`;
  html += c.mode === 'month' ? monthGrid(c.anchor) + legend() : weekPlanner(monday);
  return { title: 'Kalender', right: `<button class="text-btn" data-action="calToday">Heute</button>`, html };
}

function monthGrid(anchor) {
  const first = D.firstOfMonth(anchor);
  const start = D.mondayOf(first);
  const end = D.addDays(D.mondayOf(D.lastOfMonth(anchor)), 6);
  const t = D.today();
  const month = anchor.slice(0, 7);
  let cells = '';
  for (let d = start; d <= end; d = D.addDays(d, 1)) {
    const list = P.sessionsOn(d);
    const main = list.filter((s) => !s.optional);
    const opt = list.some((s) => s.optional);
    const content = main.length ? ring(main[0], 32) : opt ? '<span class="dot"></span>' : '<span class="ring-ph"></span>';
    cells += `<button class="day${d.slice(0, 7) === month ? '' : ' out'}${d === t ? ' today' : ''}" data-action="openDay" data-date="${d}">
      <span class="dnum">${Number(d.slice(8))}</span>${content}${main.length > 1 ? `<span class="plus">+${main.length - 1}</span>` : ''}</button>`;
  }
  return `<div class="month" data-swipe="month"><div class="wd-head">${D.WD.map((w) => `<span>${w}</span>`).join('')}</div><div class="grid7">${cells}</div></div>`;
}

function legend() {
  const types = ['A', 'B', 'C', 'D', 'E', 'T'].map((t) => `<span class="leg">${badge(t, 22)} ${esc(P.typeTitle(t))}</span>`).join('');
  return `<section class="card legend"><div class="title3">Legende</div><div class="leg-grid">${types}</div>
    <div class="leg-grid small muted"><span><b>Offen</b> – gestrichelter Ring</span><span><b>Teilweise</b> – Teilring</span>
    <span><b>Erledigt</b> – voller Ring + ✓</span><span><b>Übersprungen</b> – grau + ✕</span><span><span class="dot inline"></span> optionale Mobility</span></div></section>`;
}

function weekPlanner(monday) {
  const t = D.today();
  let html = `<p class="footnote">☝️ Session gedrückt halten und auf einen anderen Tag ziehen, um sie zu verschieben.</p>`;
  for (let i = 0; i < 7; i++) {
    const d = D.addDays(monday, i);
    const list = P.sessionsOn(d);
    html += `<div class="dayblock${d === t ? ' today' : ''}" data-drop-date="${d}">
      <button class="day-head" data-action="openDay" data-date="${d}"><b>${D.fmtLong(d)}</b>${d === t ? '<span class="pill">Heute</span>' : ''}<span class="grow"></span>${ICON.right}</button>
      ${list.length ? list.map((s) => sessionCard(s, { showDate: false, drag: true })).join('') : '<div class="muted small rest">Ruhetag</div>'}
    </div>`;
  }
  return html;
}

// ---------- Plan ----------

function planView() {
  const cur = P.currentWeek();
  const total = P.totalWeeks();
  const main = state.sessions.filter((s) => !s.optional);
  const curPhase = P.weekInfo(Math.min(Math.max(cur, 1), total));
  let html = `<section class="card"><div class="title3">${esc(P.seed.name)}</div>
    ${cur > total ? '<p>Plan abgeschlossen – Zeit für den Vergleich der Benchmarks! 🎉</p>'
      : `<div class="phase" style="color:${P.phaseColor(curPhase.phase)}">Aktuell: Woche ${Math.max(cur, 1)} von ${total} · ${esc(P.phase(curPhase.phase)?.name)}</div>`}
    <div class="pbar"><div style="width:${(Math.min(Math.max(cur - 1, 0), total) / total) * 100}%;background:var(--accent)"></div></div>
    ${main.length ? `<div class="muted small">${D.fmtDMY(main[0].date)} – ${D.fmtDMY(main[main.length - 1].date)}</div>` : ''}</section>`;

  for (const block of P.phaseBlocks()) {
    const color = P.colorNamed(block.phase.color);
    const range = block.weeks.length > 1 ? `Woche ${block.weeks[0]}–${block.weeks[block.weeks.length - 1]}` : `Woche ${block.weeks[0]}`;
    html += `<div class="phase-head"><span class="pdot" style="background:${color}"></span><b style="color:${color}">${esc(block.phase.name)}</b><span class="grow"></span><span class="muted xsmall">${range}</span></div>
      <p class="muted xsmall phase-desc">${esc(block.phase.description)}</p><section class="card list">`;
    for (const w of block.weeks) {
      const list = state.sessions.filter((s) => s.week === w);
      const rel = list.filter((s) => !s.optional && !s.skipped);
      const rate = rel.length ? rel.filter(P.isDone).length / rel.length : 0;
      const dates = list.map((s) => s.date).sort();
      const range2 = dates.length ? `${D.fmtWdShort(dates[0])} – ${D.fmtWdShort(dates[dates.length - 1])}` : '';
      html += `<button class="week-row${w === cur ? ' current' : ''}" style="--c:${color}" data-action="openWeek" data-week="${w}" id="week-${w}">
        <span class="grow">
          <span class="row"><b>Woche ${w}</b>${w === cur ? '<span class="pill" style="background:var(--c)">AKTUELL</span>' : ''}</span>
          <span class="muted xsmall block">${range2}</span>
          <span class="muted small block">${esc(P.weekInfo(w).focus)}</span>
          <span class="rings">${list.filter((s) => !s.optional).map((s) => ring(s, 26)).join('')}</span>
        </span>
        <span class="pct${rate >= 1 ? ' full' : ''}">${Math.round(rate * 100)} %</span>
      </button>`;
    }
    html += '</section>';
  }
  return { title: '12-Wochen-Plan', html, scrollTo: cur >= 1 && cur <= total ? `week-${cur}` : null };
}

// ---------- Fortschritt ----------

function progressView() {
  const st = P.streaks();
  const tot = P.totals();
  const rate = tot.due ? `${Math.round((tot.done / tot.due) * 100)} %` : '–';
  const stats = P.weekStats(P.currentWeek());
  const hb = state.settings.hasHangboard;
  const statTile = (label, value, sub, color) => `<div class="stat"><div class="stat-label" style="color:${color}">${label}</div><div class="stat-value">${value}</div><div class="muted xsmall">${sub}</div></div>`;

  let html = `<div class="stats">
    ${statTile('🔥 Serie', st.current, 'Sessions in Folge', '#f97316')}
    ${statTile('🏆 Rekord', st.longest, 'längste Serie', '#eab308')}
    ${statTile('✅ Erledigt', tot.done, `von ${tot.due} fälligen`, '#22c55e')}
    ${statTile('📈 Quote', rate, 'Abschluss bisher', '#3b82f6')}
  </div>
  <section class="card"><div class="title3">Abschlussquote pro Woche</div>
    <div class="chart">${stats.map((s) => `<div class="col">
      <div class="val">${s.total && !s.future ? Math.round(s.rate * 100) : ''}</div>
      <div class="barwrap"><div class="barfill" style="height:${Math.max(s.rate * 100, s.total && !s.future ? 2 : 0)}%;background:${s.color};opacity:${s.future ? 0.35 : 1}"></div></div>
      <div class="lbl">${s.week}</div></div>`).join('')}</div>
    <p class="muted xsmall">Farbe = Phase. Optionale und übersprungene Sessions zählen nicht.</p></section>
  <section class="card"><div class="title3">Benchmarks: Woche 1 vs. 12</div>`;
  const kinds = Object.keys(P.BENCH);
  kinds.forEach((k, i) => {
    const b = P.BENCH[k];
    const a = P.benchResult(k, 1);
    const z = P.benchResult(k, 12);
    const delta = P.benchDelta(k, a, z);
    html += `<div class="bench">
      <div class="bench-title">${b.icon} ${esc(b.title(hb))}</div>
      <div class="row">
        <button class="bench-val" data-action="openBench" data-kind="${k}" data-week="1"><span class="muted xsmall">Woche 1</span><b>${esc(P.benchDisplay(a, k))}</b></button>
        <span class="muted">→</span>
        <button class="bench-val" data-action="openBench" data-kind="${k}" data-week="12"><span class="muted xsmall">Woche 12</span><b>${esc(P.benchDisplay(z, k))}</b></button>
        <span class="grow"></span>
        ${delta ? `<b class="${delta.positive ? 'pos' : 'neg'}">${esc(delta.text)}</b>` : ''}
      </div></div>${i < kinds.length - 1 ? '<hr>' : ''}`;
  });
  html += `<p class="muted xsmall">Getestet wird in Woche 1 und 12 in den Sessions A (Max Hang, Moonboard, 3RM) und C (Kilter). Wert antippen zum Eintragen.</p></section>`;
  return { title: 'Fortschritt', html };
}

// ---------- Einstellungen & Onboarding ----------

function planFields(d) {
  const warnings = P.layoutWarnings(d.weekdays, d.daysPerWeek).map((w) => `<div class="warn small">⚠️ ${esc(w)}</div>`).join('');
  return `
    <label class="row-item"><span class="grow">Startdatum</span><input type="date" data-change="draft" data-field="startDate" value="${d.startDate}"></label>
    <div class="row-item"><span class="grow muted">Woche 1 beginnt</span><span>${D.fmtLong(D.mondayOf(d.startDate))}</span></div>
    <div class="row-item col"><span class="small">Trainingstage pro Woche</span>
      ${segmented([3, 4, 5].map((n) => ({ label: `${n} Tage`, active: d.daysPerWeek === n, action: 'draftDays', data: { n } })))}
      <span class="small">Wochentage (${d.weekdays.length}/${d.daysPerWeek})</span>
      ${weekdayPicker(d.weekdays, 'draftWd')}
      <span class="muted xsmall">${esc(P.layoutPreview(d.weekdays, d.daysPerWeek))}</span>${warnings}
    </div>
    ${switchRow('Hangboard vorhanden', d.hasHangboard, 'hasHangboard', 'Ohne Hangboard: Max Hangs → Moonboard-Halteübungen')}
    ${switchRow('Kommerzielle Boulderhalle verfügbar', d.hasGym, 'hasGym', 'Volumen, Technik & Circuits teils in der Halle, optional freies Bouldern nach Session B')}
    ${switchRow('Mobility (E) an freien Tagen', d.showMobility, 'showMobility', 'Optionale 20-min-Session, zählt nicht in die Statistik')}`;
}

function onboardingView() {
  const d = ui.draft;
  const valid = d.weekdays.length === d.daysPerWeek;
  const html = `
  <div class="welcome"><div class="big-emoji">🧗</div><div class="title1">Willkommen bei Boulder Plan</div>
    <p class="muted">12 Wochen periodisiertes Bouldertraining – von 7a+ Richtung 7b/7b+: Basis, Maximalkraft, Power und Testwoche. Lege fest, wann du trainierst; der Kalender wird automatisch erstellt.</p></div>
  <section class="card form">${planFields(d)}</section>
  <p class="footnote">A = Limit & Finger · B = Kraft & Antagonisten · C = Kilter Power · D = Kraftausdauer · T = Technik (nur bei 5 Tagen). Vorausgesetzt: Kilter, Moonboard, Klimmzugstange, Gewichte, Hantelbank, Dip-Barren, Ringe.</p>
  <p class="footnote">Mit Halle: Woche 1–4 läuft das 4×4 (D) an Hallenbouldern in gemischten Stilen, in der Power-Phase werden Linked Boulders zu Hallen-Circuits und C bekommt Koordinations-Boulder. Der Technik-Tag (T) findet in der Halle statt, und nach B gibt es optional einen Block „Freies Bouldern“ (nicht in Deload- und Testwochen). Die Finger-Einheiten A und C bleiben am Board.</p>
  <button class="btn primary wide big" data-action="createPlan"${valid ? '' : ' disabled'}>Plan erstellen</button>
  <p class="footnote">Deine Daten bleiben ausschließlich auf diesem Gerät gespeichert.</p>`;
  return { title: 'Boulder Plan', html, noTabs: true };
}

function settingsChanged(d, s) {
  return D.mondayOf(d.startDate) !== D.mondayOf(s.startDate) || d.daysPerWeek !== s.daysPerWeek
    || [...d.weekdays].sort().join() !== [...s.weekdays].sort().join()
    || d.hasHangboard !== s.hasHangboard || d.showMobility !== s.showMobility || !!d.hasGym !== !!s.hasGym;
}

function settingsView() {
  const s = state.settings;
  const d = ui.draft;
  const canApply = settingsChanged(d, s) && d.weekdays.length === d.daysPerWeek;
  const html = `
  <h3 class="section">Plan</h3>
  <section class="card form">${planFields(d)}
    <button class="btn primary wide" data-action="applySettings"${canApply ? '' : ' disabled'}>Änderungen übernehmen</button>
  </section>
  <p class="footnote">Beim Übernehmen werden zukünftige, noch nicht begonnene Sessions neu erstellt. Ein neues Startdatum erstellt den ganzen Plan neu (Benchmarks bleiben).</p>
  <p class="footnote">Halle: D läuft in Woche 1–4 als Hallen-4×4, in der Power-Phase als Hallen-Circuits. C bekommt in der Power-Phase Koordinations-Boulder, T findet in der Halle statt, und nach B gibt es optional „Freies Bouldern“ (zählt nicht für „erledigt“). A und C bleiben am Board. Moonboard-Limit-Boulder lassen sich einzeln gegen „Hallen-Limit-Boulder“ tauschen.</p>

  <h3 class="section">Krank / Urlaub</h3>
  <section class="card form">
    <div class="row-item"><span class="grow">Pausieren um (Tage)</span>${stepper('pause-days', d.pauseDays, 1, { min: 1 })}</div>
    <button class="btn wide" data-action="pausePlan">⏸ Plan pausieren & verschieben</button>
    ${s.shiftDays ? `<div class="row-item"><span class="grow muted">Bisher verschoben</span><span>${s.shiftDays} Tage</span></div>` : ''}
  </section>
  <p class="footnote">Verschiebt alle offenen Sessions ab heute. Einzelne Wochen überspringst du im Tab „Plan“, verpasste Sessions holst du im Tab „Heute“ nach.</p>

  <h3 class="section">Erinnerungen</h3>
  <section class="card form">
    <label class="row-item"><span class="grow">Uhrzeit</span><input type="time" data-change="reminderTime" value="${esc(s.reminderTime || '17:30')}"></label>
    <button class="btn wide" data-action="icsShare">🔔 Trainingstage in Kalender übernehmen</button>
    <button class="btn wide" data-action="icsOpen">Kalenderdatei direkt öffnen</button>
  </section>
  <p class="footnote">Web-Apps können auf dem iPhone ohne Server keine Erinnerungen planen. Stattdessen erzeugt die App eine Kalenderdatei mit allen offenen Trainingstagen und Hinweis zur gewählten Uhrzeit – die iOS-Kalender-App erinnert dich dann. Nach größeren Plan-Änderungen erneut übernehmen (alte Termine ggf. vorher löschen).</p>

  <h3 class="section">Darstellung</h3>
  <section class="card form">
    <label class="row-item"><span class="grow">Design</span>
      <select data-change="theme"><option value="dark"${s.theme !== 'system' ? ' selected' : ''}>Immer dunkel</option><option value="system"${s.theme === 'system' ? ' selected' : ''}>Wie System</option></select></label>
  </section>

  <h3 class="section">Daten</h3>
  <section class="card form">
    <button class="btn wide" data-action="exportData">⬆️ Fortschritt exportieren (JSON)</button>
    <button class="btn wide" data-action="importData">⬇️ Fortschritt importieren (JSON)</button>
    <button class="btn danger wide" data-action="regenerate">Plan komplett neu erstellen</button>
  </section>
  <p class="footnote">Alle Daten liegen nur lokal in dieser Web-App auf deinem iPhone. Exportiere regelmäßig ein Backup (z. B. in „Dateien“ oder iCloud Drive). Wichtig: Die App immer über das Home-Bildschirm-Symbol öffnen – Safari selbst hat einen eigenen, getrennten Speicher.</p>

  <h3 class="section">Info</h3>
  <section class="card form">
    <div class="row-item"><span class="grow muted">Plan</span><span class="small">${esc(P.seed.name)}</span></div>
    <div class="row-item"><span class="grow muted">Seed-Version</span><span>${P.seed.version}</span></div>
  </section>`;
  return { title: 'Einstellungen', html };
}

// ---------- Sheets ----------

export function sheetHTML() {
  const sh = ui.sheet;
  if (!sh) return '';
  let inner = '';
  switch (sh.type) {
    case 'checkin': inner = checkInSheet(sh); break;
    case 'move': inner = moveSheet(sh); break;
    case 'edit': inner = editSheet(sh); break;
    case 'swap': inner = swapSheet(sh); break;
    case 'bench': inner = benchSheet(sh); break;
    case 'confirm': inner = confirmSheet(sh); break;
    default: inner = '';
  }
  return `<div class="backdrop" data-action="closeSheet"></div><div class="sheet" role="dialog" aria-modal="true">${inner}</div>`;
}

function sheetHead(title, right = '') {
  return `<div class="sheet-head"><button class="text-btn" data-action="closeSheet">Abbrechen</button><b>${esc(title)}</b><span>${right}</span></div>`;
}

function checkInSheet(sh) {
  const v = sh.v;
  const low = Math.min(v.sleep, v.energy, v.fingers) <= 2 || (v.sleep + v.energy + v.fingers) / 3 < 2.7;
  const colors = ['#ef4444', '#f97316', '#eab308', '#22c55e', '#2ecca9'];
  const row = (key, label) => `<div class="rate"><b>${label}</b><div class="rate-row">${[1, 2, 3, 4, 5].map((n) =>
    `<button class="${v[key] === n ? 'on' : ''}" style="--c:${colors[n - 1]}" data-action="rate" data-k="${key}" data-n="${n}">${n}</button>`).join('')}</div></div>`;
  return `${sheetHead('Check-in')}
    <div class="sheet-body">
      <p class="muted">Wie fühlst du dich heute? 1 = sehr schlecht, 5 = top.</p>
      ${row('sleep', '😴 Schlaf')}${row('energy', '⚡ Energie')}${row('fingers', '✋ Fingergefühl')}
      <div class="card reco">${low
        ? '<b>🐢 Empfehlung: leichtere Variante</b><p class="muted small">−1 Satz pro Übung und keine Limit-Versuche. Qualität vor Quantität – Finger schonen.</p>'
        : '<b>🔥 Bereit für volles Training</b><p class="muted small">Gute Werte – trainiere nach Plan.</p>'}</div>
      <button class="btn primary wide big" data-action="applyCheckIn" data-light="${low ? 1 : 0}">${low ? 'Leichte Variante verwenden' : 'Normal trainieren'}</button>
      <button class="btn wide" data-action="applyCheckIn" data-light="${low ? 0 : 1}">${low ? 'Trotzdem normal trainieren' : 'Leichte Variante wählen'}</button>
    </div>`;
}

function moveSheet(sh) {
  const s = P.findSession(sh.sid);
  const days = P.weekDates(s.week, state.settings);
  if (sh.pending) {
    const list = P.fingerConflicts(s, sh.pending).map((o) => `<li>${o.type} – ${esc(o.title)} am ${D.fmtWdShort(o.date)}</li>`).join('');
    return `${sheetHead('Weniger als 48 h Erholung')}<div class="sheet-body">
      <p>Fingerintensive Sessions (A, C) sollten mindestens 48 h auseinanderliegen:</p><ul>${list}</ul>
      <button class="btn danger wide big" data-action="confirmMove">Trotzdem auf ${D.fmtWdShort(sh.pending)} verschieben</button>
      <button class="btn wide" data-action="cancelPending">Anderen Tag wählen</button></div>`;
  }
  const rows = days.map((d) => {
    const others = P.sessionsOn(d).filter((o) => o.id !== s.id && !o.optional);
    const cur = d === s.date;
    const conflict = !cur && P.fingerConflicts(s, d).length > 0;
    return `<button class="move-row" data-action="moveTo" data-date="${d}">
      <span class="grow"><b>${D.fmtLong(d)}</b><span class="muted xsmall block">${others.length ? 'Bereits: ' + others.map((o) => `${o.type} ${esc(o.title)}`).join(', ') : 'frei'}</span></span>
      ${cur ? '<span class="pill" style="background:var(--field);color:var(--text)">aktuell</span>' : conflict ? '<span>⚠️</span>' : ICON.right}</button>`;
  }).join('');
  return `${sheetHead(`${s.type} verschieben`)}<div class="sheet-body"><div class="muted small">Trainingswoche ${s.week}</div><div class="card list">${rows}</div>
    <p class="footnote">Sessions lassen sich innerhalb ihrer Trainingswoche verschieben. Für spätere Termine nutze „Nachholen“ im ⋯-Menü.</p></div>`;
}

function editSheet(sh) {
  const s = P.findSession(sh.sid);
  const e = sh.eid ? s.exercises.find((x) => x.id === sh.eid) : null;
  const v = e || { name: '', info: '', sets: 3, reps: '8', rest: 120, intensity: '', weight: null, minutes: 10, core: false, notes: '' };
  return `${sheetHead(e ? 'Übung bearbeiten' : 'Eigene Übung', `<button class="text-btn strong" data-action="saveExercise">Sichern</button>`)}
  <div class="sheet-body form">
    <label class="field"><span>Name</span><input id="f-name" value="${esc(v.name)}" placeholder="z. B. Pinch-Block"></label>
    <label class="field"><span>Beschreibung / Ausführung</span><textarea id="f-info" rows="3">${esc(v.info)}</textarea></label>
    <label class="row-item switch-row"><span class="grow">Kernübung ★</span><input type="checkbox" class="switch" id="f-core"${v.core ? ' checked' : ''}></label>
    <div class="row-item"><span class="grow">Sätze</span>${stepper('f-sets', v.sets, 1, { min: 1 })}</div>
    <label class="field"><span>Wiederholungen / Dauer</span><input id="f-reps" value="${esc(v.reps)}" placeholder="z. B. 8–10 oder 10 s"></label>
    <div class="row-item"><span class="grow">Pause (Sek.)</span>${stepper('f-rest', v.rest, 15, { min: 0 })}</div>
    <label class="field"><span>Intensität</span><input id="f-intensity" value="${esc(v.intensity)}" placeholder="Grad, RPE …"></label>
    <div class="row-item"><span class="grow">Zusatzgewicht (kg)<span class="muted xsmall block">leer = keins, negativ = Entlastung</span></span>${stepper('f-weight', v.weight ?? '', 1.25, { decimal: true, placeholder: '–' })}</div>
    <div class="row-item"><span class="grow">Dauer (min)</span>${stepper('f-minutes', v.minutes, 5, { min: 1 })}</div>
    <label class="field"><span>Notiz</span><textarea id="f-notes" rows="2">${esc(v.notes)}</textarea></label>
  </div>`;
}

function swapSheet(sh) {
  const s = P.findSession(sh.sid);
  const e = s.exercises.find((x) => x.id === sh.eid);
  const item = (key) => {
    const ex = P.seed.exercises[key];
    if (!ex) return '';
    return `<button class="swap-item" data-action="doSwap" data-key="${key}" data-name="${esc(ex.name.toLowerCase())}"><b>${esc(ex.name)}</b><span class="muted xsmall block clamp">${esc(ex.description)}</span></button>`;
  };
  const alts = e.alternatives.filter((k) => P.seed.exercises[k]);
  let body = `<input class="search" data-input="swapSearch" placeholder="Übung suchen" type="search">`;
  if (alts.length) body += `<div class="swap-group" data-group="alts"><div class="muted small label">Empfohlene Alternativen</div><div class="card list">${alts.map(item).join('')}</div></div>`;
  for (const g of P.libraryGroups()) {
    const items = g.items.filter((i) => i.key !== e.key);
    if (items.length) body += `<div class="swap-group"><div class="muted small label">${esc(g.title)}</div><div class="card list">${items.map((i) => item(i.key)).join('')}</div></div>`;
  }
  return `${sheetHead(`${e.name} tauschen`)}<div class="sheet-body">${body}</div>`;
}

function benchSheet(sh) {
  const b = P.BENCH[sh.kind];
  const hb = state.settings.hasHangboard;
  const field = b.grade
    ? `<label class="row-item"><span class="grow">Grad (Fb)</span><select id="b-grade">${P.GRADES.map((g) => `<option${g === sh.grade ? ' selected' : ''}>${g}</option>`).join('')}</select></label>`
    : `<div class="row-item"><span class="grow">Zusatzgewicht (kg)</span>${stepper('b-value', sh.value ?? 0, 1.25, { decimal: true })}</div>`;
  return `${sheetHead(b.title(hb), `<button class="text-btn strong" data-action="saveBench">Sichern</button>`)}
  <div class="sheet-body form">
    <p class="small">${esc(b.instr(hb))}</p>
    ${segmented([1, 12].map((w) => ({ label: `Woche ${w}`, active: sh.week === w, action: 'benchWeek', data: { week: w } })))}
    ${field}
    <label class="field"><span>Notiz</span><textarea id="b-note" rows="2" placeholder="z. B. Griffposition, Problemname">${esc(sh.note || '')}</textarea></label>
  </div>`;
}

function confirmSheet(sh) {
  return `<div class="sheet-body confirm">
    ${sh.title ? `<div class="title3">${esc(sh.title)}</div>` : ''}
    ${sh.message ? `<p class="muted">${esc(sh.message)}</p>` : ''}
    ${sh.buttons.map((b, i) => `<button class="btn wide ${b.style || ''}" data-action="sheetBtn" data-i="${i}">${esc(b.label)}</button>`).join('')}
    ${sh.noCancel ? '' : '<button class="btn wide ghost" data-action="closeSheet">Abbrechen</button>'}
  </div>`;
}
