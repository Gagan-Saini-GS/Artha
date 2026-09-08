import 'package:tracker/enums/transaction_type.dart';

// Sentinel used by copyWith to distinguish "omit" from "set to null" for
// nullable fields (e.g. detaching a tracker by passing trackerId: null).
const _sentinel = Object();

class Transaction {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String note;
  final TransactionType type;
  final String? trackerId;

  Transaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.type,
    this.note = "",
    this.trackerId,
  });

  static TransactionType getTypeValue(String type) {
    if (type == "Expense") {
      return TransactionType.expense;
    } else if (type == "Income") {
      return TransactionType.income;
    } else if (type == "Saving") {
      return TransactionType.saving;
    }

    return TransactionType.expense;
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      name: json['title'] ?? json['name'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      isIncome: json['type'] == 'Income',
      type: getTypeValue(json['type']),
      note: json['note'] ?? '',
      trackerId: json['tracker_id'],
    );
  }

  Transaction copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? date,
    bool? isIncome,
    TransactionType? type,
    String? note,
    Object? trackerId = _sentinel,
  }) {
    return Transaction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      type: type ?? this.type,
      note: note ?? this.note,
      trackerId: identical(trackerId, _sentinel)
          ? this.trackerId
          : trackerId as String?,
    );
  }

  @override
  String toString() {
    return 'Id: $id, Name: $name, Amount: $amount, Date: $date, isIncome: $isIncome, Note: $note, Type: $type';
  }
}
