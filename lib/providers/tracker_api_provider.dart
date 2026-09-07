import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/models/tracker.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';
import 'package:tracker/providers/wallet_provider.dart';

class TrackerApiState {
  final List<Tracker> trackers;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> pagination;

  TrackerApiState({
    this.trackers = const [],
    this.isLoading = false,
    this.error,
    this.pagination = const {},
  });

  TrackerApiState copyWith({
    List<Tracker>? trackers,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? pagination,
  }) {
    return TrackerApiState(
      trackers: trackers ?? this.trackers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pagination: pagination ?? this.pagination,
    );
  }
}

class TrackerApiNotifier extends StateNotifier<TrackerApiState> {
  final Ref ref;
  TrackerApiNotifier(this.ref) : super(TrackerApiState());

  Future<Tracker> addTracker({
    required String name,
    required double budgetAmount,
    double? currentAmount,
    String? description,
  }) async {
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'tracker/add/v1',
        'POST',
        body: {
          'name': name,
          'budget_amount': budgetAmount,
          if (currentAmount != null) 'current_amount': currentAmount,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );

      final isSuccess = response['success'] ?? false;
      if (!isSuccess) {
        final message = response['message'] ?? 'Failed to add tracker';
        state = state.copyWith(error: message);
        throw Exception(message);
      }

      final data = response['data'];
      final newTracker = Tracker.fromJson(data['tracker']);

      final updatedWallet = data['updatedWallet'];
      if (updatedWallet != null) {
        ref
            .read(walletProvider.notifier)
            .updateWallet(
              (updatedWallet['bank_balance'] as num).toDouble(),
              (updatedWallet['expense'] as num).toDouble(),
              (updatedWallet['income'] as num).toDouble(),
              (updatedWallet['saving'] as num).toDouble(),
            );
      }

      state = state.copyWith(
        trackers: [newTracker, ...state.trackers],
        error: null,
      );
      return newTracker;
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchTrackers({
    int page = 1,
    int limit = 15,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'tracker/get/v1',
        'GET',
        queryParams: {'page': '$page', 'limit': '$limit'},
      );

      final List<dynamic> trackersData = response['data']['trackers'] ?? [];
      final trackers = trackersData
          .map((data) => Tracker.fromJson(data))
          .toList();

      final pagination = Map<String, dynamic>.from(
        response['data']['pagination'] ?? {},
      );

      state = state.copyWith(
        trackers: trackers,
        isLoading: false,
        pagination: pagination,
      );

      return {'trackers': trackers, 'pagination': pagination};
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch trackers: ${e.toString()}',
      );
      return {'trackers': <Tracker>[], 'pagination': <String, dynamic>{}};
    }
  }

  Future<Tracker?> getTrackerById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'tracker/details/v1/$id',
        'GET',
      );

      final tracker = Tracker.fromJson(response['data']);
      state = state.copyWith(isLoading: false);
      return tracker;
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch tracker details: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> deleteTracker(String id) async {
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'tracker/delete/v1/$id',
        'DELETE',
      );

      final updatedWallet = response['data']?['updatedWallet'];
      if (updatedWallet != null) {
        ref
            .read(walletProvider.notifier)
            .updateWallet(
              (updatedWallet['bank_balance'] as num).toDouble(),
              (updatedWallet['expense'] as num).toDouble(),
              (updatedWallet['income'] as num).toDouble(),
              (updatedWallet['saving'] as num).toDouble(),
            );
      }

      state = state.copyWith(
        trackers: state.trackers.where((t) => t.id != id).toList(),
      );
      return true;
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(error: 'Failed to delete tracker: ${e.toString()}');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final trackerApiProvider =
    StateNotifierProvider<TrackerApiNotifier, TrackerApiState>((ref) {
      return TrackerApiNotifier(ref);
    });
