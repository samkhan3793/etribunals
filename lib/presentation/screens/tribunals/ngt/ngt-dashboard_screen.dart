import 'package:flutter/material.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';

class NGTDasboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {'title': 'Track Case Status', 'route': '/ngt/track-case-status', 'icon': Icons.search},
    {'title': 'View Cause List', 'route': '/ngt/view-cause-list', 'icon': Icons.list_alt},
    {'title': 'Judgements', 'route': '/ngt/judgements', 'icon': Icons.gavel},
  ];

  NGTDasboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: customText('NGT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'NGT tools',
        subtitle: 'Official case status, daily cause lists, and judgements',
        items: options,
      ),
    );
  }
}
