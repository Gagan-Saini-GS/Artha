import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/models/tracker.dart';
import 'package:tracker/providers/tracker_api_provider.dart';

class TrackerListState {
  final List<Tracker> trackers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  TrackerListState({
    this.trackers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.error,
  });

  TrackerListState copyWith({
    List<Tracker>? trackers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return TrackerListState(
      trackers: trackers ?? this.trackers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class TrackerListNotifier extends StateNotifier<TrackerListState> {
  final Ref ref;
  TrackerListNotifier(this.ref) : super(TrackerListState());

  Future<void> addTracker({
    required String name,
    required double budgetAmount,
    double? currentAmount,
    String? description,
  }) async {
    try {
      final newTracker = await ref
          .read(trackerApiProvider.notifier)
          .addTracker(
            name: name,
            budgetAmount: budgetAmount,
            currentAmount: currentAmount,
            description: description,
          );

      state = state.copyWith(
        trackers: [newTracker, ...state.trackers],
      );
    } catch (e) {
      Logger().e(e);
      rethrow;
    }
  }

  Future<void> fetchTrackers() async {
    if (state.isLoadingMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref
          .read(trackerApiProvider.notifier)
          .fetchTrackers(page: 1, limit: 15);

      final trackers = result['trackers'] as List<Tracker>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      state = state.copyWith(
        trackers: trackers,
        currentPage: pagination['currentPage'] ?? 1,
        hasMore: pagination['hasMore'] ?? false,
        isLoading: false,
      );
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        isLoading: false,
        error: "Can't fetch trackers",
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await ref
          .read(trackerApiProvider.notifier)
          .fetchTrackers(page: state.currentPage + 1, limit: 15);

      final trackers = result['trackers'] as List<Tracker>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      state = state.copyWith(
        trackers: [...state.trackers, ...trackers],
        currentPage: pagination['currentPage'] ?? state.currentPage + 1,
        hasMore: pagination['hasMore'] ?? false,
        isLoadingMore: false,
      );
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // Locally patch a tracker's current_amount when the server has updated it
  // via a related transaction add/delete, so the trackers list + details screen
  // stay in sync without a full refetch.
  void applyTrackerDelta(String trackerId, double delta) {
    final idx = state.trackers.indexWhere((t) => t.id == trackerId);
    if (idx < 0) return;
    final tracker = state.trackers[idx];
    final updated = tracker.copyWith(
      currentAmount: tracker.currentAmount + delta,
    );
    final newList = [...state.trackers];
    newList[idx] = updated;
    state = state.copyWith(trackers: newList);
  }

  Future<bool> deleteTracker(String id) async {
    try {
      final success = await ref
          .read(trackerApiProvider.notifier)
          .deleteTracker(id);
      if (success) {
        state = state.copyWith(
          trackers: state.trackers.where((t) => t.id != id).toList(),
        );
      }
      return success;
    } catch (e) {
      Logger().e(e);
      return false;
    }
  }
}

final trackerListProvider =
    StateNotifierProvider<TrackerListNotifier, TrackerListState>(
      (ref) => TrackerListNotifier(ref),
    );
