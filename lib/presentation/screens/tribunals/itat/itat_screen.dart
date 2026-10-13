import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:flutter/material.dart';

class ITATScreen extends StatelessWidget {
  ITATScreen({super.key});

  final options = [
    {'title': 'Case status', 'route': '/itat/case-status', 'icon': Icons.search},
    {'title': 'Tribunal orders', 'route': '/itat/orders', 'icon': Icons.gavel},
    {'title': 'Notice board', 'route': '/itat/notice-board', 'icon': Icons.campaign_outlined},
    {'title': 'Special bench orders', 'route': '/itat/special-bench', 'icon': Icons.account_balance},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('ITAT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Judicial information',
        subtitle: 'Official itat.gov.in  ·  case status, orders, notice board, special bench',
        items: options,
      ),
    );
  }
}
