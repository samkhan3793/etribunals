import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';

class NCLTDasboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {'title': 'Display Board', 'route': '/nclt/display-board', 'icon': Icons.dashboard},
    {'title': 'Track Case Status', 'route': '/nclt/track-case-status', 'icon': Icons.search},
    {'title': 'View Cause List', 'route': '/nclt/view-cause-list', 'icon': Icons.list_alt},
    {'title': 'Judgement/Orders', 'route': '/nclt/order-judgement', 'icon': Icons.description},
    {'title': 'Notifications', 'route': '/nclt/notifications', 'icon': Icons.notifications},
    {'title': 'Circulars', 'route': '/nclt/circulars', 'icon': Icons.info},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: customText("NCLT Dashboard",
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
