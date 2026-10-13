import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:flutter/material.dart';

class RCTScreen extends StatelessWidget {
  RCTScreen({super.key});

  final options = [
    {'title': 'Track Case Status', 'route': '/rct/track-case-status', 'icon': Icons.search},
    {'title': 'View Cause List', 'route': '/rct/view-cause-list', 'icon': Icons.list_alt},
    {'title': 'Judgements', 'route': '/rct/judgements', 'icon': Icons.gavel},
    {'title': 'Display Board', 'route': '/rct/display-board', 'icon': Icons.tv_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: customText('RCT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Railway Claims Tribunal',
        subtitle: 'Official eRCT case status, cause lists, judgements and today\'s board',
        items: options,
      ),
    );
  }
}
