import 'package:equatable/equatable.dart';
import 'package:game_engine/src/exceptions/game_exceptions.dart';
import 'package:meta/meta.dart';

/// Semantic version of the game engine or game definition.
@immutable
final class GameEngineVersion extends Equatable
    implements Comparable<GameEngineVersion> {
  const GameEngineVersion(
    this.major,
    this.minor,
    this.patch, {
    this.preRelease,
  })  : assert(major >= 0, 'Major version must be non-negative'),
        assert(minor >= 0, 'Minor version must be non-negative'),
        assert(patch >= 0, 'Patch version must be non-negative');

  /// Parses a semver string (e.g., '1.2.3' or '1.0.0-beta.1').
  factory GameEngineVersion.parse(String versionString) {
    final trimmed = versionString.trim();
    final preReleaseParts = trimmed.split('-');
    final mainParts = preReleaseParts[0].split('.');

    if (mainParts.length != 3) {
      throw GameValidationException(
        'Invalid semantic version format. Expected major.minor.patch',
        versionString,
      );
    }

    final major = int.tryParse(mainParts[0]);
    final minor = int.tryParse(mainParts[1]);
    final patch = int.tryParse(mainParts[2]);

    if (major == null || minor == null || patch == null) {
      throw GameValidationException(
        'Version components must be integers',
        versionString,
      );
    }

    final preRelease = preReleaseParts.length > 1
        ? preReleaseParts.sublist(1).join('-')
        : null;

    return GameEngineVersion(major, minor, patch, preRelease: preRelease);
  }

  factory GameEngineVersion.fromJson(dynamic json) {
    if (json is String) {
      return GameEngineVersion.parse(json);
    }
    if (json is Map<String, dynamic>) {
      return GameEngineVersion(
        json['major'] as int,
        json['minor'] as int,
        json['patch'] as int,
        preRelease: json['preRelease'] as String?,
      );
    }
    throw GameValidationException('Invalid GameEngineVersion JSON: $json');
  }

  /// Current default engine version for NEUROPLAY.
  static const GameEngineVersion current = GameEngineVersion(1, 0, 0);

  final int major;
  final int minor;
  final int patch;
  final String? preRelease;

  /// Returns true if this version satisfies the [required] version under semver rules.
  /// (Identical major version, and this version >= required version).
  bool isCompatibleWith(GameEngineVersion required) {
    if (major != required.major) return false;
    if (minor < required.minor) return false;
    if (minor == required.minor && patch < required.patch) return false;
    return true;
  }

  @override
  int compareTo(GameEngineVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease == null) return -1;
    if (preRelease != null && other.preRelease != null) {
      return preRelease!.compareTo(other.preRelease!);
    }
    return 0;
  }

  bool operator <(GameEngineVersion other) => compareTo(other) < 0;
  bool operator <=(GameEngineVersion other) => compareTo(other) <= 0;
  bool operator >(GameEngineVersion other) => compareTo(other) > 0;
  bool operator >=(GameEngineVersion other) => compareTo(other) >= 0;

  Map<String, dynamic> toJson() => {
        'major': major,
        'minor': minor,
        'patch': patch,
        if (preRelease != null) 'preRelease': preRelease,
      };

  @override
  String toString() {
    final base = '$major.$minor.$patch';
    return preRelease != null ? '$base-$preRelease' : base;
  }

  @override
  List<Object?> get props => [major, minor, patch, preRelease];
}
