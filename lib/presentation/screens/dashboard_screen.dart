import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/custom_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> tribunals = [
    {'name': 'NCLAT', 'icon': Icons.account_balance},
    {'name': 'NCLT', 'icon': Icons.gavel},
    {'name': 'UPREAT', 'icon': Icons.account_balance_wallet},
    {'name': 'NGT', 'icon': Icons.eco},
    {'name': 'RCT', 'icon': Icons.receipt_long},
    {'name': 'DRT', 'icon': Icons.account_balance_outlined},
  ];

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: customText(
          "Dashboard",
          size: 18,
          weight: FontWeight.bold,
        ),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.secondary,
      drawer: CustomSidebarMenu(userName: user?.email ?? 'Guest'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: tribunals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final tribunal = tribunals[index];
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/tribunal/${tribunal['name'].toString().toLowerCase()}',
                );
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
                      tribunal['icon'],
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    customText(
                      tribunal['name'],
                      size: 16,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
