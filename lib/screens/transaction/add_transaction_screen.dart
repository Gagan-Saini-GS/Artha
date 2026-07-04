import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:tracker/enums/transaction_type.dart';
import 'package:tracker/models/transaction.dart';
import 'package:tracker/providers/transaction_provider.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/utils/formatDate.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isIncome = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isIncome = _tabController.index == 1;
        });
        // Clear form data when switching tabs
        _clearForm();
      }
    });
    _dateController.text = formatDateTime(_selectedDate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _amountController.clear();
    _selectedDate = DateTime.now();
    _dateController.text = formatDateTime(_selectedDate);
    _noteController.clear();
  }

  // This function now handles picking both date and time.
  Future<void> _selectDateAndTime(BuildContext context) async {
    // 1. Pick the Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: whiteColor, // selected date
              onPrimary: darkGrayColor, // selected date text
              surface: darkGrayColor, // dialog background
              onSurface: lightGrayColor.withAlpha(200), // calendar text:
            ),
            dialogTheme: DialogThemeData(backgroundColor: darkGrayColor),
          ),
          child: child!,
        );
      },
    );

    // If the user didn't cancel the date picker
    if (pickedDate != null) {
      // 2. Pick the Time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: whiteColor, // selected date
                onPrimary: darkGrayColor, // selected date text
                surface: darkGrayColor, // dialog background
                onSurface: lightGrayColor.withAlpha(200), // calendar text:
              ),
              dialogTheme: DialogThemeData(backgroundColor: darkGrayColor),
            ),
            child: child!,
          );
        },
      );

      // If the user didn't cancel the time picker
      if (pickedTime != null) {
        // 3. Combine the date and time into a new DateTime object
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          // Update the text field with the new formatted date and time
          _dateController.text = formatDateTime(_selectedDate);
        });
      }
    }
  }

  void _addTransaction() async {
    if (_formKey.currentState!.validate()) {
      // Here you would typically save the transaction to your database
      final transactionType = _isIncome
          ? 'Income'
          : isSaving
          ? 'Saving'
          : 'Expense';
      final name = _nameController.text.trim();
      final amount = double.parse(_amountController.text.trim());
      final note = _noteController.text.trim();

      final transaction = Transaction(
        id: '',
        name: name,
        amount: amount,
        note: note,
        date: _selectedDate,
        isIncome: _isIncome,
        type: _isIncome
            ? TransactionType.income
            : isSaving
            ? TransactionType.saving
            : TransactionType.expense,
      );

      try {
        final transactionController = ref.read(
          transactionListProvider.notifier,
        );
        transactionController.addTransaction(transaction);

        // Clear the form
        _clearForm();

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$transactionType added successfully! $name of ₹$amount',
            ),
            backgroundColor: darkGreenColor,
            duration: const Duration(seconds: 2),
          ),
        );

        context.pop();
      } catch (err) {
        Logger().e("Error: $err");
      }
    } else {
      if (!mounted) return;
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: darkRedColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildTransactionForm() {
    return Container(
      padding: EdgeInsets.all(14),
      height: double.infinity,
      decoration: BoxDecoration(
        color: darkGrayColor,
        boxShadow: [
          BoxShadow(
            color: blackColor.withAlpha(100),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Tab Bar - 50% width each
            Container(
              width: double.infinity,
              color: darkGrayColor,
              child: Row(
                children: [
                  // Expense Tab - 50% width
                  Expanded(
                    child: GestureDetector(
                      onTap: () => {_tabController.animateTo(0), _clearForm()},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isIncome
                              ? (isSaving ? blueColor : redColor)
                              : grayColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          isSaving ? 'Saving' : 'Expense',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isIncome ? whiteColor : lightGrayColor,
                            fontWeight: !_isIncome
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Income Tab - 50% width
                  Expanded(
                    child: GestureDetector(
                      onTap: () => {_tabController.animateTo(1), _clearForm()},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isIncome
                              ? greenColor
                              : grayColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'Income',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isIncome ? whiteColor : lightGrayColor,
                            fontWeight: _isIncome
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            // Form Fields - Takes available space
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Name',
                              hintText: 'Enter transaction name',
                              labelStyle: TextStyle(color: whiteColor),
                              hintStyle: TextStyle(color: whiteColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: whiteColor.withAlpha(200),
                                ),
                              ),
                              iconColor: whiteColor,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // Amount Field
                          TextFormField(
                            controller: _amountController,
                            style: TextStyle(color: whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              hintText: 'Enter amount',
                              labelStyle: TextStyle(color: whiteColor),
                              hintStyle: TextStyle(color: whiteColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: whiteColor.withAlpha(200),
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.currency_rupee_outlined,
                                color: lightGrayColor,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Amount is required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Please enter a valid number';
                              }
                              if (double.parse(value.trim()) <= 0) {
                                return 'Amount must be greater than 0';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // Date Field
                          TextFormField(
                            controller: _dateController,
                            style: TextStyle(color: whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Date',
                              hintText: 'Select date',
                              labelStyle: TextStyle(color: whiteColor),
                              hintStyle: TextStyle(color: whiteColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: whiteColor.withAlpha(200),
                                ),
                              ),
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: lightGrayColor,
                              ),
                            ),
                            readOnly: true,
                            onTap: () => _selectDateAndTime(context),
                          ),

                          const SizedBox(height: 15),

                          // Note Field
                          TextFormField(
                            controller: _noteController,
                            maxLines: 3,
                            style: TextStyle(color: whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Note',
                              hintText: 'Enter transaction note',
                              labelStyle: TextStyle(color: whiteColor),
                              hintStyle: TextStyle(color: whiteColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: whiteColor.withAlpha(200),
                                ),
                              ),
                            ),
                          ),

                          if (!_isIncome) ...[
                            const SizedBox(height: 15),
                            InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: whiteColor.withAlpha(200),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Is Saving?',
                                    style: TextStyle(color: whiteColor),
                                  ),
                                  Switch(
                                    value: isSaving,
                                    onChanged: (value) {
                                      setState(() {
                                        isSaving = value;
                                      });
                                    },
                                    activeThumbColor: blueColor,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),

                  // Add Button pinned at bottom, outside the scroll area
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _addTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isIncome
                            ? greenColor
                            : isSaving
                            ? blueColor
                            : redColor,
                        foregroundColor: whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Add ${_isIncome
                            ? 'Income'
                            : isSaving
                            ? 'Saving'
                            : 'Expense'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greenColor,
      appBar: AppBar(
        backgroundColor: _isIncome
            ? greenColor
            : isSaving
            ? blueColor
            : redColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: whiteColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add ${_isIncome
              ? "Income"
              : isSaving
              ? "Saving"
              : "Expense"}',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        elevation: 0,
      ),
      body: SizedBox(width: double.infinity, child: _buildTransactionForm()),
    );
  }
}
