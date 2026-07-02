import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/models/transaction.dart';
// import 'package:tracker/enums/transaction_type.dart';
import 'package:tracker/providers/transaction_provider.dart';
import 'package:tracker/providers/wallet_provider.dart';
import 'package:tracker/screens/home/transaction_item.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/utils/formatAmount.dart';
import 'package:tracker/utils/formatDate.dart';
import 'package:tracker/widgets/loader.dart';
import 'package:tracker/widgets/paginated_list_view.dart';
import 'package:tracker/widgets/pull_to_refresh.dart';
import '../../widgets/bottom_nav_bar.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch transaction history when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allTransactionListProvider.notifier).fetchTransactionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(allTransactionListProvider);
    final transactions = transactionsState.transactions;
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: darkGrayColor,
      appBar: AppBar(
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        backgroundColor: greenColor,
        foregroundColor: whiteColor,
        elevation: 0,
      ),
      body: transactionsState.isLoading && transactions.isEmpty
          ? Center(
              child: Loader(
                title: "Loading Transactions...",
                transparent: true,
                foregroundColor: whiteColor,
                backgroundColor: darkGrayColor,
                textStyle: TextStyle(color: whiteColor),
              ),
            )
          : Column(
              children: [
                // Header section with total balance
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: walletState.bankBalance >= 0
                        ? darkGreenColor.withAlpha(200)
                        : darkRedColor.withAlpha(175),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${formatAmount(walletState.bankBalance)}',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Transaction list
                Expanded(
                  child: PullToRefresh(
                    onRefresh: () => ref
                        .read(allTransactionListProvider.notifier)
                        .fetchTransactionHistory(),
                    child: transactions.isEmpty
                        ? ListView(
                            physics: AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 64,
                                        color: grayColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Transactions Yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: grayColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Your transaction history will appear here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: grayColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : PaginatedListView<Transaction>(
                            items: transactions,
                            onLoadMore: ref
                                .read(allTransactionListProvider.notifier)
                                .fetchNextPage,
                            hasMore: transactionsState.hasMore,
                            isLoadingMore: transactionsState.isLoadingMore,
                            itemBuilder: (context, transaction, index) {
                              return TransactionItem(
                                iconAsset: null,
                                title: transaction.name,
                                date: formatDateTimeWithMonthName(
                                  transaction.date,
                                ),
                                amount: transaction.amount.toStringAsFixed(2),
                                isIncome: transaction.isIncome,
                                transactionId: transaction.id,
                                type: transaction.type,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: greenColor,
        onPressed: () {
          context.push('/add-transaction');
        },
        elevation: 4,
        child: Icon(Icons.add, color: whiteColor),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
