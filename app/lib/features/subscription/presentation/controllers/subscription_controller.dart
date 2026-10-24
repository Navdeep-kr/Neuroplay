import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/features/subscription/data/subscription_repository.dart';
import 'package:neuroplay/features/subscription/domain/entitlement_models.dart';

/// State of the subscription UI view.
class SubscriptionState extends Equatable {
  const SubscriptionState({
    required this.entitlement,
    this.isLoading = false,
    this.isRestoring = false,
    this.errorMessage,
    this.restoreMessage,
  });

  final SubscriptionEntitlement entitlement;
  final bool isLoading;
  final bool isRestoring;
  final String? errorMessage;
  final String? restoreMessage;

  SubscriptionState copyWith({
    SubscriptionEntitlement? entitlement,
    bool? isLoading,
    bool? isRestoring,
    String? errorMessage,
    String? restoreMessage,
    bool clearError = false,
    bool clearRestoreMessage = false,
  }) =>
      SubscriptionState(
        entitlement: entitlement ?? this.entitlement,
        isLoading: isLoading ?? this.isLoading,
        isRestoring: isRestoring ?? this.isRestoring,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        restoreMessage: clearRestoreMessage
            ? null
            : (restoreMessage ?? this.restoreMessage),
      );

  @override
  List<Object?> get props => [
        entitlement,
        isLoading,
        isRestoring,
        errorMessage,
        restoreMessage,
      ];
}

/// State notifier managing subscription loading, verification, and restore actions.
class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController({
    required ISubscriptionRepository repository,
  })  : _repository = repository,
        super(
          SubscriptionState(
            entitlement: SubscriptionEntitlement.defaultFree(),
          ),
        ) {
    _init();
  }

  final ISubscriptionRepository _repository;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final entitlement = await _repository.getEntitlement();
    state = state.copyWith(
      entitlement: entitlement,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final entitlement = await _repository.getEntitlement(forceRefresh: true);
    state = state.copyWith(
      entitlement: entitlement,
      isLoading: false,
    );
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(
      isRestoring: true,
      clearError: true,
      clearRestoreMessage: true,
    );

    final result = await _repository.restorePurchases();

    if (result.isSuccess && result.entitlement != null) {
      state = state.copyWith(
        isRestoring: false,
        entitlement: result.entitlement!,
        restoreMessage:
            'Subscription restored successfully! Welcome to NEUROPLAY Plus.',
      );
    } else {
      state = state.copyWith(
        isRestoring: false,
        errorMessage: result.errorMessage ?? 'No active subscription found.',
      );
    }
  }

  Future<Uri> getManagementUrl() => _repository.getManagementUrl();
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionController(repository: repo);
});
