import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/utils/constants.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackColor,
      appBar: AppBar(
        backgroundColor: darkGreenColor,
        elevation: 0,
        iconTheme: IconThemeData(color: whiteColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: whiteColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Trackers',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Text("Trackers", style: TextStyle(color: whiteColor)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: greenColor,
        onPressed: () => context.push("/add-tracker"),
        child: Icon(Icons.add, color: whiteColor),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }
}
