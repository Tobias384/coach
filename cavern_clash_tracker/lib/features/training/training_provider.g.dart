// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lastExerciseSetHash() => r'af93cc537a6cffec4f9c1f97720e4e9f4ac7a9b7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [lastExerciseSet].
@ProviderFor(lastExerciseSet)
const lastExerciseSetProvider = LastExerciseSetFamily();

/// See also [lastExerciseSet].
class LastExerciseSetFamily extends Family<AsyncValue<SetEntry?>> {
  /// See also [lastExerciseSet].
  const LastExerciseSetFamily();

  /// See also [lastExerciseSet].
  LastExerciseSetProvider call(int exerciseId) {
    return LastExerciseSetProvider(exerciseId);
  }

  @override
  LastExerciseSetProvider getProviderOverride(
    covariant LastExerciseSetProvider provider,
  ) {
    return call(provider.exerciseId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lastExerciseSetProvider';
}

/// See also [lastExerciseSet].
class LastExerciseSetProvider extends AutoDisposeFutureProvider<SetEntry?> {
  /// See also [lastExerciseSet].
  LastExerciseSetProvider(int exerciseId)
    : this._internal(
        (ref) => lastExerciseSet(ref as LastExerciseSetRef, exerciseId),
        from: lastExerciseSetProvider,
        name: r'lastExerciseSetProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$lastExerciseSetHash,
        dependencies: LastExerciseSetFamily._dependencies,
        allTransitiveDependencies:
            LastExerciseSetFamily._allTransitiveDependencies,
        exerciseId: exerciseId,
      );

  LastExerciseSetProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.exerciseId,
  }) : super.internal();

  final int exerciseId;

  @override
  Override overrideWith(
    FutureOr<SetEntry?> Function(LastExerciseSetRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LastExerciseSetProvider._internal(
        (ref) => create(ref as LastExerciseSetRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        exerciseId: exerciseId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SetEntry?> createElement() {
    return _LastExerciseSetProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LastExerciseSetProvider && other.exerciseId == exerciseId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, exerciseId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LastExerciseSetRef on AutoDisposeFutureProviderRef<SetEntry?> {
  /// The parameter `exerciseId` of this provider.
  int get exerciseId;
}

class _LastExerciseSetProviderElement
    extends AutoDisposeFutureProviderElement<SetEntry?>
    with LastExerciseSetRef {
  _LastExerciseSetProviderElement(super.provider);

  @override
  int get exerciseId => (origin as LastExerciseSetProvider).exerciseId;
}

String _$trainingNotifierHash() => r'744255bd42061d227f7c4389145b954640f1607b';

/// See also [TrainingNotifier].
@ProviderFor(TrainingNotifier)
final trainingNotifierProvider =
    AutoDisposeNotifierProvider<TrainingNotifier, TrainingState>.internal(
      TrainingNotifier.new,
      name: r'trainingNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$trainingNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TrainingNotifier = AutoDisposeNotifier<TrainingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
