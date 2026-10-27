/// Non-web fallback implementation for sound synthesizer.
void platformPlaySuccess(int streak) {
  // Graceful fallback for non-web environments (mobile uses HapticFeedback)
}

void platformPlayError() {
  // Graceful fallback
}

void platformPlayCountdown({required bool isFinal}) {
  // Graceful fallback
}

void platformPlayClick() {
  // Graceful fallback
}

void platformPlayFanfare() {
  // Graceful fallback
}
