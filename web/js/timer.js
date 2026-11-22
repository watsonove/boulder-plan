// Pausen- und Intervall-Timer als reine Rechenlogik (ohne DOM, testbar).
// Alle Zeiten sind absolute Zeitstempel in ms. Eine neue Phase beginnt am geplanten Ende der vorigen,
// nicht beim nächsten Tick – deshalb stimmt der Timer auch, wenn die App kurz im Hintergrund war.

/** Vorwarnung: die letzten 3 Sekunden einer Phase. */
export const WARN_SECONDS = 3;

const base = (meta) => ({ paused: false, left: 0, nextWarn: WARN_SECONDS, ...meta });

/** Satzpause: Countdown über `seconds`, beginnend bei `at`. */
export function restTimer(seconds, at, meta = {}) {
  const total = Math.max(1, seconds) * 1000;
  return { ...base(meta), kind: 'rest', phase: 'rest', rep: 0, reps: 0, total, endAt: at + total };
}

/** Intervall: reps × (work s Arbeit, rest s Pause); nach der letzten Arbeitsphase ist der Satz fertig. */
export function intervalTimer({ work, rest = 0, reps = 1 }, at, meta = {}) {
  const total = Math.max(1, work) * 1000;
  return { ...base(meta), kind: 'interval', phase: 'work', work, rest, reps: Math.max(1, reps), rep: 1, total, endAt: at + total };
}

/** Restzeit in ms. */
export function remaining(t, now) {
  if (!t || t.phase === 'done') return 0;
  return t.paused ? t.left : Math.max(0, t.endAt - now);
}

/** Anteil der verbleibenden Zeit an der Phase (1 = gerade begonnen, 0 = vorbei). */
export const fraction = (t, now) => (t && t.total ? Math.min(1, remaining(t, now) / t.total) : 0);

function startPhase(t, phase, seconds, at) {
  t.phase = phase;
  t.total = Math.max(1, seconds) * 1000;
  t.endAt = at + t.total;
  t.nextWarn = WARN_SECONDS;
}

/**
 * Zeit fortschreiben. Liefert die Ereignisse seit dem letzten Aufruf:
 * - { type: 'warn', sec }      Vorwarnung (3, 2, 1 s vor Ende; nur bei Phasen länger als 3 s)
 * - { type: 'pause', at, rep } Arbeitsphase vorbei, Pause zwischen Wiederholungen beginnt
 * - { type: 'work', at, rep }  nächste Arbeitsphase beginnt
 * - { type: 'setDone', at }    alle Wiederholungen des Intervalls geschafft
 * - { type: 'restDone', at }   Satzpause vorbei
 * Bei längerer Abwesenheit werden alle verpassten Phasen nachgeholt (ohne Vorwarnungen dafür).
 */
export function tick(t, now) {
  const events = [];
  if (!t || t.paused || t.phase === 'done') return events;
  while (t.phase !== 'done' && now >= t.endAt) {
    const at = t.endAt;
    if (t.kind === 'rest') {
      t.phase = 'done';
      events.push({ type: 'restDone', at });
    } else if (t.phase === 'work') {
      if (t.rep >= t.reps) {
        t.phase = 'done';
        events.push({ type: 'setDone', at });
      } else if (t.rest > 0) {
        startPhase(t, 'pause', t.rest, at);
        events.push({ type: 'pause', at, rep: t.rep });
      } else {
        t.rep++;
        startPhase(t, 'work', t.work, at);
        events.push({ type: 'work', at, rep: t.rep });
      }
    } else {
      t.rep++;
      startPhase(t, 'work', t.work, at);
      events.push({ type: 'work', at, rep: t.rep });
    }
  }
  if (t.phase !== 'done' && t.total > WARN_SECONDS * 1000) {
    const sec = Math.ceil((t.endAt - now) / 1000);
    if (sec <= t.nextWarn && sec >= 1) {
      events.push({ type: 'warn', sec });
      t.nextWarn = sec - 1;
    }
  }
  return events;
}

export function pause(t, now) {
  if (!t || t.paused || t.phase === 'done') return;
  t.left = Math.max(0, t.endAt - now);
  t.paused = true;
}

export function resume(t, now) {
  if (!t || !t.paused) return;
  t.endAt = now + t.left;
  t.paused = false;
}

/** Aktuelle Phase sofort beenden (die Folgeereignisse liefert der nächste tick). */
export function skip(t, now) {
  if (!t || t.phase === 'done') return;
  t.paused = false;
  t.left = 0;
  t.endAt = now;
}

/** Restzeit der aktuellen Phase um deltaSeconds ändern (z. B. ±15 s); nie unter 0. */
export function adjust(t, deltaSeconds, now) {
  if (!t || t.phase === 'done') return;
  const left = Math.max(0, remaining(t, now) + deltaSeconds * 1000);
  if (t.paused) t.left = left;
  else t.endAt = now + left;
  if (left > t.total) t.total = left;
  t.nextWarn = left > WARN_SECONDS * 1000 ? WARN_SECONDS : Math.max(0, Math.ceil(left / 1000) - 1);
}

/** „1:30“ ab einer Minute, darunter nur Sekunden („7“). */
export function fmtTime(ms, long = false) {
  const s = Math.ceil(ms / 1000);
  if (!long && s < 60) return String(s);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}
