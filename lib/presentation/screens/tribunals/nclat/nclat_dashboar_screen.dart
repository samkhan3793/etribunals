import 'package:flutter/material.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/constants/app_colors.dart';

class NCLATScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {'title': 'Display board', 'route': '/nclat/display-board', 'icon': Icons.tv_outlined},
    {'title': 'Track case status', 'route': '/nclat/track-case-status', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/nclat/view-cause-list', 'icon': Icons.list_alt},
    {'title': 'Judgements / orders', 'route': '/nclat/judgement', 'icon': Icons.gavel},
    {'title': 'Judgements before May 2021', 'route': '/nclat/priorjudement', 'icon': Icons.history},
    {'title': 'Daily orders before May 2021', 'route': '/nclat/prior-daily-orders', 'icon': Icons.today_outlined},
    {'title': 'Registrar orders before May 2021', 'route': '/nclat/prior-daily-orders-registrar', 'icon': Icons.account_balance_outlined},
    {'title': 'Court notices', 'route': '/nclat/court-notice', 'icon': Icons.notifications_outlined},
    {'title': 'Circulars & notifications', 'route': '/nclat/circulars-orders-notifications', 'icon': Icons.info_outline},
    {'title': 'Acts & rules', 'route': '/nclat/acts-rules', 'icon': Icons.rule},
  ];

  NCLATScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('NCLAT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'NCLAT tools',
        subtitle: 'Official appeals, cause lists, orders, notices — Delhi & Chennai',
        items: options,
      ),
    );
  }
}
