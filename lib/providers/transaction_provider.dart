import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/enums/transaction_type.dart';
import 'package:tracker/models/transaction_summary.dart';
import 'package:tracker/providers/transaction_api_provider.dart';
import 'package:tracker/utils/getTransactionType.dart';
import '../models/transaction.dart';

class TransactionState {
  final List<Transaction> transactions;
  final double income;
  final double expense;
  final double saving;
  final Transaction selectedTransaction;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  bool isLoading;

  TransactionState({
    this.transactions = const [],
    this.income = 0,
    this.expense = 0,
    this.saving = 0,
    Transaction? selectedTransaction,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoading = false,
  }) : selectedTransaction =
           selectedTransaction ??
           Transaction(
             id: '',
             amount: 0,
             name: '',
             date: DateTime(2025),
             isIncome: true,
             type:
                 TransactionType.expense, // Using goal as it's not implemented
             note: "",
           );

  TransactionState copyWith({
    List<Transaction>? transactions,
    double? income,
    double? expense,
    double? saving,
    Transaction? selectedTransaction,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    bool? isLoading,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      selectedTransaction: selectedTransaction ?? this.selectedTransaction,
      isLoading: isLoading ?? this.isLoading,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      saving: saving ?? this.saving,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class TransactionListNotifier extends StateNotifier<TransactionState> {
  final Ref ref;
  TransactionListNotifier(this.ref) : super(TransactionState());

  Future<void> addTransaction(
    Transaction transaction, {
    String? trackerId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedTransactions = await ref
          .read(transactionApiProvider.notifier)
          .addTransaction(
            title: transaction.name,
            type: getTransactionType(transaction.type),
            amount: transaction.amount,
            date: transaction.date.toIso8601String(),
            note: transaction.note,
            trackerId: trackerId,
          );

      if (updatedTransactions.isNotEmpty) {
        ref
            .read(recentTransactionListProvider.notifier)
            .updateRecentTransactions(updatedTransactions.first);
        state = state.copyWith(transactions: updatedTransactions);
      }
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(transactions: []);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchRecentTransactions() async {
    state = state.copyWith(isLoading: true);

    try {
      final List<Transaction> transactions = await ref
          .read(transactionApiProvider.notifier)
          .fetchRecentTransactions();
      state = state.copyWith(transactions: transactions);
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(transactions: []);
      throw Exception("Can't fetch recent transactions");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchTransactionHistory() async {
    state = state.copyWith(isLoading: true);

    try {
      final TransactionSummary summary = await ref
          .read(transactionApiProvider.notifier)
          .fetchTransactionHistory(page: 1, limit: 15);

      state = state.copyWith(transactions: summary.transactions);
    } catch (e) {
      Logger().e(e);
      throw Exception("Can't fetch transactions");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> getTransactionDetailsById(String transactionId) async {
    state = state.copyWith(isLoading: true);

    try {
      final Transaction? transaction = await ref
          .read(transactionApiProvider.notifier)
          .getTransactionDetailsById(transactionId);

      state = state.copyWith(selectedTransaction: transaction);
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(selectedTransaction: null);
      throw Exception("Can't get transaction details");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> deleteTransaction(String transactionId, String date) async {
    state = state.copyWith(isLoading: true);
    try {
      final bool success = await ref
          .read(transactionApiProvider.notifier)
          .deleteTransaction(transactionId, date);

      if (success) {
        // Remove the deleted transaction from the current state
        final updatedTransactions = state.transactions
            .where((transaction) => transaction.id != transactionId)
            .toList();
        state = state.copyWith(transactions: updatedTransactions);
      }

      return success;
    } catch (e) {
      Logger().e(e);
      throw Exception("Can't delete transaction, Please try again");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionState>(
      (ref) => TransactionListNotifier(ref),
    );

// Recent Transactions Provider
class RecentTransactionListNotifier extends StateNotifier<TransactionState> {
  final Ref ref;
  RecentTransactionListNotifier(this.ref) : super(TransactionState());

  Future<void> fetchRecentTransactions() async {
    state = state.copyWith(isLoading: true);
    try {
      final List<Transaction> transactions = await ref
          .read(transactionApiProvider.notifier)
          .fetchRecentTransactions();
      state = state.copyWith(transactions: transactions);
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(transactions: []);
      throw Exception("Can't fetch recent transactions");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateRecentTransactions(Transaction newTransaction) {
    state = state.copyWith(
      transactions: [newTransaction, ...state.transactions.take(4)],
    );
  }
}

final recentTransactionListProvider =
    StateNotifierProvider<RecentTransactionListNotifier, TransactionState>(
      (ref) => RecentTransactionListNotifier(ref),
    );

// All Transactions Provider
class AllTransactionListNotifier extends StateNotifier<TransactionState> {
  final Ref ref;
  AllTransactionListNotifier(this.ref) : super(TransactionState());

  Future<void> fetchTransactionHistory() async {
    if (state.isLoadingMore) return; // Don't reset while a page is fetching.
    state = state.copyWith(isLoading: true);
    try {
      final TransactionSummary summary = await ref
          .read(transactionApiProvider.notifier)
          .fetchTransactionHistory(page: 1, limit: 15);

      state = state.copyWith(
        transactions: summary.transactions,
        currentPage: summary.pagination['currentPage'],
        hasMore: summary.pagination['hasMore'],
      );
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        transactions: [],
        expense: 0,
        income: 0,
        saving: 0,
      );
      throw Exception("Can't fetch transactions");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final TransactionSummary summary = await ref
          .read(transactionApiProvider.notifier)
          .fetchTransactionHistory(page: state.currentPage + 1, limit: 15);
      state = state.copyWith(
        transactions: [...state.transactions, ...summary.transactions],
        currentPage: summary.pagination['currentPage'],
        hasMore: summary.pagination['hasMore'],
      );
    } catch (e) {
      Logger().e(e);
      throw Exception("Can't fetch next page transactions");
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void updateTransactions(List<Transaction> newTransactions) {
    state = state.copyWith(transactions: newTransactions);
  }
}

final allTransactionListProvider =
    StateNotifierProvider<AllTransactionListNotifier, TransactionState>(
      (ref) => AllTransactionListNotifier(ref),
    );
