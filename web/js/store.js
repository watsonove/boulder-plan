// Lokale Speicherung im Browser (localStorage). Kein Server – alles bleibt auf dem Gerät.

const KEY = 'boulderplan.v1';

/** Gesamter App-Zustand. */
export const state = {
  settings: null, // wird im Onboarding angelegt
  sessions: [],
  benchmarks: [],
};

export function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) Object.assign(state, JSON.parse(raw));
  } catch (err) {
    console.error('Daten konnten nicht geladen werden', err);
  }
}

let saveFailed = false;
export function save() {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
    saveFailed = false;
  } catch (err) {
    console.error('Speichern fehlgeschlagen', err);
    if (!saveFailed) alert('Speichern fehlgeschlagen – ist der Speicher voll oder der private Modus aktiv?');
    saveFailed = true;
  }
}

/** Speichern mit kurzer Verzögerung (für Texteingaben). */
let timer = null;
export function saveSoon() {
  clearTimeout(timer);
  timer = setTimeout(save, 400);
}

export function uid() {
  if (globalThis.crypto?.randomUUID) return crypto.randomUUID();
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 10);
}
