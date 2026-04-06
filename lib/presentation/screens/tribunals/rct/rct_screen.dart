import 'package:flutter/material.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';

class RCTScreen extends StatelessWidget {
  const RCTScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: customText("NCLAT", color: Colors.black, size: 20, weight: FontWeight.bold),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: customText(
          "Welcome to NCLAT Information Page",
          size: 20,
          weight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
