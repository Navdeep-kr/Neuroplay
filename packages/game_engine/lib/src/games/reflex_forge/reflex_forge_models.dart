import 'package:equatable/equatable.dart';

/// Geometric shapes used in Reflex Forge.
enum ReflexShape {
  circle('Circle'),
  square('Square'),
  triangle('Triangle'),
  diamond('Diamond');

  const ReflexShape(this.label);
  final String label;
}

/// Visual fill patterns used in Reflex Forge for non-color differentiation.
enum ReflexPattern {
  solid('Solid'),
  striped('Striped'),
  dotted('Dotted'),
  outline('Outline');

  const ReflexPattern(this.label);
  final String label;
}

/// Active matching rule for the current trial.
enum ReflexRule {
  matchShape(
    'Match Shape',
    'Select the option matching the target\'s SHAPE',
  ),
  matchPattern(
    'Match Pattern',
    'Select the option matching the target\'s FILL PATTERN',
  );

  const ReflexRule(this.title, this.description);
  final String title;
  final String description;

  ReflexRule get opposite => this == matchShape ? matchPattern : matchShape;
}

/// A compound symbol combining shape and pattern attributes.
final class ReflexSymbol extends Equatable {
  const ReflexSymbol({
    required this.shape,
    required this.pattern,
  });

  final ReflexShape shape;
  final ReflexPattern pattern;

  String get label => '${shape.label} (${pattern.label})';

  Map<String, dynamic> toJson() => {
        'shape': shape.name,
        'pattern': pattern.name,
      };

  factory ReflexSymbol.fromJson(Map<String, dynamic> json) {
    return ReflexSymbol(
      shape: ReflexShape.values.firstWhere((s) => s.name == json['shape']),
      pattern:
          ReflexPattern.values.firstWhere((p) => p.name == json['pattern']),
    );
  }

  @override
  List<Object?> get props => [shape, pattern];

  @override
  String toString() => label;
}
