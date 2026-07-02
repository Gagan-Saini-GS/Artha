import 'package:flutter/material.dart';
import 'package:tracker/enums/transaction_type.dart';
import 'package:tracker/utils/constants.dart';

String getTransactionType(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
      return "Expense";
    case TransactionType.income:
      return "Income";
    case TransactionType.saving:
      return "Saving";
  }
}

Color getColorByTransactionType(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
      return redColor;
    case TransactionType.income:
      return greenColor;
    case TransactionType.saving:
      return blueColor;
  }
}

IconData getIconByType(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
      return Icons.trending_down_outlined;
    case TransactionType.income:
      return Icons.trending_up_outlined;
    case TransactionType.saving:
      return Icons.account_balance_outlined;
  }
}

String getLoadingByTransactionType(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
      return "Loading Expenses...";
    case TransactionType.income:
      return "Loading Incomes...";
    case TransactionType.saving:
      return "Loading Savings...";
  }
}
