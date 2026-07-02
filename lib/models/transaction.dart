import 'package:tracker/enums/transaction_type.dart';

class Transaction {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String note;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.type,
    this.note = "",
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
    );
  }

  @override
  String toString() {
    return 'Id: $id, Name: $name, Amount: $amount, Date: $date, isIncome: $isIncome, Note: $note, Type: $type';
  }
}
