import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:flutter/material.dart';

class CESTATScreen extends StatelessWidget {
  CESTATScreen({super.key});

  final options = [
    {'title': 'Case details', 'route': '/cestat/case-details', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/cestat/cause-list', 'icon': Icons.list_alt},
    {'title': 'Court proceedings', 'route': '/cestat/proceedings', 'icon': Icons.menu_book_outlined},
    {'title': 'Daily orders', 'route': '/cestat/daily-orders', 'icon': Icons.description_outlined},
    {'title': 'Final orders', 'route': '/cestat/final-orders', 'icon': Icons.gavel},
    {'title': 'Final order search', 'route': '/cestat/final-search', 'icon': Icons.find_in_page_outlined},
    {'title': 'Display board', 'route': '/cestat/display-board', 'icon': Icons.tv_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('CESTAT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Case information and orders',
        subtitle: 'Official cestat.gov.in  ·  case details, cause list, proceedings, orders, display board',
        items: options,
      ),
    );
  }
}
