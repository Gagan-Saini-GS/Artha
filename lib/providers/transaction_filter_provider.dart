import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/enums/timePeriod.dart';
import 'package:tracker/enums/transaction_type.dart';
import 'package:tracker/models/transaction_filter.dart';

class TransactionFilterNotifier extends StateNotifier<TransactionFilter> {
  TransactionFilterNotifier() : super(TransactionFilter.defaultFilter());

  void setType(TransactionType type) {
    state = state.copyWith(type: type);
  }

  // Switching period recomputes start/end automatically.
  void setPeriodType(TimePeriod periodType) {
    state = state.copyWith(periodType: periodType);
  }

  // Custom date range from the date picker — period stays unchanged.
  void setDateRange(DateTime start, DateTime end) {
    final endOfDay = DateTime(end.year, end.month, end.day, 00, 00, 00, 000);
    state = state.copyWith(startDate: start, endDate: endOfDay);
  }

  // Set Default Value in state
  void setDefault() {
    state = TransactionFilter.defaultFilter();
  }

  DateTimeRange getDateRange() {
    return DateTimeRange(start: state.startDate, end: state.endDate);
  }
}

final transactionFilterProvider =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilter>(
      (ref) => TransactionFilterNotifier(),
    );
