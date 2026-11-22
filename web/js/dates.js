// Datums-Helfer. Alle Tage werden als 'YYYY-MM-DD'-Strings gespeichert und in UTC gerechnet –
// so gibt es keine Probleme mit Zeitzonen oder Sommerzeit.

export const pad = (n) => String(n).padStart(2, '0');

export function toUTC(ds) {
  const [y, m, d] = ds.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

export function fromUTC(dt) {
  return `${dt.getUTCFullYear()}-${pad(dt.getUTCMonth() + 1)}-${pad(dt.getUTCDate())}`;
}

/** Heutiges lokales Datum. */
export function today() {
  const n = new Date();
  return `${n.getFullYear()}-${pad(n.getMonth() + 1)}-${pad(n.getDate())}`;
}

export function addDays(ds, n) {
  const d = toUTC(ds);
  d.setUTCDate(d.getUTCDate() + n);
  return fromUTC(d);
}

export function addMonths(ds, n) {
  const d = toUTC(ds);
  return fromUTC(new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + n, 1)));
}

/** ISO-Wochentag: 1 = Montag … 7 = Sonntag. */
export function isoWeekday(ds) {
  const w = toUTC(ds).getUTCDay();
  return w === 0 ? 7 : w;
}

export const mondayOf = (ds) => addDays(ds, -(isoWeekday(ds) - 1));
export const daysBetween = (a, b) => Math.round((toUTC(b) - toUTC(a)) / 86400000);

export function nextMondayOrToday() {
  const t = today();
  return isoWeekday(t) === 1 ? t : addDays(mondayOf(t), 7);
}

export function firstOfMonth(ds) {
  return ds.slice(0, 8) + '01';
}

export function lastOfMonth(ds) {
  return addDays(addMonths(ds, 1), -1);
}

export function isoWeekNumber(ds) {
  const d = toUTC(ds);
  d.setUTCDate(d.getUTCDate() + 4 - isoWeekday(ds));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
}

const fmt = (opts) => new Intl.DateTimeFormat('de-DE', { ...opts, timeZone: 'UTC' });
const F = {
  long: fmt({ weekday: 'long', day: 'numeric', month: 'long' }),
  wdShort: fmt({ weekday: 'short', day: 'numeric', month: 'numeric' }),
  short: fmt({ day: 'numeric', month: 'numeric' }),
  dmy: fmt({ day: 'numeric', month: 'short', year: 'numeric' }),
  monthYear: fmt({ month: 'long', year: 'numeric' }),
};

/** "Montag, 24. November" */
export const fmtLong = (ds) => F.long.format(toUTC(ds));
/** "Mo., 24.11." */
export const fmtWdShort = (ds) => F.wdShort.format(toUTC(ds));
/** "24.11." */
export const fmtShort = (ds) => F.short.format(toUTC(ds)) + (F.short.format(toUTC(ds)).endsWith('.') ? '' : '.');
/** "24. Nov. 2026" */
export const fmtDMY = (ds) => F.dmy.format(toUTC(ds));
/** "November 2026" */
export const fmtMonthYear = (ds) => F.monthYear.format(toUTC(ds));

export const WD = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/** 45 → "45 s", 120 → "2 min", 90 → "1:30 min" */
export function restText(sec) {
  if (sec < 60) return `${sec} s`;
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return s === 0 ? `${m} min` : `${m}:${pad(s)} min`;
}

/** 12.5 → "12,5" */
export const num = (v) => Number(v).toLocaleString('de-DE', { maximumFractionDigits: 2 });

/** "12,5" oder "12.5" → 12.5; leer → null */
export function parseNum(v) {
  if (v === null || v === undefined) return null;
  const s = String(v).trim().replace(',', '.');
  if (s === '' || s === '-') return null;
  const n = parseFloat(s);
  return Number.isFinite(n) ? n : null;
}
