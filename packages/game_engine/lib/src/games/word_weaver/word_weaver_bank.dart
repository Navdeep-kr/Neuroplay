import 'package:game_engine/src/games/word_weaver/word_weaver_models.dart';

/// Versioned, curated vocabulary bank for Word Weaver.
///
/// Designed with unencumbered scientific, literary, and domain concepts.
abstract final class WordWeaverBank {
  static const String version = '1.0.0';

  static const List<WordBankItem> items = [
    // Cognition
    WordBankItem(
      word: 'SYNAPSE',
      category: WordCategory.cognition,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'NEURON',
      category: WordCategory.cognition,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'CORTEX',
      category: WordCategory.cognition,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'AXON',
      category: WordCategory.cognition,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'PERCEPTION',
      category: WordCategory.cognition,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'PLASTICITY',
      category: WordCategory.cognition,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'HIPPOCAMPUS',
      category: WordCategory.cognition,
      difficultyTier: 3,
    ),
    WordBankItem(
      word: 'NEUROTRANSMITTER',
      category: WordCategory.cognition,
      difficultyTier: 3,
    ),

    // Astronomy
    WordBankItem(
      word: 'GALAXY',
      category: WordCategory.astronomy,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'NEBULA',
      category: WordCategory.astronomy,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'ECLIPSE',
      category: WordCategory.astronomy,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'ORBIT',
      category: WordCategory.astronomy,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'PULSAR',
      category: WordCategory.astronomy,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'SUPERNOVA',
      category: WordCategory.astronomy,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'ZENITH',
      category: WordCategory.astronomy,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'PARALLAX',
      category: WordCategory.astronomy,
      difficultyTier: 3,
    ),

    // Ecology
    WordBankItem(
      word: 'CANOPY',
      category: WordCategory.ecology,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'BIOME',
      category: WordCategory.ecology,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'HABITAT',
      category: WordCategory.ecology,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'FLORA',
      category: WordCategory.ecology,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'TUNDRA',
      category: WordCategory.ecology,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'SYMBIOSIS',
      category: WordCategory.ecology,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'BIOSPHERE',
      category: WordCategory.ecology,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'MYCELIUM',
      category: WordCategory.ecology,
      difficultyTier: 3,
    ),

    // Acoustics
    WordBankItem(
      word: 'MELODY',
      category: WordCategory.acoustics,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'HARMONY',
      category: WordCategory.acoustics,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'RHYTHM',
      category: WordCategory.acoustics,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'PITCH',
      category: WordCategory.acoustics,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'TIMBRE',
      category: WordCategory.acoustics,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'CADENCE',
      category: WordCategory.acoustics,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'RESONANCE',
      category: WordCategory.acoustics,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'OVERTONE',
      category: WordCategory.acoustics,
      difficultyTier: 3,
    ),

    // Architecture
    WordBankItem(
      word: 'ARCH',
      category: WordCategory.architecture,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'FACADE',
      category: WordCategory.architecture,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'COLUMN',
      category: WordCategory.architecture,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'DOME',
      category: WordCategory.architecture,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'CANTILEVER',
      category: WordCategory.architecture,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'ATRIUM',
      category: WordCategory.architecture,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'KEYSTONE',
      category: WordCategory.architecture,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'BUTTRESS',
      category: WordCategory.architecture,
      difficultyTier: 3,
    ),

    // Literature
    WordBankItem(
      word: 'METAPHOR',
      category: WordCategory.literature,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'SONNET',
      category: WordCategory.literature,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'PROSE',
      category: WordCategory.literature,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'STANZA',
      category: WordCategory.literature,
      difficultyTier: 1,
    ),
    WordBankItem(
      word: 'SYNTAX',
      category: WordCategory.literature,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'ALLEGORY',
      category: WordCategory.literature,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'LEXICON',
      category: WordCategory.literature,
      difficultyTier: 2,
    ),
    WordBankItem(
      word: 'JUXTAPOSITION',
      category: WordCategory.literature,
      difficultyTier: 3,
    ),
  ];

  static List<WordBankItem> getItemsForCategory(WordCategory category) {
    return items.where((i) => i.category == category).toList();
  }
}
