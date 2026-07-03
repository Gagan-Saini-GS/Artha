import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/enums/timePeriod.dart';
import 'package:tracker/enums/transaction_type.dart';
import 'package:tracker/models/chart_data.dart';
import 'package:tracker/models/transaction.dart';
import 'package:tracker/models/transaction_summary.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';
import 'package:tracker/providers/transaction_filter_provider.dart';
import 'package:tracker/utils/capitalize.dart';
import 'package:tracker/utils/getTransactionType.dart';

class RollupDataState {
  final String periodKey;
  final String periodType;
  final String transactionType;
  final double amount;

  RollupDataState({
    this.periodKey = "",
    this.periodType = "",
    this.transactionType = "",
    this.amount = 0,
  });

  RollupDataState copyWith({
    String? periodKey,
    String? periodType,
    String? transactionType,
    double? amount,
  }) {
    return RollupDataState(
      periodKey: periodKey ?? this.periodKey,
      periodType: periodType ?? this.periodType,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
    );
  }
}

class TransactionRollupApiState {
  final bool isLoading;
  final String? error;
  final List<ChartData> graphData;
  final List<Transaction> transactions;
  final Map<String, dynamic> pagination;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  TransactionRollupApiState({
    this.isLoading = false,
    this.error,
    this.graphData = const [],
    this.transactions = const [],
    this.pagination = const {},
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
  });

  TransactionRollupApiState copyWith({
    bool? isLoading,
    String? error,
    List<ChartData>? graphData,
    List<Transaction>? transactions,
    Map<String, dynamic>? pagination,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) {
    return TransactionRollupApiState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      graphData: graphData ?? this.graphData,
      transactions: transactions ?? this.transactions,
      pagination: pagination ?? this.pagination,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class TransactionRollupApiNotifier
    extends StateNotifier<TransactionRollupApiState> {
  final Ref ref;

  TransactionRollupApiNotifier(this.ref) : super(TransactionRollupApiState());

  Future<List<Transaction>> getStats(
    TimePeriod periodType,
    DateTime startDate,
    DateTime endDate,
    TransactionType type,
  ) async {
    state = state.copyWith(isLoading: true);

    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'rollups/stats/v1',
        'GET',
        queryParams: {
          "type": getTransactionType(type),
          "period": periodType.name.capitalize(),
          "start_date": startDate.toIso8601String(),
          "end_date": endDate.toIso8601String(),
        },
      );

      final graphData = (response["data"] as List).map((transaction) {
        return ChartData(
          transaction["period_key"],
          transaction["period_key"],
          (transaction["total_amount"] as num).toDouble(),
        );
      }).toList();

      final transactionData = (response["transactions"] as List)
          .map((tx) => Transaction.fromJson(tx))
          .toList();

      state = state.copyWith(
        graphData: graphData,
        transactions: transactionData,
        // Setting is hardcoded  -> As not getting this from getStats response, so always try to fetch page 2 -> if found good, if not currentPage stays same.
        currentPage: 1,
        // Setting is hardcode -> As not getting this from getStats response, so always try to fetch page 2 -> if found good, if not then set hasMore false there.
        hasMore: true,
      );

      return transactionData;
    } catch (error) {
      Logger().e(error);
      state = state.copyWith(
        error: "Failed to get the summary ${error.toString()}",
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }

    return [];
  }

  Future<void> getSummary() async {}

  Future<TransactionSummary> getTransactionsByDateRange({
    required String startDate,
    required String endDate,
    required TransactionType type,
    required int page,
    required int limit,
  }) async {
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/dates/v1',
        'GET',
        queryParams: {
          'startDate': startDate,
          'endDate': endDate,
          'type': getTransactionType(type),
          'page': '$page',
          'limit': '$limit',
        },
      );

      final List<dynamic> transactionsData =
          response['data']['transactions'] ?? [];
      final Map<String, dynamic> pagination =
          response['data']['pagination'] ?? [];
      final transactions = transactionsData
          .map((data) => Transaction.fromJson(data))
          .toList();

      return TransactionSummary(
        transactions: transactions,
        pagination: pagination,
      );
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        // isLoading: false,
        error: 'Failed to fetch transactions: ${e.toString()}',
      );
    }

    return TransactionSummary(transactions: [], pagination: {});
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final transactionFilterState = ref.read(transactionFilterProvider);

    state = state.copyWith(isLoadingMore: true);
    try {
      final TransactionSummary summary = await getTransactionsByDateRange(
        startDate: transactionFilterState.startDate.toIso8601String(),
        endDate: transactionFilterState.endDate.toIso8601String(),
        type: transactionFilterState.type,
        page: state.currentPage + 1,
        limit: 15,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...summary.transactions],
        pagination: summary.pagination,
        currentPage: summary.pagination['currentPage'] ?? 1,
        hasMore: summary.pagination['hasMore'] ?? false,
      );
    } catch (e) {
      Logger().e(e);
      throw Exception("Can't fetch next page transactions");
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final transactionRollupApiProvider =
    StateNotifierProvider<
      TransactionRollupApiNotifier,
      TransactionRollupApiState
    >((ref) {
      return TransactionRollupApiNotifier(ref);
    });
