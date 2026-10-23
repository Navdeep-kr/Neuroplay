/// NEUROPLAY Game Engine & Contracts
///
/// A deterministic, headless, UI-independent cognitive game framework in pure Dart.
library;

// Contracts
export 'src/contracts/game_action.dart';
export 'src/contracts/game_config.dart';
export 'src/contracts/game_definition.dart';
export 'src/contracts/game_difficulty.dart';
export 'src/contracts/game_engine_version.dart';
export 'src/contracts/game_phase.dart';
export 'src/contracts/game_result.dart';
export 'src/contracts/game_state.dart';
export 'src/contracts/scoring_rules.dart';

// Exceptions
export 'src/exceptions/game_exceptions.dart';

// Randomness & Determinism
export 'src/randomness/seeded_random.dart';

// Session & Engine Base
export 'src/session/game_engine_base.dart';
export 'src/session/game_session.dart';

// Monotonic Timing
export 'src/timing/monotonic_clock.dart';
