import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/models/tracker.dart';
import 'package:tracker/providers/tracker_provider.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/utils/formatAmount.dart';
import 'package:tracker/widgets/loader.dart';
import 'package:tracker/widgets/paginated_list_view.dart';
import 'package:tracker/widgets/pull_to_refresh.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackerListProvider.notifier).fetchTrackers();
    });
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.track_changes_outlined, size: 64, color: grayColor),
                const SizedBox(height: 16),
                Text(
                  'No Trackers Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: grayColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first tracker',
                  style: TextStyle(fontSize: 14, color: grayColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerCard(Tracker tracker) {
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
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkGrayColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: whiteColor.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tracker.name,
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '₹${formatAmount(budget)}',
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (tracker.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tracker.description,
              style: TextStyle(
                color: lightGrayColor.withAlpha(200),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: grayColor.withAlpha(80),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${formatAmount(current)} spent',
                style: TextStyle(
                  color: lightGrayColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isOverBudget
                    ? 'Over by ₹${formatAmount(current - budget)}'
                    : '₹${formatAmount(budget - current)} left',
                style: TextStyle(
                  color: isOverBudget ? redColor : lightGrayColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(trackerListProvider);
    final trackers = trackerState.trackers;

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
          'Trackers',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: trackerState.isLoading && trackers.isEmpty
          ? Center(
              child: Loader(
                title: 'Loading Trackers...',
                transparent: true,
                foregroundColor: whiteColor,
                backgroundColor: darkGrayColor,
                textStyle: TextStyle(color: whiteColor),
              ),
            )
          : PullToRefresh(
              onRefresh: () =>
                  ref.read(trackerListProvider.notifier).fetchTrackers(),
              child: trackers.isEmpty
                  ? _buildEmptyState()
                  : PaginatedListView<Tracker>(
                      items: trackers,
                      onLoadMore: ref
                          .read(trackerListProvider.notifier)
                          .fetchNextPage,
                      hasMore: trackerState.hasMore,
                      isLoadingMore: trackerState.isLoadingMore,
                      itemBuilder: (context, tracker, index) =>
                          _buildTrackerCard(tracker),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: greenColor,
        onPressed: () => context.push("/add-tracker"),
        child: Icon(Icons.add, color: whiteColor),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }
}
