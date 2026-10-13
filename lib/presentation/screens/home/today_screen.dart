import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/hearing_date.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/followed_case_card.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:etribunals/data/services/bookmark_refresh_service.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<List<BookmarkedCase>> _future;

  static const _shortcuts = [
    {'title': 'NCLAT Cause List', 'route': '/nclat/view-cause-list'},
    {'title': 'NCLT Cause List', 'route': '/nclt/view-cause-list'},
    {'title': 'UPREAT Cause List', 'route': '/upreat/view-cause-list'},
    {'title': 'NGT Cause List', 'route': '/ngt/view-cause-list'},
    {'title': 'RCT Cause List', 'route': '/rct/view-cause-list'},
    {'title': 'DRT Cause List', 'route': '/drt/cause-list'},
    {'title': 'CAT Cause List', 'route': '/cat/cause-list'},
    {'title': 'ITAT Notice Board', 'route': '/itat/notice-board'},
    {'title': 'CESTAT Cause List', 'route': '/cestat/cause-list'},
    {'title': 'TDSAT Cause List', 'route': '/tdsat/cause-list'},
    {'title': 'APTEL Cause List', 'route': '/aptel/cause-list'},
    {'title': 'SAT Cause List', 'route': '/sat/cause-list'},
    {'title': 'AFT Cause List', 'route': '/aft/cause-list'},
    {'title': 'NCDRC Cause List', 'route': '/ncdrc/cause-list'},
    {'title': 'ATFP Cause List', 'route': '/atfp/cause-list'},
    {'title': 'CGIT Cause List', 'route': '/cgit/cause-list'},
    {'title': 'NCLAT Display Board', 'route': '/nclat/display-board'},
    {'title': 'NCLT Display Board', 'route': '/nclt/display-board'},
    {'title': 'RCT Display Board', 'route': '/rct/display-board'},
    {'title': 'CESTAT Display Board', 'route': '/cestat/display-board'},
    {'title': 'APTEL Display Board', 'route': '/aptel/display-board'},
    {'title': 'NCDRC Display Board', 'route': '/ncdrc/display-board'},
  ];

  @override
  void initState() {
    super.initState();
    _future = LocalStorageService.getBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      backgroundColor: AppColors.secondary,
      body: FutureBuilder<List<BookmarkedCase>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final today = <BookmarkedCase>[];
          final upcoming = <BookmarkedCase>[];
          final changed = items.where((e) => e.listingChanged).toList();
          for (final item in items) {
            final date = parseHearingDate(item.nextHearing);
            if (date == null) continue;
            if (isSameDay(date, now)) {
              today.add(item);
            } else if (date.isAfter(now) && date.difference(now).inDays <= 14) {
              upcoming.add(item);
            }
          }
          today.sort((a, b) => (b.listingChanged ? 1 : 0).compareTo(a.listingChanged ? 1 : 0));
          upcoming.sort((a, b) => parseHearingDate(a.nextHearing)!.compareTo(parseHearingDate(b.nextHearing)!));

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              await BookmarkRefreshService.refreshAll();
              if (!mounted) return;
              setState(() => _future = LocalStorageService.getBookmarks());
            },
            child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CourtBand(
                title: 'Followed today',
                subtitle: 'Pull down to refresh listing dates',
                icon: Icons.today_outlined,
              ),
              const SizedBox(height: 10),
              if (changed.isNotEmpty) ...[
                const Text('Dates that changed', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 8),
                ...changed.map((item) => FollowedCaseCard(item: item, highlight: today.contains(item))),
                const SizedBox(height: 12),
              ],
              if (today.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('No followed matter is listed for today.', style: TextStyle(color: AppColors.textMuted)),
                )
              else
                ...today.where((e) => !e.listingChanged).map((item) => FollowedCaseCard(item: item, highlight: true)),
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: 8),
                const CourtBand(
                  title: 'Next 14 days',
                  color: AppColors.stampBlue,
                  icon: Icons.event_note_outlined,
                ),
                const SizedBox(height: 10),
                ...upcoming.where((e) => !e.listingChanged).map((item) => FollowedCaseCard(item: item)),
              ],
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: false,
                  title: const Text('Public cause lists', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                  subtitle: const Text('Open only if you need a full board', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  children: [
                    ..._shortcuts.map(
                      (item) => ListTile(
                        dense: true,
                        title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                        onTap: () => Navigator.pushNamed(context, item['route']!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }
}
