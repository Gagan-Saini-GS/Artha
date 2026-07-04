import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/enums/timePeriod.dart';
import 'package:tracker/providers/chart_data_provider.dart';
import 'package:tracker/providers/transaction_filter_provider.dart';
import 'package:tracker/providers/transaction_rollup_api_provider.dart';
import 'package:tracker/utils/capitalize.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/utils/getTransactionType.dart';

class TimeFilterButtons extends ConsumerWidget {
  const TimeFilterButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionFilterController = ref.read(
      transactionFilterProvider.notifier,
    );
    final transactionFilterState = ref.watch(transactionFilterProvider);
    final chartDataController = ref.read(
      chartDataProvider(transactionFilterState.periodType).notifier,
    );
    final transactionRollupController = ref.read(
      transactionRollupApiProvider.notifier,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: TimePeriod.values.map((filter) {
        final isSelected = transactionFilterState.periodType == filter;

        return Expanded(
          child: GestureDetector(
            // Fetch chart data for the new time filter selected
            onTap: () async {
              transactionFilterController.setPeriodType(filter);
              final transactions = await transactionRollupController.getStats(
                filter,
                transactionFilterState.startDate,
                transactionFilterState.endDate,
                transactionFilterState.type,
              );

              chartDataController.updateChartFromTransactions(transactions);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? getColorByTransactionType(transactionFilterState.type)
                    : grayColor.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  filter.name.capitalize(),
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected
                        ? whiteColor
                        : lightGrayColor.withAlpha(200),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
