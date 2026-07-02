import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/enums/dateformat.dart';
import 'package:tracker/models/transaction.dart';
import 'package:tracker/providers/chart_data_provider.dart';
import 'package:tracker/providers/transaction_filter_provider.dart';
import 'package:tracker/providers/transaction_rollup_api_provider.dart';
import 'package:tracker/screens/home/transaction_item.dart';
import 'package:tracker/screens/statistics/expense_type_dropdown.dart';
import 'package:tracker/screens/statistics/graph_screen.dart';
import 'package:tracker/screens/statistics/time_filter_button.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/utils/formatDate.dart';
import 'package:tracker/utils/formatDateWithLabel.dart';
import 'package:tracker/utils/getTransactionType.dart';
import 'package:tracker/widgets/bottom_nav_bar.dart';
import 'package:tracker/widgets/loader.dart';
import 'package:tracker/widgets/paginated_list_view.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  bool _isDateRangeLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch transaction history when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionFilterProvider.notifier).setDefault();

      final transactionFilterState = ref.read(transactionFilterProvider);
      ref
          .read(transactionRollupApiProvider.notifier)
          .getStats(
            transactionFilterState.periodType,
            transactionFilterState.startDate,
            transactionFilterState.endDate,
            transactionFilterState.type,
          );
    });
  }

  String _formatDateRange(DateTimeRange range) {
    return '${formatDateWithLabel(range.start.toIso8601String(), DateLabelFormat.MMMd)} - ${formatDateWithLabel(range.end.toIso8601String(), DateLabelFormat.MMMd)}';
  }

  @override
  Widget build(BuildContext context) {
    final transactionFilterController = ref.watch(
      transactionFilterProvider.notifier,
    );
    final transactionFilterState = ref.watch(transactionFilterProvider);
    final chartDataController = ref.read(
      chartDataProvider(transactionFilterState.periodType).notifier,
    );
    final rollupController = ref.read(transactionRollupApiProvider.notifier);
    final rollupDataState = ref.watch(transactionRollupApiProvider);

    return Scaffold(
      backgroundColor: darkGrayColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Statistics',
              style: TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),

            ...[
              Text(
                _formatDateRange(transactionFilterController.getDateRange()),
                style: TextStyle(
                  color: getColorByTransactionType(transactionFilterState.type),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range_outlined, color: whiteColor),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: transactionFilterController.getDateRange(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: whiteColor,
                        onPrimary: darkGrayColor,
                        surface: darkGrayColor,
                        onSurface: whiteColor,
                        surfaceContainerHigh: darkGrayColor,
                        surfaceContainer: darkGrayColor,
                        surfaceTint: Colors.transparent,
                      ),
                      datePickerTheme: DatePickerThemeData(
                        backgroundColor: darkGrayColor,
                        headerBackgroundColor: darkGrayColor,
                        headerForegroundColor: whiteColor,
                        surfaceTintColor: Colors.transparent,
                        rangeSelectionBackgroundColor: whiteColor.withAlpha(50),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (range != null) {
                transactionFilterController.setDateRange(
                  range.start,
                  range.end,
                );

                setState(() {
                  _isDateRangeLoading = true; // show loader
                });

                try {
                  final transactions = await rollupController.getStats(
                    transactionFilterState.periodType,
                    range.start,
                    range.end,
                    transactionFilterState.type,
                  );

                  chartDataController.updateChartFromTransactions(transactions);
                } finally {
                  setState(() => _isDateRangeLoading = false);
                }
              }
            },
          ),
        ],
      ),
      body: _isDateRangeLoading || rollupDataState.isLoading
          ? Center(
              child: Loader(
                title: getLoadingByTransactionType(transactionFilterState.type),
                backgroundColor: getColorByTransactionType(
                  transactionFilterState.type,
                ),
                foregroundColor: darkGrayColor,
                transparent: true,
                textStyle: TextStyle(color: whiteColor),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TimeFilterButtons(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                    child: ExpenseTypeDropdown(),
                  ),
                ),
                Divider(height: 1, color: grayColor, indent: 16, endIndent: 16),
                const SizedBox(height: 20),

                // Graph
                const ReusableLineChart(),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: whiteColor,
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: getColorByTransactionType(
                            transactionFilterState.type,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          rollupDataState.transactions.length.toString(),
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: rollupDataState.transactions.isEmpty
                      ? Center(
                          child: Text(
                            'No Transactions Yet.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: grayColor,
                            ),
                          ),
                        )
                      : PaginatedListView<Transaction>(
                          items: rollupDataState.transactions,
                          hasMore: rollupDataState.hasMore,
                          isLoadingMore: rollupDataState.isLoadingMore,
                          onLoadMore: rollupController.fetchNextPage,
                          itemBuilder: (context, transaction, index) {
                            return TransactionItem(
                              iconAsset: null,
                              title: transaction.name,
                              date: formatDateTimeWithMonthName(
                                transaction.date,
                              ),
                              amount:
                                  "${transaction.isIncome ? '+' : '-'} ₹${transaction.amount}",
                              isIncome: transaction.isIncome,
                              type: transaction.type,
                              transactionId: transaction.id,
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
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
