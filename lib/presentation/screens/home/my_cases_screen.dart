import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/followed_case_card.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:etribunals/data/services/bookmark_refresh_service.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';

class MyCasesScreen extends StatefulWidget {
  final VoidCallback onOpenTribunals;
  final bool isVisible;

  const MyCasesScreen({
    super.key,
    required this.onOpenTribunals,
    this.isVisible = true,
  });

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  late Future<List<BookmarkedCase>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(MyCasesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      setState(_reload);
    }
  }

  void _reload() {
    _future = LocalStorageService.getBookmarks();
  }

  Future<void> _refresh() async {
    final result = await BookmarkRefreshService.refreshAll();
    if (!mounted) return;
    setState(_reload);
    await _future;
    if (!mounted) return;
    final msg = result.changed > 0
        ? 'Listing date updated for ${result.changed} case${result.changed == 1 ? '' : 's'}.'
        : result.checked > 0
            ? 'Dates checked. No changes.'
            : 'Dates refresh for NCDRC and CGIT bookmarks. Others keep the saved date.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cases')),
      backgroundColor: AppColors.secondary,
      body: FutureBuilder<List<BookmarkedCase>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.tile,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.bookmark_added_outlined, size: 36, color: AppColors.accent),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Follow cases you care about',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Search any tribunal case and tap bookmark. They stay on this phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: widget.onOpenTribunals,
                      icon: const Icon(Icons.account_balance_outlined),
                      label: const Text('Browse tribunals'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CourtBand(
                      title: 'Followed matters',
                      subtitle: '${items.length} case${items.length == 1 ? '' : 's'}  ·  tap row to open full record',
                      icon: Icons.folder_special_outlined,
                    ),
                  );
                }
                final item = items[index - 1];
                return FollowedCaseCard(
                  item: item,
                  onDelete: () async {
                    await LocalStorageService.removeBookmark(item.id);
                    await _refresh();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
