// Reiner UI-Zustand (wird nicht gespeichert).
import { today } from './dates.js';

export const ui = {
  tab: 'today',
  /** Navigationsstapel je Tab: [{ view: 'session'|'day'|'week'|'missed', ... }] */
  stacks: { today: [], calendar: [], plan: [], progress: [], settings: [] },
  /** Aufgeklappte Übungen. */
  expanded: new Set(),
  /** Gewählte Session, falls heute mehrere anstehen. */
  todaySel: null,
  cal: { mode: 'month', anchor: today() },
  /** Offenes Bottom-Sheet. */
  sheet: null,
  /** Entwurf der Einstellungen bzw. des Onboardings. */
  draft: null,
};
