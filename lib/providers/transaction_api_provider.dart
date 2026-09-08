import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/models/transaction.dart';
import 'package:tracker/models/transaction_summary.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';
import 'package:tracker/providers/tracker_provider.dart';
import 'package:tracker/providers/wallet_provider.dart';

class TransactionApiState {
  final List<Transaction> transactions;
  final double income;
  final double expense;
  final double saving;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> pagination;

  TransactionApiState({
    this.transactions = const [],
    this.isLoading = false,
    this.income = 0,
    this.expense = 0,
    this.saving = 0,
    this.error,
    this.pagination = const {},
  });

  TransactionApiState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    double? income,
    double? expense,
    double? saving,
    String? error,
    Map<String, dynamic>? pagination,
  }) {
    return TransactionApiState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      saving: saving ?? this.saving,
      error: error ?? this.error,
      pagination: pagination ?? this.pagination,
    );
  }
}

class TransactionApiNotifier extends StateNotifier<TransactionApiState> {
  final Ref ref;
  TransactionApiNotifier(this.ref) : super(TransactionApiState());

  Future<List<Transaction>> fetchRecentTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/recent/v1',
        'GET',
        queryParams: {'page': '1', 'limit': '5'},
      );

      final List<dynamic> transactionsData = response['data'] ?? [];
      final transactions = transactionsData
          .map((data) => Transaction.fromJson(data))
          .toList();

      state = state.copyWith(transactions: transactions, isLoading: false);

      return transactions;
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch transactions: ${e.toString()}',
      );
    }

    return [];
  }

  Future<TransactionSummary> fetchTransactionHistory({
    int page = 1,
    int limit = 15,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/history/v1',
        'GET',
        queryParams: {'page': '$page', 'limit': '$limit'},
      );

      final List<dynamic> transactionsData =
          response['data']['transactions'] ?? [];
      final transactions = transactionsData
          .map((data) => Transaction.fromJson(data))
          .toList();

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        pagination: response['data']['pagination'],
      );

      return TransactionSummary(
        transactions: transactions,
        pagination: response['data']['pagination'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch transaction history: ${e.toString()}',
      );
    }

    return TransactionSummary(transactions: [], pagination: {});
  }

  Future<List<Transaction>> addTransaction({
    required String title,
    required String type,
    required double amount,
    required String date,
    String? note,
    String? trackerId,
  }) async {
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      // `transactions/add/v1` -> Negative Balance allowed
      // `transactions/add/v2` -> Negative Balance not allowed
      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/add/v2',
        'POST',
        body: {
          'title': title,
          'type': type,
          'amount': amount,
          'date': date,
          if (note != null) 'note': note,
          'tracker_id': trackerId,
        },
      );

      final isSuccess = response['success'];

      if (!isSuccess) {
        final message = response['message'] ?? 'Failed to add transaction';
        state = state.copyWith(error: message);
        throw Exception(message);
      }

      final transactionData = response['data']['transaction'];
      final newTransaction = Transaction.fromJson(transactionData);

      final updatedWallet = response['data']['updatedWallet'];
      ref
          .read(walletProvider.notifier)
          .updateWallet(
            (updatedWallet['bank_balance'] as num).toDouble(),
            (updatedWallet['expense'] as num).toDouble(),
            (updatedWallet['income'] as num).toDouble(),
            (updatedWallet['saving'] as num).toDouble(),
          );

      // Mirror the server-side tracker.current_amount change locally.
      // Create: Expense += amount, Income -= amount. Saving is filtered out
      // by the frontend (tracker_id is always null for Saving).
      final createdTrackerId = transactionData['tracker_id'];
      if (createdTrackerId != null && transactionData['type'] != 'Saving') {
        final trackerDelta = transactionData['type'] == 'Income'
            ? -newTransaction.amount
            : newTransaction.amount;
        ref
            .read(trackerListProvider.notifier)
            .applyTrackerDelta(createdTrackerId, trackerDelta);
      }

      final updatedTransactions = [newTransaction, ...state.transactions];
      // Add to current state
      state = state.copyWith(transactions: updatedTransactions);

      return updatedTransactions;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<bool> deleteTransaction(String transactionId, String date) async {
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/delete/v1/$transactionId',
        'DELETE',
        body: {'date': date},
      );

      // Remove from current state
      state = state.copyWith(
        transactions: state.transactions
            .where((transaction) => transaction.id != transactionId)
            .toList(),
      );

      final wallet = response['data']['updatedWallet'];
      ref
          .read(walletProvider.notifier)
          .updateWallet(
            (wallet['bank_balance'] as num).toDouble(),
            (wallet['expense'] as num).toDouble(),
            (wallet['income'] as num).toDouble(),
            (wallet['saving'] as num).toDouble(),
          );

      // Reverse the tracker.current_amount change locally. Mirror of add:
      // Delete Expense → -amount, Delete Income → +amount.
      final deleted = response['data']['deletedTransaction'];
      final deletedTrackerId = deleted?['tracker_id'];
      if (deletedTrackerId != null && deleted['type'] != 'Saving') {
        final amount = (deleted['amount'] as num).toDouble();
        final trackerDelta = deleted['type'] == 'Income' ? amount : -amount;
        ref
            .read(trackerListProvider.notifier)
            .applyTrackerDelta(deletedTrackerId, trackerDelta);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete transaction: ${e.toString()}',
      );
      return false;
    }
  }

  // Attaches or detaches a tracker on an existing transaction.
  // Wallet + rollups are untouched by the backend; only the affected tracker's
  // current_amount changes -- mirror that locally in trackerListProvider.
  Future<Transaction?> updateTransactionTracker({
    required String transactionId,
    required String? trackerId,
  }) async {
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/set-tracker/v1/$transactionId',
        'PATCH',
        body: {'tracker_id': trackerId},
      );

      final updated = Transaction.fromJson(response['data']['transaction']);

      final updatedTrackers = response['data']['updatedTrackers'] as List?;
      if (updatedTrackers != null) {
        final trackerListNotifier = ref.read(trackerListProvider.notifier);
        for (final t in updatedTrackers) {
          trackerListNotifier.setTrackerCurrentAmount(
            t['id'] as String,
            (t['current_amount'] as num).toDouble(),
          );
        }
      }

      return updated;
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        error: 'Failed to update tracker: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<Transaction?> getTransactionDetailsById(String transactionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'transactions/details/v1/$transactionId',
        'GET',
      );

      final transactionData = response['data'];
      final transaction = Transaction.fromJson(transactionData);

      state = state.copyWith(isLoading: false);
      return transaction;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch transaction details: ${e.toString()}',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final transactionApiProvider =
    StateNotifierProvider<TransactionApiNotifier, TransactionApiState>((ref) {
      return TransactionApiNotifier(ref);
    });
