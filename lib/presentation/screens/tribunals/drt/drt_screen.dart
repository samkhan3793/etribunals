import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:flutter/material.dart';

class DRTScreen extends StatelessWidget {
  DRTScreen({super.key});

  final options = [
    {'title': 'Case details', 'route': '/drt/case-details', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/drt/cause-list', 'icon': Icons.list_alt},
    {'title': 'Orders', 'route': '/drt/orders', 'icon': Icons.gavel},
    {'title': 'Case transfer', 'route': '/drt/case-transfer', 'icon': Icons.swap_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('DRT / DRAT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Debts Recovery Tribunals',
        subtitle: 'Official drt.gov.in  ·  case details, cause lists, orders, RC/TRC',
        items: options,
      ),
    );
  }
}
