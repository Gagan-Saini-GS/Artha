import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/models/transaction.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';
import 'package:tracker/providers/transaction_provider.dart';

class WalletFilterState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isSearchMode;
  final List<Transaction> transactions;
  final Map<String, dynamic> pagination;

  WalletFilterState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.isSearchMode = false,
    this.transactions = const [],
    this.pagination = const {},
  });

  WalletFilterState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isSearchMode,
    List<Transaction>? transactions,
    Map<String, dynamic>? pagination,
  }) {
    return WalletFilterState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      transactions: transactions ?? this.transactions,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  String toString() {
    return "isLoading: $isLoading, isSearchMode: $isSearchMode, hasMore: $hasMore, Pagination: $pagination, Transactions: $transactions";
  }
}

class WalletFilterNotifier extends StateNotifier<WalletFilterState> {
  final Ref ref;
  String? _lastName;
  double? _lastAmount;

  WalletFilterNotifier(this.ref) : super(WalletFilterState());

  Future<void> clearSearch() async {
    _lastName = null;
    _lastAmount = null;
    state = WalletFilterState();
    ref.read(allTransactionListProvider.notifier).fetchTransactionHistory();
  }

  Future<void> searchTransactions({String? name, double? amount}) async {
    try {
      _lastName = name;
      _lastAmount = amount;
      state = state.copyWith(isLoading: true);

      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final queryParams = <String, String>{
        'page': '1',
        'limit': '15',
      };

      if (name != null && name.trim().isNotEmpty) {
        queryParams['name'] = name;
      }

      if (amount != null) {
        queryParams['amount'] = '$amount';
      }

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/search/v1',
        'GET',
        queryParams: queryParams,
      );

      final data = response['data']['transactions'];
      final pagination = response['data']['pagination'];

      final transactions = (data as List)
          .map((item) => Transaction.fromJson(item))
          .toList();

      state = state.copyWith(
        transactions: transactions,
        pagination: pagination,
        isSearchMode: true,
        hasMore: pagination['hasMore'] ?? false,
      );

      ref.read(allTransactionListProvider.notifier).updateTransactions(transactions);
    } catch (error) {
      Logger().e(error);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final queryParams = <String, String>{
        'page': '${(state.pagination['currentPage'] ?? 1) + 1}',
        'limit': '15',
      };

      if (_lastName != null && _lastName!.trim().isNotEmpty) {
        queryParams['name'] = _lastName!;
      }

      if (_lastAmount != null) {
        queryParams['amount'] = '$_lastAmount';
      }

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/search/v1',
        'GET',
        queryParams: queryParams,
      );

      final data = response['data']['transactions'];
      final pagination = response['data']['pagination'];

      final newTransactions = (data as List)
          .map((item) => Transaction.fromJson(item))
          .toList();

      final merged = [...state.transactions, ...newTransactions];

      state = state.copyWith(
        transactions: merged,
        pagination: pagination,
        hasMore: pagination['hasMore'] ?? false,
      );

      ref.read(allTransactionListProvider.notifier).updateTransactions(merged);
    } catch (e) {
      Logger().e(e);
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final walletFilterProvider =
    StateNotifierProvider<WalletFilterNotifier, WalletFilterState>((ref) {
      return WalletFilterNotifier(ref);
    });
