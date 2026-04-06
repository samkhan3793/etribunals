import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';

class PublicOrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: customText("Public Order"),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: customText(
          "View public orders here.",
          size: 20,
          weight: FontWeight.bold,
        ),
      ),
    );
  }
}
