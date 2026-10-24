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

// Cognitive Games: Memory Matrix
export 'src/games/memory_matrix/memory_matrix_actions.dart';
export 'src/games/memory_matrix/memory_matrix_config.dart';
export 'src/games/memory_matrix/memory_matrix_definition.dart';
export 'src/games/memory_matrix/memory_matrix_engine.dart';
export 'src/games/memory_matrix/memory_matrix_scoring.dart';
export 'src/games/memory_matrix/memory_matrix_state.dart';

// Cognitive Games: Reflex Forge
export 'src/games/reflex_forge/reflex_forge_actions.dart';
export 'src/games/reflex_forge/reflex_forge_config.dart';
export 'src/games/reflex_forge/reflex_forge_definition.dart';
export 'src/games/reflex_forge/reflex_forge_engine.dart';
export 'src/games/reflex_forge/reflex_forge_models.dart';
export 'src/games/reflex_forge/reflex_forge_scoring.dart';
export 'src/games/reflex_forge/reflex_forge_state.dart';

// Cognitive Games: Focus Reactor
export 'src/games/focus_reactor/focus_reactor_actions.dart';
export 'src/games/focus_reactor/focus_reactor_config.dart';
export 'src/games/focus_reactor/focus_reactor_definition.dart';
export 'src/games/focus_reactor/focus_reactor_engine.dart';
export 'src/games/focus_reactor/focus_reactor_models.dart';
export 'src/games/focus_reactor/focus_reactor_scoring.dart';
export 'src/games/focus_reactor/focus_reactor_state.dart';

// Cognitive Games: Logic Labyrinth
export 'src/games/logic_labyrinth/logic_labyrinth_actions.dart';
export 'src/games/logic_labyrinth/logic_labyrinth_config.dart';
export 'src/games/logic_labyrinth/logic_labyrinth_definition.dart';
export 'src/games/logic_labyrinth/logic_labyrinth_engine.dart';
export 'src/games/logic_labyrinth/logic_labyrinth_models.dart';
export 'src/games/logic_labyrinth/logic_labyrinth_scoring.dart';
export 'src/games/logic_labyrinth/logic_labyrinth_solver.dart';
export 'src/games/logic_labyrinth/logic_labyrinth_state.dart';

// Cognitive Games: Number Pulse
export 'src/games/number_pulse/number_pulse_actions.dart';
export 'src/games/number_pulse/number_pulse_config.dart';
export 'src/games/number_pulse/number_pulse_definition.dart';
export 'src/games/number_pulse/number_pulse_engine.dart';
export 'src/games/number_pulse/number_pulse_models.dart';
export 'src/games/number_pulse/number_pulse_scoring.dart';
export 'src/games/number_pulse/number_pulse_state.dart';

// Cognitive Games: Word Weaver
export 'src/games/word_weaver/word_weaver_actions.dart';
export 'src/games/word_weaver/word_weaver_bank.dart';
export 'src/games/word_weaver/word_weaver_config.dart';
export 'src/games/word_weaver/word_weaver_definition.dart';
export 'src/games/word_weaver/word_weaver_engine.dart';
export 'src/games/word_weaver/word_weaver_models.dart';
export 'src/games/word_weaver/word_weaver_scoring.dart';
export 'src/games/word_weaver/word_weaver_state.dart';

// Adaptive Difficulty Engine
export 'src/adaptive/adaptive_difficulty_engine.dart';
export 'src/adaptive/adaptive_models.dart';
export 'src/adaptive/adaptive_rules.dart';
