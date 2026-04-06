import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';

class NGTScreen extends StatelessWidget {
  const NGTScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: customText("NCLAT"),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: customText(
          "Welcome to NCLAT Information Page",
          size: 20,
          weight: FontWeight.bold,
        ),
      ),
    );
  }
}
