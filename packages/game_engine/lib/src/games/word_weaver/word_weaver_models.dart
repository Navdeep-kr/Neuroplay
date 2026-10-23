import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Curated semantic category for Word Weaver associations.
enum WordCategory {
  cognition('Cognition', 'Brain structures, mental processes, and memory'),
  astronomy('Cosmos', 'Celestial bodies, astrophysics, and orbital phenomena'),
  ecology('Ecology', 'Biomes, ecosystems, and natural habitats'),
  acoustics('Acoustics', 'Musical harmonics, tone, and sound properties'),
  architecture(
    'Architecture',
    'Structural engineering and architectural forms',
  ),
  literature('Literature', 'Poetics, rhetoric, and literary forms');

  const WordCategory(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// A single vocabulary item in the curated bank.
@immutable
final class WordBankItem extends Equatable {
  const WordBankItem({
    required this.word,
    required this.category,
    this.difficultyTier = 1,
  });

  factory WordBankItem.fromJson(Map<String, dynamic> json) => WordBankItem(
        word: json['word'] as String,
        category: WordCategory.values.byName(json['category'] as String),
        difficultyTier: json['difficultyTier'] as int? ?? 1,
      );

  final String word;
  final WordCategory category;
  final int difficultyTier;

  Map<String, dynamic> toJson() => {
        'word': word,
        'category': category.name,
        'difficultyTier': difficultyTier,
      };

  @override
  List<Object?> get props => [word, category, difficultyTier];
}

/// A single word association question presented to the player.
@immutable
final class WordWeaverQuestion extends Equatable {
  const WordWeaverQuestion({
    required this.anchorWord,
    required this.category,
    required this.correctAssociatedWord,
    required this.options,
    required this.relationshipHint,
  }) : assert(options.length == 4, 'Must provide exactly 4 options');

  factory WordWeaverQuestion.fromJson(Map<String, dynamic> json) =>
      WordWeaverQuestion(
        anchorWord: json['anchorWord'] as String,
        category: WordCategory.values.byName(json['category'] as String),
        correctAssociatedWord: json['correctAssociatedWord'] as String,
        options: (json['options'] as List<dynamic>).cast<String>(),
        relationshipHint: json['relationshipHint'] as String,
      );

  final String anchorWord;
  final WordCategory category;
  final String correctAssociatedWord;
  final List<String> options;
  final String relationshipHint;

  Map<String, dynamic> toJson() => {
        'anchorWord': anchorWord,
        'category': category.name,
        'correctAssociatedWord': correctAssociatedWord,
        'options': options,
        'relationshipHint': relationshipHint,
      };

  @override
  List<Object?> get props => [
        anchorWord,
        category,
        correctAssociatedWord,
        options,
        relationshipHint,
      ];
}
