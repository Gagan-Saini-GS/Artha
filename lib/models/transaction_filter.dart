import 'package:tracker/enums/timePeriod.dart';
import 'package:tracker/enums/transaction_type.dart';

class TransactionFilter {
  final TransactionType type;
  final TimePeriod periodType;
  final DateTime startDate;
  final DateTime endDate;

  const TransactionFilter({
    required this.type,
    required this.periodType,
    required this.startDate,
    required this.endDate,
  });

  factory TransactionFilter.defaultFilter() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 00, 00, 00, 000);
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    return TransactionFilter(
      type: TransactionType.expense,
      periodType: TimePeriod.daily,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Computes start/end for a preset period, always anchored to today.
  static ({DateTime start, DateTime end}) dateRangeFor(TimePeriod period) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 00, 00, 00, 000);
    final startOfToday = DateTime(now.year, now.month, now.day);

    final DateTime start = switch (period) {
      TimePeriod.daily => startOfToday.subtract(const Duration(days: 6)),
      TimePeriod.weekly => startOfToday.subtract(const Duration(days: 29)),
      TimePeriod.monthly => startOfToday.subtract(const Duration(days: 89)),
      TimePeriod.yearly => startOfToday.subtract(const Duration(days: 364)),
    };

    return (start: start, end: endOfToday);
  }

  // API-formatted values for rollups/stats query params.
  String get apiType => switch (type) {
    TransactionType.expense => 'Expense',
    TransactionType.income => 'Income',
    TransactionType.saving => 'Saving',
  };

  String get apiTimePeriodType => switch (periodType) {
    TimePeriod.daily => 'Daily',
    TimePeriod.weekly => 'Weekly',
    TimePeriod.monthly => 'Monthly',
    TimePeriod.yearly => 'Yearly',
  };

  String get apiStartDate => startDate.toIso8601String().split('T').first;
  String get apiEndDate => endDate.toIso8601String().split('T').first;

  TransactionFilter copyWith({
    TransactionType? type,
    TimePeriod? periodType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
