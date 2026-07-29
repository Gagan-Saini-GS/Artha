import 'package:flutter/material.dart';
import 'package:tracker/utils/constants.dart';

class SettingToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: greenColor,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: darkGrayColor,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: whiteColor,
            fontSize: 16,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: whiteColor,
          activeTrackColor: darkGreenColor,
          inactiveThumbColor: lightGrayColor,
          inactiveTrackColor: grayColor,
        ),
        onTap: () => onChanged(!value),
      ),
    );
  }
}
