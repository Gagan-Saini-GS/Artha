import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/widgets/setting_toggle_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkTheme = true;
  bool _allowNegativeBalance = false;
  // final bool _cashTracking = false;
  // final bool _creditTracking = false;
  // final bool _trackGoals = false;
  // final bool _trackBudgets = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGrayColor,
      appBar: AppBar(
        backgroundColor: darkGreenColor,
        elevation: 0,
        iconTheme: IconThemeData(color: whiteColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: whiteColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          SettingToggleTile(
            title: 'Dark Theme',
            value: _darkTheme,
            onChanged: (v) => setState(() => _darkTheme = v),
          ),
          SettingToggleTile(
            title: 'Allow Negative Balance',
            value: _allowNegativeBalance,
            onChanged: (v) => setState(() => _allowNegativeBalance = v),
          ),
          // V2
          // SettingToggleTile(
          //   title: 'Cash Tracking',
          //   value: _cashTracking,
          //   onChanged: (v) => setState(() => _cashTracking = v),
          // ),
          // SettingToggleTile(
          //   title: 'Credit Tracking',
          //   value: _creditTracking,
          //   onChanged: (v) => setState(() => _creditTracking = v),
          // ),
          // SettingToggleTile(
          //   title: 'Track Goals',
          //   value: _trackGoals,
          //   onChanged: (v) => setState(() => _trackGoals = v),
          // ),
          // SettingToggleTile(
          //   title: 'Track Budgets',
          //   value: _trackBudgets,
          //   onChanged: (v) => setState(() => _trackBudgets = v),
          // ),
        ],
      ),
    );
  }
}
