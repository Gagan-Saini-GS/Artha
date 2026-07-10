import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';

class WalletState {
  final String id;
  final double bankBalance;
  final double totalExpense;
  final double totalIncome;
  final double totalSaving;
  final String userId;
  final bool isLoading;
  final String? error;

  WalletState({
    this.id = "",
    this.bankBalance = 0,
    this.totalExpense = 0,
    this.totalIncome = 0,
    this.totalSaving = 0,
    this.userId = "",
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    String? id,
    double? bankBalance,
    double? totalExpense,
    double? totalIncome,
    double? totalSaving,
    String? userId,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      id: id ?? this.id,
      bankBalance: bankBalance ?? this.bankBalance,
      totalExpense: totalExpense ?? this.totalExpense,
      totalIncome: totalIncome ?? this.totalIncome,
      totalSaving: totalSaving ?? this.totalSaving,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return "Bank Balance: $bankBalance, Expense: $totalExpense, Income: $totalIncome, Saving: $totalSaving";
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final Ref ref;

  // WalletNotifier(this.ref) : super(WalletState());
  WalletNotifier(this.ref) : super(WalletState()) {
    getWalletDetails();
  }

  Future<WalletState> getWalletDetails() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);

      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'wallet/details/v1',
        'GET',
      );

      final dynamic walletDetails = response['data'];
      final WalletState wallet = WalletState(
        id: walletDetails['id'],
        bankBalance: (walletDetails['bank_balance'] as num).toDouble(),
        totalExpense: (walletDetails['expense'] as num).toDouble(),
        totalIncome: (walletDetails['income'] as num).toDouble(),
        totalSaving: (walletDetails['saving'] as num).toDouble(),
        userId: walletDetails['user_id'],
      );

      state = state.copyWith(
        id: wallet.id,
        bankBalance: wallet.bankBalance,
        totalExpense: wallet.totalExpense,
        totalIncome: wallet.totalIncome,
        totalSaving: wallet.totalSaving,
        userId: wallet.userId,
        isLoading: false,
      );

      return wallet;
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch wallet details: ${e.toString()}',
      );
    }

    return WalletState();
  }

  void updateWallet(
    double newBankBalance,
    double newExpense,
    double newIncome,
    double newSaving,
  ) {
    state = state.copyWith(
      bankBalance: newBankBalance,
      totalExpense: newExpense,
      totalIncome: newIncome,
      totalSaving: newSaving,
    );
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  return WalletNotifier(ref);
});
