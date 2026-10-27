import 'dart:js_interop';
import 'dart:math' as math;

@JS('eval')
external JSAny? _jsEval(JSString script);

bool _initialized = false;

void _ensureInitialized() {
  if (_initialized) return;
  _initialized = true;
  try {
    _jsEval(
      '''
      window.__neuroplayAudio = {
        ctx: null,
        init: function() {
          if (!this.ctx) {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (AudioCtx) this.ctx = new AudioCtx();
          }
          if (this.ctx && this.ctx.state === 'suspended') {
            this.ctx.resume();
          }
        },
        playTone: function(freq, duration, type, startGain) {
          this.init();
          if (!this.ctx) return;
          try {
            var osc = this.ctx.createOscillator();
            var gain = this.ctx.createGain();
            osc.type = type || 'sine';
            osc.frequency.setValueAtTime(freq, this.ctx.currentTime);
            gain.gain.setValueAtTime(startGain || 0.15, this.ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.0001, this.ctx.currentTime + duration);
            osc.connect(gain);
            gain.connect(this.ctx.destination);
            osc.start();
            osc.stop(this.ctx.currentTime + duration);
          } catch(e) {}
        },
        playChord: function(freqs, duration) {
          var self = this;
          freqs.forEach(function(f, idx) {
            setTimeout(function() {
              self.playTone(f, duration, 'triangle', 0.12);
            }, idx * 60);
          });
        }
      };
    '''
          .toJS,
    );
  } on Object catch (_) {}
}

void platformPlaySuccess(int streak) {
  try {
    _ensureInitialized();
    // Ascending pentatonic scale frequencies (C5, D5, E5, G5, A5, C6...)
    const scale = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66];
    final noteIndex = math.min(streak, scale.length - 1);
    final freq = scale[noteIndex];
    _jsEval(
      'window.__neuroplayAudio.playTone($freq, 0.28, "triangle", 0.18);'.toJS,
    );
  } on Object catch (_) {}
}

void platformPlayError() {
  try {
    _ensureInitialized();
    _jsEval(
      'window.__neuroplayAudio.playTone(130.81, 0.35, "sine", 0.25);'.toJS,
    );
  } on Object catch (_) {}
}

void platformPlayCountdown({required bool isFinal}) {
  try {
    _ensureInitialized();
    final freq = isFinal ? 880.00 : 440.00;
    final dur = isFinal ? 0.35 : 0.15;
    _jsEval(
      'window.__neuroplayAudio.playTone($freq, $dur, "sine", 0.15);'.toJS,
    );
  } on Object catch (_) {}
}

void platformPlayClick() {
  try {
    _ensureInitialized();
    _jsEval(
      'if (window.__neuroplayAudio) window.__neuroplayAudio.playTone(1200, 0.03, "sine", 0.08);'
          .toJS,
    );
  } on Object catch (_) {}
}

void platformPlayFanfare() {
  try {
    _ensureInitialized();
    _jsEval(
      'window.__neuroplayAudio.playChord([523.25, 659.25, 783.99, 1046.50], 0.6);'
          .toJS,
    );
  } on Object catch (_) {}
}
