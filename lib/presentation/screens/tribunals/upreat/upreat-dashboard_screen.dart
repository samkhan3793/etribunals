import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';

class UPREATDasboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {'title': 'Track case status', 'route': '/upreat/track-case-status', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/upreat/view-cause-list', 'icon': Icons.list_alt},
    {'title': 'Judgements / orders', 'route': '/upreat/order-judgement', 'icon': Icons.gavel},
  ];

  UPREATDasboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('UPREAT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'UPREAT tools',
        subtitle: 'Lucknow Real Estate Appellate Tribunal — official public records',
        items: options,
      ),
    );
  }
}
