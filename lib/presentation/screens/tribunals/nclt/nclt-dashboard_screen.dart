import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';

class NCLTDasboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {'title': 'Display board', 'route': '/nclt/display-board', 'icon': Icons.tv_outlined},
    {'title': 'Track case status', 'route': '/nclt/track-case-status', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/nclt/view-cause-list', 'icon': Icons.list_alt},
    {'title': 'Judgements / orders', 'route': '/nclt/order-judgement', 'icon': Icons.gavel},
    {'title': 'Notifications', 'route': '/nclt/notifications', 'icon': Icons.notifications_outlined},
    {'title': 'Circulars', 'route': '/nclt/circulars', 'icon': Icons.info_outline},
  ];

  NCLTDasboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('NCLT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'NCLT tools',
        subtitle: 'Official benches, cause lists, orders and notices',
        items: options,
      ),
    );
  }
}
