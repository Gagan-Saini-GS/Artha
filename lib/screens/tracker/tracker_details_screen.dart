import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/models/tracker.dart';
import 'package:tracker/models/transaction.dart';
import 'package:tracker/providers/tracker_provider.dart';
import 'package:tracker/providers/tracker_transactions_provider.dart';
import 'package:tracker/screens/home/transaction_item.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/utils/formatAmount.dart';
import 'package:tracker/utils/formatDate.dart';
import 'package:tracker/widgets/loader.dart';
import 'package:tracker/widgets/paginated_list_view.dart';
import 'package:tracker/widgets/pull_to_refresh.dart';

class TrackerDetailsScreen extends ConsumerStatefulWidget {
  final Tracker tracker;
  const TrackerDetailsScreen({super.key, required this.tracker});

  @override
  ConsumerState<TrackerDetailsScreen> createState() =>
      _TrackerDetailsScreenState();
}

class _TrackerDetailsScreenState extends ConsumerState<TrackerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackerTransactionsProvider.notifier).fetch(widget.tracker.id);
    });
  }

  Widget _buildSummaryCard(Tracker tracker) {
    final budget = tracker.budgetAmount;
    final current = tracker.currentAmount;
    final progress = budget > 0 ? (current / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = current > budget && budget > 0;
    final barColor = isOverBudget
        ? redColor
        : progress >= 0.75
        ? Color(0xFFE8A335)
        : greenColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: darkGreenColor.withAlpha(200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tracker.description.isNotEmpty) ...[
            Text(
              tracker.description,
              style: TextStyle(color: whiteColor.withAlpha(220), fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      color: whiteColor.withAlpha(180),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${formatAmount(current)}',
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(
                      color: whiteColor.withAlpha(180),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${formatAmount(budget)}',
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: blackColor.withAlpha(80),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              isOverBudget
                  ? 'Over by ₹${formatAmount(current - budget)}'
                  : '₹${formatAmount(budget - current)} left',
              style: TextStyle(
                color: isOverBudget ? redColor : whiteColor.withAlpha(220),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        'Transactions',
        style: TextStyle(
          color: whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: grayColor),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: grayColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a transaction and pick this tracker',
              style: TextStyle(fontSize: 13, color: grayColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    return TransactionItem(
      iconAsset: null,
      title: transaction.name,
      date: formatDateTimeWithMonthName(transaction.date),
      amount: transaction.amount.toStringAsFixed(2),
      isIncome: transaction.isIncome,
      transactionId: transaction.id,
      type: transaction.type,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the live tracker from the list provider so wallet/transaction
    // changes elsewhere reflect here. Fall back to the one passed via `extra`
    // if it's no longer in the list (e.g. list not yet loaded).
    final liveTracker = ref.watch(
      trackerListProvider.select(
        (s) => s.trackers.where((t) => t.id == widget.tracker.id).firstOrNull,
      ),
    );
    final tracker = liveTracker ?? widget.tracker;
    final state = ref.watch(trackerTransactionsProvider);
    final transactions = state.transactions;

    return Scaffold(
      backgroundColor: blackColor,
      appBar: AppBar(
        backgroundColor: darkGreenColor,
        elevation: 0,
        iconTheme: IconThemeData(color: whiteColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: whiteColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tracker.name,
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: PullToRefresh(
        onRefresh: () =>
            ref.read(trackerTransactionsProvider.notifier).fetch(tracker.id),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSummaryCard(tracker)),
            SliverToBoxAdapter(child: _buildSectionHeader()),
            if (state.isLoading && transactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Loader(
                    title: 'Loading Transactions...',
                    transparent: true,
                    foregroundColor: whiteColor,
                    backgroundColor: darkGrayColor,
                    textStyle: TextStyle(color: whiteColor),
                  ),
                ),
              )
            else if (transactions.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyTransactions())
            else
              SliverFillRemaining(
                hasScrollBody: true,
                child: PaginatedListView<Transaction>(
                  items: transactions,
                  onLoadMore: ref
                      .read(trackerTransactionsProvider.notifier)
                      .fetchNextPage,
                  hasMore: state.hasMore,
                  isLoadingMore: state.isLoadingMore,
                  itemBuilder: (context, transaction, index) =>
                      _buildTransactionTile(transaction),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
