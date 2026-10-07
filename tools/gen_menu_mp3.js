// Offline render of bin/music.js's "menu" mood into an mp3 (needs ffmpeg). usage: node gen_menu.js <seconds> <out.mp3> [kbps]
const { spawn } = require('child_process');
const SR = 44100, SECS = +process.argv[2] || 60, OUT = process.argv[3] || 'menu.mp3', KBPS = process.argv[4] || '64';
const VOLUME = 0.22 * 8; // x8: the page plays it quiet on purpose (it is background music); a file for listening should be loud
const mood = { root: 48, scale: [0, 2, 4, 5, 7, 9, 11], bpm: 56, chords: [0, 5, 3, 4], pad: 'triangle', arp: 'sine', density: 0.5 };
const hz = (m) => 440 * Math.pow(2, (m - 69) / 12);
const degree = (d) => { const n = mood.scale.length; return mood.root + mood.scale[((d % n) + n) % n] + 12 * Math.floor(d / n); };
const CH = SR * 30, TAIL = SR * 7;
let dry = new Float32Array(CH + TAIL), base = 0; // base = sample index of dry[0]
function osc(type, ph) { const p = ph - Math.floor(ph); return type === 'sine' ? Math.sin(2 * Math.PI * p) : (type === 'triangle' ? 1 - 4 * Math.abs(p - 0.5) : 0); }
function note(freq, whenS, dur, type, gain, attack, cutoff) {
  const start = Math.round(whenS * SR) - base, n = Math.round((dur + 0.05) * SR);
  // RBJ lowpass, Q = 1 dB like Web Audio's default
  const w0 = 2 * Math.PI * Math.min(cutoff, 20000) / SR, Q = Math.pow(10, 1 / 20), al = Math.sin(w0) / (2 * Q), cs = Math.cos(w0);
  const b0 = (1 - cs) / 2, b1 = 1 - cs, b2 = b0, a0 = 1 + al, a1 = -2 * cs, a2 = 1 - al;
  const B0 = b0 / a0, B1 = b1 / a0, B2 = b2 / a0, A1 = a1 / a0, A2 = a2 / a0;
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0, ph = Math.random();
  const dph = freq / SR, end = dur, tiny = 0.0001;
  for (let i = 0; i < n; i++) {
    const idx = start + i; const t = i / SR;
    let g;
    if (t < attack) g = tiny + (gain - tiny) * (t / attack); else if (t < end) g = gain * Math.pow(tiny / gain, (t - attack) / (end - attack)); else g = 0;
    const x = osc(type, ph) * g; ph += dph;
    const y = B0 * x + B1 * x1 + B2 * x2 - A1 * y1 - A2 * y2; x2 = x1; x1 = x; y2 = y1; y1 = y;
    if (idx >= 0 && idx < dry.length) dry[idx] += y;
  }
}
// delay / tone state
const D = Math.round(0.42 * SR), ring = new Float32Array(D); let rp = 0;
const tw = 2 * Math.PI * 1800 / SR, tq = Math.pow(10, 1 / 20), tal = Math.sin(tw) / (2 * tq), tcs = Math.cos(tw);
const T0 = (1 - tcs) / 2 / (1 + tal), T1 = (1 - tcs) / (1 + tal), TA1 = -2 * tcs / (1 + tal), TA2 = (1 - tal) / (1 + tal);
let tx1 = 0, tx2 = 0, ty1 = 0, ty2 = 0;
function mix(len) { const out = Buffer.alloc(len * 4);
  for (let i = 0; i < len; i++) {
    const x = dry[i], dout = ring[rp];
    const ty = T0 * dout + T1 * tx1 + T0 * tx2 - TA1 * ty1 - TA2 * ty2; tx2 = tx1; tx1 = dout; ty2 = ty1; ty1 = ty;
    ring[rp] = x + 0.38 * ty; rp = (rp + 1) % D;
    out.writeFloatLE(VOLUME * (x + 0.35 * ty), i * 4);
  } return out; }
const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'f32le', '-ar', String(SR), '-ac', '1', '-i', '-', '-c:a', 'libmp3lame', '-b:a', KBPS + 'k', OUT], { stdio: ['pipe', 'inherit', 'inherit'] });
const spb = 60 / mood.bpm; let beat = 0, nextBeat = 0.1, total = 0, peak = 0;
async function run() {
  while (total < SECS * SR) {
    const chunkEnd = (base + CH) / SR;
    while (nextBeat < chunkEnd) {
      const t = nextBeat, bar = Math.floor(beat / 4), cd = mood.chords[bar % mood.chords.length];
      if (beat % 4 === 0) { const len = spb * 4.2;
        [0, 2, 4].forEach((k, i) => { note(hz(degree(cd + k)), t, len, mood.pad, 0.07, 1.2, 700 + 120 * i); note(hz(degree(cd + k) + 0.12), t, len, mood.pad, 0.05, 1.4, 650); });
        note(hz(degree(cd) - 12), t, len, 'sine', 0.16, 0.25, 400); }
      if (Math.random() < mood.density) { const d = cd + [0, 2, 4, 7, 9][Math.floor(Math.random() * 5)]; note(hz(degree(d) + 12), t + (Math.random() < 0.3 ? spb / 2 : 0), spb * 1.6, mood.arp, 0.05, 0.02, 3200); }
      nextBeat += spb; beat++;
    }
    const take = Math.min(CH, SECS * SR - total);
    for (let i = 0; i < take; i++) peak = Math.max(peak, Math.abs(dry[i]) * VOLUME);
    const buf = mix(take);
    if (!ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once('drain', r));
    total += take;
    const nd = new Float32Array(CH + TAIL); nd.set(dry.subarray(CH)); dry = nd; base += CH;
    if ((total / SR) % 600 < 30) console.log('rendered', Math.round(total / SR / 60), 'min, dry peak', peak.toFixed(2));
  }
  ff.stdin.end(); ff.on('close', () => console.log('done, peak', peak.toFixed(2)));
}
run();
