import 'package:etribunals/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSidebarMenu extends StatelessWidget {
  const CustomSidebarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.paper,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(gradient: AppColors.heroGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.account_balance, size: 28, color: AppColors.primary),
                ),
                SizedBox(height: 10),
                Text(
                  'eTribunals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Public records on this phone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
            title: const Text('Tribunals', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(context),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Live: NCLAT · NCLT · UPREAT · NGT · RCT · DRT · CAT · ITAT · CESTAT · TDSAT · APTEL · SAT · AFT · NCDRC · ATFP · CGIT',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
