import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';

class NCLATScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {'title': 'Display Board', 'route': '/nclat/display-board', 'icon': Icons.dashboard},
    {'title': 'Track Case Status', 'route': '/nclat/track-case-status', 'icon': Icons.search},
    {'title': 'View Cause List', 'route': '/nclat/view-cause-list', 'icon': Icons.list_alt},
    {'title': 'Judgement/Orders', 'route': '/nclat/judgement', 'icon': Icons.description},
    {'title': 'Judgement Prior to 31-05-2021', 'route': '/nclat/priorjudement', 'icon': Icons.history},
    {'title': 'Daily Orders Prior to 31-05-2021', 'route': '/nclat/prior-daily-orders', 'icon': Icons.today},
    {'title': 'Daily Orders Registrar Court Prior to 31-05-2021', 'route': '/nclat/prior-daily-orders-registrar', 'icon': Icons.account_balance},
    {'title': 'Court Notice', 'route': '/nclat/court-notice', 'icon': Icons.notifications},
    {'title': 'Circulars/Orders/Notifications', 'route': '/nclat/circulars-orders-notifications', 'icon': Icons.info},
    {'title': 'Act & Rules', 'route': '/nclat/acts-rules', 'icon': Icons.rule},
  ];

  NCLATScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: customText("NCLAT Dashboard",
            size: 20, weight: FontWeight.w600, color: Colors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      backgroundColor: AppColors.secondary,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          final item = options[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, item['route']);
            },
            child: Card(
              color: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'],
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
