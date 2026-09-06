import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/utils/constants.dart';

class AddTrackerScreen extends ConsumerStatefulWidget {
  const AddTrackerScreen({super.key});

  @override
  ConsumerState<AddTrackerScreen> createState() => _AddTrackerScreenState();
}

class _AddTrackerScreenState extends ConsumerState<AddTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _initialAmountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _initialAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _budgetController.clear();
    _initialAmountController.clear();
    _descriptionController.clear();
  }

  void _addTracker() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final name = _nameController.text.trim();
      final budget = double.parse(_budgetController.text.trim());
      final initialAmount = _initialAmountController.text.trim().isEmpty
          ? 0.0
          : double.parse(_initialAmountController.text.trim());
      final description = _descriptionController.text.trim();

      try {
        // ignore: unused_local_variable
        final tracker = {
          'name': name,
          'budget': budget,
          'initialAmount': initialAmount,
          'description': description,
        };

        _clearForm();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tracker "$name" added successfully!'),
            backgroundColor: darkGreenColor,
            duration: const Duration(seconds: 2),
          ),
        );

        context.pop();
      } catch (err) {
        if (!mounted) return;
        final errorMessage = err
            .toString()
            .replaceFirst(RegExp(r'^Exception: \d+: '), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to add tracker',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: whiteColor,
                  ),
                ),
                Text(errorMessage, style: TextStyle(color: whiteColor)),
              ],
            ),
            backgroundColor: darkRedColor,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: darkRedColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildTrackerForm() {
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
                              hintText: 'Enter tracker name',
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

                          // Budget Field
                          TextFormField(
                            controller: _budgetController,
                            style: TextStyle(color: whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Budget',
                              hintText: 'Enter budget',
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
                                return 'Budget is required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Please enter a valid number';
                              }
                              if (double.parse(value.trim()) <= 0) {
                                return 'Budget must be greater than 0';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // Initial Amount Field
                          TextFormField(
                            controller: _initialAmountController,
                            style: TextStyle(color: whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Initial Amount',
                              hintText: 'Enter initial amount (default 0)',
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
                                return null;
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Please enter a valid number';
                              }
                              if (double.parse(value.trim()) < 0) {
                                return 'Initial amount cannot be negative';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // Description Field
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: TextStyle(color: whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter tracker description',
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
                      onPressed: _isSubmitting ? null : _addTracker,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenColor,
                        disabledBackgroundColor: greenColor.withAlpha(150),
                        foregroundColor: whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: whiteColor,
                              ),
                            )
                          : const Text(
                              'Add Tracker',
                              style: TextStyle(
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
        backgroundColor: greenColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: whiteColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Tracker',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        elevation: 0,
      ),
      body: SizedBox(width: double.infinity, child: _buildTrackerForm()),
    );
  }
}
