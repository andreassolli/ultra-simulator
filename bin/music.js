// Background music for the simulator.
//
// The main screen plays audio/menu.mp3 (or a generated menu track); a fight starting restarts the boss's own track from the beginning.
//
// 1. If bin/audio/<boss>.mp3 (or .ogg) exists - boss = speaker | dage | drakath | nulgath | gramiel - that file is looped.
//    Drop your own tracks there; nothing else has to change.
// 2. Otherwise a short generative ambient track is played, made in the browser with the Web Audio API (no audio files, nothing
//    downloaded), in a different key / tempo / mood for each boss.
//
// The game calls window.gameMusicBoss(id) when a boss is selected and window.gameMusicToggle() for the Music button / M key.
// Browsers only allow sound after a click or key press, so the music starts with the first one.
(function () {
  "use strict";
  var VOLUME = 0.22;
  var MOODS = {
    //            root MIDI, scale (semitones), tempo (bpm), chords (scale degrees, 0-based), pad wave, arp wave, arp density
    speaker: { root: 50, scale: [0, 2, 3, 5, 7, 8, 10], bpm: 62, chords: [0, 5, 3, 4], pad: "sawtooth", arp: "triangle", density: 0.45 },
    dage:    { root: 52, scale: [0, 1, 4, 5, 7, 8, 10], bpm: 70, chords: [0, 1, 0, 6], pad: "sawtooth", arp: "square", density: 0.35 },
    drakath: { root: 49, scale: [0, 2, 3, 5, 7, 8, 11], bpm: 84, chords: [0, 5, 2, 4], pad: "sawtooth", arp: "sawtooth", density: 0.6 },
    nulgath: { root: 53, scale: [0, 2, 3, 5, 7, 8, 10], bpm: 58, chords: [0, 0, 5, 6], pad: "square", arp: "triangle", density: 0.3 },
    menu:    { root: 48, scale: [0, 2, 4, 5, 7, 9, 11], bpm: 56, chords: [0, 5, 3, 4], pad: "triangle", arp: "sine", density: 0.5 },
    gramiel: { root: 50, scale: [0, 2, 4, 6, 7, 9, 11], bpm: 66, chords: [0, 4, 5, 3], pad: "triangle", arp: "sine", density: 0.55 }
  };
  var state = { on: true, boss: "menu", ctx: null, master: null, timer: null, nextBeat: 0, beat: 0, file: null, unlocked: false };
  try { if (window.localStorage.getItem("ultraMusic") === "off") state.on = false; } catch (e) {}

  function hz(m) { return 440 * Math.pow(2, (m - 69) / 12); }
  function degree(mood, d) { var n = mood.scale.length; return mood.root + mood.scale[((d % n) + n) % n] + 12 * Math.floor(d / n); }

  function ensureContext() {
    if (state.ctx) return state.ctx;
    var AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    var ctx = new AC();
    var master = ctx.createGain();
    master.gain.value = VOLUME;
    // a soft echo so the thin oscillators sound like a room
    var delay = ctx.createDelay(1.5); delay.delayTime.value = 0.42;
    var fb = ctx.createGain(); fb.gain.value = 0.38;
    var wet = ctx.createGain(); wet.gain.value = 0.35;
    var tone = ctx.createBiquadFilter(); tone.type = "lowpass"; tone.frequency.value = 1800;
    delay.connect(tone); tone.connect(fb); fb.connect(delay); tone.connect(wet); wet.connect(master);
    var bus = ctx.createGain(); bus.connect(master); bus.connect(delay);
    master.connect(ctx.destination);
    state.ctx = ctx; state.master = master; state.bus = bus;
    return ctx;
  }

  function note(freq, when, dur, type, gain, attack, cutoff) {
    var ctx = state.ctx;
    var o = ctx.createOscillator(), g = ctx.createGain(), f = ctx.createBiquadFilter();
    o.type = type; o.frequency.value = freq;
    f.type = "lowpass"; f.frequency.value = cutoff || 2400;
    g.gain.setValueAtTime(0.0001, when);
    g.gain.linearRampToValueAtTime(gain, when + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, when + dur);
    o.connect(f); f.connect(g); g.connect(state.bus);
    o.start(when); o.stop(when + dur + 0.05);
  }

  // schedule a little ahead of the clock, one beat at a time
  function schedule() {
    var ctx = state.ctx, mood = MOODS[state.boss] || MOODS.speaker;
    if (!ctx) return;
    var spb = 60 / mood.bpm;
    while (state.nextBeat < ctx.currentTime + 0.6) {
      var t = state.nextBeat, b = state.beat, bar = Math.floor(b / 4), chordDeg = mood.chords[bar % mood.chords.length];
      if (b % 4 === 0) { // chord: root, third, fifth, with a bass note, held for the bar
        var len = spb * 4.2;
        [0, 2, 4].forEach(function (k, i) {
          note(hz(degree(mood, chordDeg + k) + (i === 0 ? 0 : 0)), t, len, mood.pad, 0.07, 1.2, 700 + 120 * i);
          note(hz(degree(mood, chordDeg + k) + 0.12), t, len, mood.pad, 0.05, 1.4, 650);
        });
        note(hz(degree(mood, chordDeg) - 12), t, len, "sine", 0.16, 0.25, 400);
      }
      if (Math.random() < mood.density) { // a slow arpeggio over the chord
        var d = chordDeg + [0, 2, 4, 7, 9][Math.floor(Math.random() * 5)];
        note(hz(degree(mood, d) + 12), t + (Math.random() < 0.3 ? spb / 2 : 0), spb * 1.6, mood.arp, 0.05, 0.02, 3200);
      }
      state.nextBeat += spb;
      state.beat++;
    }
  }

  function stopAll() {
    if (state.timer) { clearInterval(state.timer); state.timer = null; }
    if (state.file) { try { state.file.pause(); } catch (e) {} state.file = null; }
  }

  function start() {
    stopAll();
    if (!state.on || !state.unlocked) return;
    var id = state.boss, tried = [id + ".mp3", id + ".ogg"], i = 0;
    var tryFile = function () {
      if (i >= tried.length) return generative();
      var a = new Audio("audio/" + tried[i++]);
      a.loop = true; a.volume = VOLUME * 2;
      a.addEventListener("error", tryFile, { once: true });
      a.play().then(function () { if (state.boss === id && state.on) state.file = a; else a.pause(); }).catch(function () {});
    };
    var generative = function () {
      var ctx = ensureContext();
      if (!ctx || !state.on) return;
      if (ctx.state === "suspended") ctx.resume();
      state.nextBeat = ctx.currentTime + 0.1; state.beat = 0;
      state.timer = setInterval(schedule, 120);
    };
    if (window.location.protocol === "file:") generative(); else tryFile();
  }

  function unlock() {
    if (state.unlocked) return;
    state.unlocked = true;
    start();
  }
  ["pointerdown", "keydown", "touchstart"].forEach(function (ev) { window.addEventListener(ev, unlock, { capture: true }); });

  // scene = "menu" (the main screen) or a boss id; force restarts the track even when the scene did not change (a fight starting)
  window.gameMusicScene = window.gameMusicBoss = function (id, force) {
    if (!MOODS[id]) return false;
    if (id !== state.boss || force) { state.boss = id; start(); }
    return state.on;
  };
  window.gameMusicToggle = function () {
    state.on = !state.on;
    try { window.localStorage.setItem("ultraMusic", state.on ? "on" : "off"); } catch (e) {}
    if (state.on) { state.unlocked = true; start(); } else { stopAll(); }
    return state.on;
  };
  window.gameMusicState = function () { return state.on; };
})();
