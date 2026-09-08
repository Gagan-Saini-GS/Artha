import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/enums/transaction_type.dart';
import 'package:tracker/models/tracker.dart';
import 'package:tracker/providers/tracker_provider.dart';
import 'package:tracker/providers/tracker_transactions_provider.dart';
import 'package:tracker/providers/transaction_provider.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/utils/formatAmount.dart';
import 'package:tracker/utils/formatDate.dart';
import 'package:tracker/utils/getTransactionType.dart';
import 'package:tracker/widgets/loader.dart';
// import 'package:tracker/utils/constants.dart';

class TransactionDetailsBottomSheet extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailsBottomSheet({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailsBottomSheet> createState() =>
      _TransactionDetailsBottomSheetState();
}

class _TransactionDetailsBottomSheetState
    extends ConsumerState<TransactionDetailsBottomSheet> {
  bool _isUpdatingTracker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(transactionListProvider.notifier)
          .getTransactionDetailsById(widget.transactionId);
      // Ensure trackers are loaded so we can render the name + picker.
      final trackerState = ref.read(trackerListProvider);
      if (trackerState.trackers.isEmpty && !trackerState.isLoading) {
        ref.read(trackerListProvider.notifier).fetchTrackers();
      }
    });
  }

  Future<Tracker?> _pickTracker(List<Tracker> trackers) async {
    return showDialog<Tracker>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: darkGrayColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick a tracker',
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (trackers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No trackers yet. Create one first.',
                    style: TextStyle(color: lightGrayColor),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: trackers.length,
                    separatorBuilder: (_, __) => Divider(
                      color: whiteColor.withAlpha(20),
                      height: 1,
                    ),
                    itemBuilder: (context, i) {
                      final t = trackers[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          t.name,
                          style: TextStyle(color: whiteColor),
                        ),
                        subtitle: Text(
                          '₹${formatAmount(t.currentAmount)} / ₹${formatAmount(t.budgetAmount)}',
                          style: TextStyle(
                            color: lightGrayColor.withAlpha(200),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.of(dialogContext).pop(t),
                      );
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: lightGrayColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attachTracker(List<Tracker> trackers) async {
    final picked = await _pickTracker(trackers);
    if (picked == null || !mounted) return;
    await _submit(picked.id);
  }

  Future<void> _detachTracker(String? oldTrackerId) async {
    await _submit(null, detachedTrackerId: oldTrackerId);
  }

  Future<void> _submit(String? trackerId, {String? detachedTrackerId}) async {
    if (_isUpdatingTracker) return;
    setState(() => _isUpdatingTracker = true);
    try {
      await ref
          .read(transactionListProvider.notifier)
          .updateTransactionTracker(
            transactionId: widget.transactionId,
            trackerId: trackerId,
          );

      // If we're viewing the details of the tracker we just detached from,
      // drop the row from that screen's list too.
      if (detachedTrackerId != null) {
        final trackerTxnState = ref.read(trackerTransactionsProvider);
        if (trackerTxnState.trackerId == detachedTrackerId) {
          ref
              .read(trackerTransactionsProvider.notifier)
              .removeTransaction(widget.transactionId);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trackerId == null ? 'Tracker removed' : 'Tracker attached',
          ),
          backgroundColor: darkGreenColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (err) {
      Logger().e('Tracker update failed: $err');
      if (!mounted) return;
      final message = err
          .toString()
          .replaceFirst(RegExp(r'^Exception: \d+: '), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update tracker: $message'),
          backgroundColor: darkRedColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingTracker = false);
    }
  }

  Widget _buildTrackerSection(String? trackerId, List<Tracker> trackers) {
    final currentTracker = trackerId == null
        ? null
        : trackers.where((t) => t.id == trackerId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracker',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: blackColor.withAlpha(80),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: whiteColor.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.track_changes_outlined,
                color: trackerId != null ? greenColor : grayColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  trackerId == null
                      ? 'No tracker attached'
                      : (currentTracker?.name ?? 'Tracker'),
                  style: TextStyle(
                    color: trackerId != null ? whiteColor : lightGrayColor,
                    fontSize: 16,
                    fontWeight: trackerId != null
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_isUpdatingTracker)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: whiteColor,
                  ),
                )
              else if (trackerId == null)
                TextButton.icon(
                  onPressed: () => _attachTracker(trackers),
                  icon: Icon(Icons.add, size: 18, color: greenColor),
                  label: Text(
                    'Attach',
                    style: TextStyle(color: greenColor),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () => _detachTracker(trackerId),
                  icon: Icon(Icons.close, size: 18, color: redColor),
                  label: Text(
                    'Remove',
                    style: TextStyle(color: redColor),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trancsationState = ref.watch(transactionListProvider);

    if (trancsationState.isLoading) {
      return Container(
        color: darkGrayColor,
        child: Loader(
          title: "Loading Transaction Details",
          transparent: true,
          foregroundColor: whiteColor,
          backgroundColor: darkGrayColor,
          textStyle: TextStyle(color: whiteColor),
        ),
      );
    }

    final details = trancsationState.selectedTransaction;
    final trackers = ref.watch(
      trackerListProvider.select((s) => s.trackers),
    );

    return Container(
      padding: const EdgeInsets.all(24.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkGrayColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: whiteColor.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  details.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: whiteColor,
                  ),
                ),
              ),
              // Text(
              //   details.name,
              //   style: const TextStyle(
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //     // overflow: TextOverflow.ellipsis,
              //   ),
              //   maxLines: 3,
              // ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: getColorByTransactionType(details.type),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  color: getColorByTransactionType(details.type).withAlpha(50),
                ),
                child: Text(
                  (getTransactionType(details.type)).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: getColorByTransactionType(details.type),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text(
                "Amount",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: whiteColor,
                ),
              ),
              const Spacer(),
              Text(
                '${details.type == TransactionType.saving
                    ? ''
                    : details.isIncome
                    ? '+ '
                    : '- '}₹${formatAmount(double.tryParse(cleanAmount(details.amount.toString())) ?? 0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: getColorByTransactionType(details.type),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Date",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: whiteColor,
            ),
          ),
          Text(
            formatDateTimeWithMonthName(details.date),
            style: TextStyle(
              fontSize: 18,
              color: lightGrayColor.withAlpha(200),
            ),
          ),
          const SizedBox(height: 16),

          if (details.note != "") ...[
            Text("Note", style: TextStyle(color: whiteColor, fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              details.note,
              style: TextStyle(fontSize: 18, color: lightGrayColor),
            ),

            const SizedBox(height: 16),
          ],

          if (details.type != TransactionType.saving)
            _buildTrackerSection(details.trackerId, trackers),
        ],
      ),
    );
  }
}
