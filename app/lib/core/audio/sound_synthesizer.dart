import 'package:flutter/services.dart';
import 'package:neuroplay/core/audio/sound_synthesizer_stub.dart'
    if (dart.library.js_interop) 'package:neuroplay/core/audio/sound_synthesizer_web.dart';

/// Cognitive Sound Synthesizer: Generates organic musical feedback in real-time.
///
/// Features Pavlovian ascending pentatonic scale chimes for streaks,
/// gentle sub-bass thuds for mistakes, and focus countdown beeps.
abstract final class SoundSynthesizer {
  /// Play an ascending harmonic chime when user answers correctly.
  /// [streak] determines the scale pitch (C, D, E, G, A, C5...).
  static void playSuccess({int streak = 0}) {
    HapticFeedback.lightImpact();
    platformPlaySuccess(streak);
  }

  /// Play a soft low-frequency thud on mistake (never punitive).
  static void playError() {
    HapticFeedback.mediumImpact();
    platformPlayError();
  }

  /// Play pre-game countdown pip.
  static void playCountdown({bool isFinal = false}) {
    HapticFeedback.selectionClick();
    platformPlayCountdown(isFinal: isFinal);
  }

  /// Play crisp tactile micro-click on button/tile tap.
  static void playClick() {
    HapticFeedback.selectionClick();
    platformPlayClick();
  }

  /// Play celebratory multi-tone fanfare upon exercise completion.
  static void playFanfare() {
    HapticFeedback.heavyImpact();
    platformPlayFanfare();
  }
}
