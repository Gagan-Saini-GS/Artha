import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/models/transaction.dart';
// import 'package:tracker/enums/transaction_type.dart';
import 'package:tracker/providers/transaction_provider.dart';
import 'package:tracker/providers/wallet_filter_provider.dart';
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
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // Fetch transaction history when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allTransactionListProvider.notifier).fetchTransactionHistory();
    });
  }

  Widget _searchDialog() {
    final walletFilterController = ref.read(walletFilterProvider.notifier);

    return AlertDialog(
      title: Text("Search Transaction", style: TextStyle(color: whiteColor)),
      backgroundColor: darkGrayColor,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name Field
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: whiteColor),
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter transaction name',
              labelStyle: TextStyle(color: whiteColor),
              hintStyle: TextStyle(color: whiteColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: whiteColor.withAlpha(200)),
              ),
              iconColor: whiteColor,
            ),
          ),
          const SizedBox(height: 15),

          // Amount Field
          TextFormField(
            controller: _amountController,
            style: TextStyle(color: whiteColor),
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: 'Enter amount',
              labelStyle: TextStyle(color: whiteColor),
              hintStyle: TextStyle(color: whiteColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: whiteColor.withAlpha(200)),
              ),
              prefixIcon: Icon(
                Icons.currency_rupee_outlined,
                color: lightGrayColor,
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null) return null;

              if (double.tryParse(value.trim()) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value.trim()) <= 0) {
                return 'Amount must be greater than 0';
              }
              return null;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            _nameController.clear();
            _amountController.clear();
            Navigator.pop(context);
            await walletFilterController.clearSearch();
          },
          child: Text(
            "Clear",
            style: TextStyle(color: lightGrayColor.withAlpha(150)),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await walletFilterController.searchTransactions(
              name: _nameController.text,
              amount: double.tryParse(_amountController.text),
            );
          },
          child: Text("Search", style: TextStyle(color: whiteColor)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(allTransactionListProvider);
    final transactions = transactionsState.transactions;
    final walletState = ref.watch(walletProvider);
    final walletFilterState = ref.watch(walletFilterProvider);

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
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _searchDialog(),
              );
            },
            icon: Icon(Icons.search, color: whiteColor),
          ),
        ],
      ),
      body:
          transactionsState.isLoading && transactions.isEmpty ||
              walletFilterState.isLoading
          ? Center(
              child: Loader(
                title: walletFilterState.isLoading
                    ? "Searching Transactions..."
                    : "Loading Transactions...",
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
                            onLoadMore: walletFilterState.isSearchMode
                                ? ref.read(walletFilterProvider.notifier).fetchNextPage
                                : ref.read(allTransactionListProvider.notifier).fetchNextPage,
                            hasMore: walletFilterState.isSearchMode
                                ? walletFilterState.hasMore
                                : transactionsState.hasMore,
                            isLoadingMore: walletFilterState.isSearchMode
                                ? walletFilterState.isLoadingMore
                                : transactionsState.isLoadingMore,
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
