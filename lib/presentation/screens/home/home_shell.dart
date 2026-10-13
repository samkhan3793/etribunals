import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/data/services/followed_case_opener.dart';
import 'package:etribunals/data/services/hearing_reminder_service.dart';
import 'package:etribunals/presentation/screens/dashboard_screen.dart';
import 'package:etribunals/presentation/screens/home/more_screen.dart';
import 'package:etribunals/presentation/screens/home/my_cases_screen.dart';
import 'package:etribunals/presentation/screens/home/today_screen.dart';
import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    HearingReminderService.instance.tapPayload.addListener(_onNotificationTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNotificationTap());
  }

  @override
  void dispose() {
    HearingReminderService.instance.tapPayload.removeListener(_onNotificationTap);
    super.dispose();
  }

  Future<void> _onNotificationTap() async {
    final payload = HearingReminderService.instance.takePayload();
    if (payload == null || !mounted) return;
    setState(() => _index = 1);
    if (payload == HearingReminderService.testPayload) return;
    final item = await HearingReminderService.instance.caseForPayload(payload);
    if (item == null || !mounted) return;
    await FollowedCaseOpener.open(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            isVisible: _index == 0,
            onOpenMyCases: () => setState(() => _index = 1),
            onOpenToday: () => setState(() => _index = 2),
            onOpenMore: () => setState(() => _index = 3),
          ),
          MyCasesScreen(
            isVisible: _index == 1,
            onOpenTribunals: () => setState(() => _index = 0),
          ),
          const TodayScreen(),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            label: 'Tribunals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'My Cases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
      ),
    );
  }
}
