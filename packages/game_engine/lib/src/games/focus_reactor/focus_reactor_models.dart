import 'package:equatable/equatable.dart';

/// Distinct geometric shapes for Focus Reactor.
enum FocusShape {
  star('Star', '★'),
  hexagon('Hexagon', '⬡'),
  cross('Cross', '✚'),
  pentagon('Pentagon', '⬟'),
  diamond('Diamond', '◆'),
  circle('Circle', '●');

  const FocusShape(this.label, this.symbol);
  final String label;
  final String symbol;
}

/// Distinct marker icon for non-color accessibility.
enum FocusMarker {
  dot('Dot', '•'),
  ring('Ring', '○'),
  stripe('Stripe', '≡'),
  plain('Plain', '');

  const FocusMarker(this.label, this.symbol);
  final String label;
  final String symbol;
}

/// An individual stimulus item in Focus Reactor.
final class FocusItem extends Equatable {
  const FocusItem({
    required this.shape,
    this.marker = FocusMarker.plain,
  });

  final FocusShape shape;
  final FocusMarker marker;

  String get label => marker == FocusMarker.plain
      ? shape.label
      : '${shape.label} (${marker.label})';

  Map<String, dynamic> toJson() => {
        'shape': shape.name,
        'marker': marker.name,
      };

  factory FocusItem.fromJson(Map<String, dynamic> json) {
    return FocusItem(
      shape: FocusShape.values.firstWhere((s) => s.name == json['shape']),
      marker: FocusMarker.values.firstWhere(
        (m) => m.name == json['marker'],
        orElse: () => FocusMarker.plain,
      ),
    );
  }

  @override
  List<Object?> get props => [shape, marker];

  @override
  String toString() => label;
}
