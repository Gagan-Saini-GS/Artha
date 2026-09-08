import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/models/transaction.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';

class TrackerTransactionsState {
  final String trackerId;
  final List<Transaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  TrackerTransactionsState({
    this.trackerId = '',
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.error,
  });

  TrackerTransactionsState copyWith({
    String? trackerId,
    List<Transaction>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return TrackerTransactionsState(
      trackerId: trackerId ?? this.trackerId,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class TrackerTransactionsNotifier
    extends StateNotifier<TrackerTransactionsState> {
  final Ref ref;
  TrackerTransactionsNotifier(this.ref) : super(TrackerTransactionsState());

  Future<void> fetch(String trackerId) async {
    state = TrackerTransactionsState(trackerId: trackerId, isLoading: true);
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);
      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/tracker/v1/$trackerId',
        'GET',
        queryParams: {'page': '1', 'limit': '15'},
      );

      final List<dynamic> data = response['data']['transactions'] ?? [];
      final transactions = data.map((e) => Transaction.fromJson(e)).toList();
      final pagination = response['data']['pagination'] ?? {};

      state = state.copyWith(
        transactions: transactions,
        currentPage: pagination['currentPage'] ?? 1,
        hasMore: pagination['hasMore'] ?? false,
        isLoading: false,
      );
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        isLoading: false,
        error: "Can't fetch tracker transactions",
      );
    }
  }

  // Called from the transaction details bottom sheet when a transaction is
  // detached from the tracker currently being viewed. Keeps the list in sync
  // without requiring a pull-to-refresh.
  void removeTransaction(String transactionId) {
    if (state.transactions.every((t) => t.id != transactionId)) return;
    state = state.copyWith(
      transactions: state.transactions
          .where((t) => t.id != transactionId)
          .toList(),
    );
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.trackerId.isEmpty) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);
      final nextPage = state.currentPage + 1;
      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/tracker/v1/${state.trackerId}',
        'GET',
        queryParams: {'page': '$nextPage', 'limit': '15'},
      );

      final List<dynamic> data = response['data']['transactions'] ?? [];
      final transactions = data.map((e) => Transaction.fromJson(e)).toList();
      final pagination = response['data']['pagination'] ?? {};

      state = state.copyWith(
        transactions: [...state.transactions, ...transactions],
        currentPage: pagination['currentPage'] ?? nextPage,
        hasMore: pagination['hasMore'] ?? false,
        isLoadingMore: false,
      );
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final trackerTransactionsProvider =
    StateNotifierProvider<
      TrackerTransactionsNotifier,
      TrackerTransactionsState
    >((ref) => TrackerTransactionsNotifier(ref));
