import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/theme/app_layout.dart';
import 'package:etribunals/core/utils/case_route_hint.dart';
import 'package:etribunals/core/widgets/custom_sidebar.dart';
import 'package:etribunals/core/widgets/followed_case_card.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onOpenMyCases;
  final VoidCallback? onOpenToday;
  final VoidCallback? onOpenMore;

  const DashboardScreen({
    super.key,
    this.isVisible = true,
    this.onOpenMyCases,
    this.onOpenToday,
    this.onOpenMore,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _tribunals = [
    {
      'name': 'NCLAT',
      'icon': Icons.account_balance_rounded,
      'subtitle': 'Company law appeals',
      'start': Color(0xFF14384A),
      'end': Color(0xFF1F5A6E),
    },
    {
      'name': 'NCLT',
      'icon': Icons.gavel_rounded,
      'subtitle': 'Company law trials',
      'start': Color(0xFF14685A),
      'end': Color(0xFF1C7A68),
    },
    {
      'name': 'UPREAT',
      'icon': Icons.home_work_rounded,
      'subtitle': 'UP real estate appeals',
      'start': Color(0xFF8A6A32),
      'end': Color(0xFFC4A265),
    },
    {
      'name': 'NGT',
      'icon': Icons.eco_rounded,
      'subtitle': 'Environment cases',
      'start': Color(0xFF2E6B3A),
      'end': Color(0xFF4C9A5B),
    },
    {
      'name': 'RCT',
      'icon': Icons.train_rounded,
      'subtitle': 'Railway claims',
      'start': Color(0xFF6B1E1E),
      'end': Color(0xFF8B2E2E),
    },
    {
      'name': 'DRT',
      'icon': Icons.account_balance_wallet_rounded,
      'subtitle': 'Debts recovery',
      'start': Color(0xFF14384A),
      'end': Color(0xFF1A4A6B),
    },
    {
      'name': 'CAT',
      'full': 'Central Administrative Tribunal',
      'icon': Icons.badge_rounded,
      'subtitle': 'Central service matters',
      'start': Color(0xFF3D4A6B),
      'end': Color(0xFF5A6B8A),
    },
    {
      'name': 'ITAT',
      'full': 'Income Tax Appellate Tribunal',
      'icon': Icons.receipt_long_rounded,
      'subtitle': 'Income tax appeals',
      'start': Color(0xFF1A4A3A),
      'end': Color(0xFF2D6B54),
    },
    {
      'name': 'CESTAT',
      'full': 'Customs, Excise & Service Tax Appellate Tribunal',
      'icon': Icons.local_shipping_rounded,
      'subtitle': 'Customs and excise appeals',
      'start': Color(0xFF4A3A1A),
      'end': Color(0xFF6B542D),
    },
    {
      'name': 'TDSAT',
      'full': 'Telecom Disputes Settlement and Appellate Tribunal',
      'icon': Icons.cell_tower_rounded,
      'subtitle': 'Telecom and broadcasting',
      'start': Color(0xFF1A3A5A),
      'end': Color(0xFF2D5580),
    },
    {
      'name': 'APTEL',
      'full': 'Appellate Tribunal for Electricity',
      'icon': Icons.bolt_rounded,
      'subtitle': 'Electricity appeals',
      'start': Color(0xFF5A4A1A),
      'end': Color(0xFF8A7028),
    },
    {
      'name': 'SAT',
      'full': 'Securities Appellate Tribunal',
      'icon': Icons.show_chart_rounded,
      'subtitle': 'SEBI / securities appeals',
      'start': Color(0xFF1E3A4A),
      'end': Color(0xFF2E5A6E),
    },
    {
      'name': 'AFT',
      'full': 'Armed Forces Tribunal',
      'icon': Icons.military_tech_rounded,
      'subtitle': 'Defence service matters',
      'start': Color(0xFF2A3A2A),
      'end': Color(0xFF3E5A3E),
    },
    {
      'name': 'NCDRC',
      'full': 'National Consumer Disputes Redressal Commission',
      'icon': Icons.groups_rounded,
      'subtitle': 'Consumer disputes',
      'start': Color(0xFF4A2A3A),
      'end': Color(0xFF6B3E54),
    },
    {
      'name': 'ATFP',
      'full': 'Appellate Tribunal under PMLA',
      'icon': Icons.policy_rounded,
      'subtitle': 'PMLA / FEMA appeals',
      'start': Color(0xFF3A2A4A),
      'end': Color(0xFF543E6B),
    },
    {
      'name': 'CGIT',
      'full': 'Central Government Industrial Tribunal',
      'icon': Icons.factory_rounded,
      'subtitle': 'Industrial disputes',
      'start': Color(0xFF3A3A2A),
      'end': Color(0xFF5A543E),
    },
  ];

  final _search = TextEditingController();
  List<BookmarkedCase> _bookmarks = [];
  List<BookmarkedCase> _recents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final bookmarks = await LocalStorageService.getBookmarks();
    final recents = await LocalStorageService.getRecents();
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _recents = recents;
      _loading = false;
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<Map<String, Object>> get _filteredTribunals {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _tribunals;
    return _tribunals.where((t) {
      final name = (t['name'] as String).toLowerCase();
      final sub = (t['subtitle'] as String).toLowerCase();
      final full = (t['full'] as String? ?? '').toLowerCase();
      return name.contains(q) || sub.contains(q) || full.contains(q);
    }).toList();
  }

  void _openTribunal(Map<String, Object> t) {
    if (t['soon'] == true) {
      Navigator.pushNamed(context, '/tribunal/coming-soon', arguments: t);
      return;
    }
    Navigator.pushNamed(context, '/tribunal/${(t['name'] as String).toLowerCase()}');
  }

  Future<void> _pickAndGo(String title, Map<String, String> routes) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final maxH = MediaQuery.sizeOf(context).height * 0.72;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final e in routes.entries)
                        ListTile(
                          leading: const Icon(Icons.account_balance_outlined, color: AppColors.accent),
                          title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, e.value),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice != null && mounted) {
      Navigator.pushNamed(context, choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = AppLayout.pagePadding(context);
    final top = MediaQuery.paddingOf(context).top;
    final date = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      drawer: const CustomSidebarMenu(),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                pad: pad,
                top: top,
                greeting: _greeting,
                date: date,
                search: _search,
                onSearch: (_) => setState(() {}),
                onOpenAccount: widget.onOpenMore ?? () {},
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 16, pad, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StatsRow(
                    tribunals: _tribunals.length,
                    saved: _bookmarks.length,
                    recents: _recents.length,
                    loading: _loading,
                    onSaved: widget.onOpenMyCases,
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Quick actions', action: 'Today', onAction: widget.onOpenToday),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _QuickChip(
                          icon: Icons.search_rounded,
                          label: 'Track case',
                          onTap: () => _pickAndGo('Track case status', const {
                            'NCLAT': '/nclat/track-case-status',
                            'NCLT': '/nclt/track-case-status',
                            'UPREAT': '/upreat/track-case-status',
                            'NGT': '/ngt/track-case-status',
                            'RCT': '/rct/track-case-status',
                            'DRT': '/drt/case-details',
                            'CAT': '/cat/case-status',
                            'ITAT': '/itat/case-status',
                            'CESTAT': '/cestat/case-details',
                            'TDSAT': '/tdsat/case-status',
                            'APTEL': '/aptel/case-status',
                            'SAT': '/sat/case-status',
                            'AFT': '/aft/case-status',
                            'NCDRC': '/ncdrc/case-status',
                            'ATFP': '/atfp/orders',
                            'CGIT': '/cgit/cause-list',
                          }),
                        ),
                        _QuickChip(
                          icon: Icons.list_alt_rounded,
                          label: 'Cause list',
                          onTap: () => _pickAndGo('View cause list', const {
                            'NCLAT': '/nclat/view-cause-list',
                            'NCLT': '/nclt/view-cause-list',
                            'UPREAT': '/upreat/view-cause-list',
                            'NGT': '/ngt/view-cause-list',
                            'RCT': '/rct/view-cause-list',
                            'DRT': '/drt/cause-list',
                            'CAT': '/cat/cause-list',
                            'ITAT': '/itat/notice-board',
                            'CESTAT': '/cestat/cause-list',
                            'TDSAT': '/tdsat/cause-list',
                            'APTEL': '/aptel/cause-list',
                            'SAT': '/sat/cause-list',
                            'AFT': '/aft/cause-list',
                            'NCDRC': '/ncdrc/cause-list',
                            'ATFP': '/atfp/cause-list',
                            'CGIT': '/cgit/cause-list',
                          }),
                        ),
                        _QuickChip(
                          icon: Icons.tv_rounded,
                          label: 'Display board',
                          onTap: () => _pickAndGo('Display board', const {
                            'NCLAT': '/nclat/display-board',
                            'NCLT': '/nclt/display-board',
                            'RCT': '/rct/display-board',
                            'CESTAT': '/cestat/display-board',
                            'APTEL': '/aptel/display-board',
                            'NCDRC': '/ncdrc/display-board',
                          }),
                        ),
                        _QuickChip(
                          icon: Icons.description_outlined,
                          label: 'Orders',
                          onTap: () => _pickAndGo('Judgement / orders', const {
                            'NCLAT': '/nclat/judgement',
                            'NCLT': '/nclt/order-judgement',
                            'UPREAT': '/upreat/order-judgement',
                            'NGT': '/ngt/judgements',
                            'RCT': '/rct/judgements',
                            'DRT': '/drt/orders',
                            'CAT': '/cat/daily-orders',
                            'ITAT': '/itat/orders',
                            'CESTAT': '/cestat/daily-orders',
                            'TDSAT': '/tdsat/daily-orders',
                            'APTEL': '/aptel/daily-orders',
                            'SAT': '/sat/orders',
                            'AFT': '/aft/orders',
                            'NCDRC': '/ncdrc/orders',
                            'ATFP': '/atfp/orders',
                            'CGIT': '/cgit/awards',
                          }),
                        ),
                        _QuickChip(
                          icon: Icons.bookmark_outline,
                          label: 'My cases',
                          onTap: widget.onOpenMyCases ?? () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (caseRouteHints(_search.text).isNotEmpty) ...[
                    const _SectionTitle(title: 'Open this case number in'),
                    const SizedBox(height: 8),
                    ...caseRouteHints(_search.text).map(
                      (hint) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0x3314384A)),
                            ),
                            leading: const Icon(Icons.manage_search_rounded, color: AppColors.accent),
                            title: Text(hint.label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                            subtitle: Text(hint.tribunal, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(context, hint.route),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const _SectionTitle(title: 'Tribunals', subtitle: 'Tap a court to search its records'),
                  const SizedBox(height: 12),
                  if (_filteredTribunals.isEmpty && caseRouteHints(_search.text).isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No tribunal matches your search', style: TextStyle(color: AppColors.textMuted))),
                    )
                  else if (_filteredTribunals.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredTribunals.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: AppLayout.gridCount(context),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: AppLayout.gridAspect(context),
                      ),
                      itemBuilder: (context, index) {
                        final t = _filteredTribunals[index];
                        return _TribunalCard(
                          name: t['name'] as String,
                          subtitle: t['subtitle'] as String,
                          icon: t['icon'] as IconData,
                          start: t['start'] as Color,
                          end: t['end'] as Color,
                          comingSoon: t['soon'] == true,
                          onTap: () => _openTribunal(t),
                        );
                      },
                    ),
                  if (_bookmarks.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(title: 'Saved cases', action: 'See all', onAction: widget.onOpenMyCases),
                    const SizedBox(height: 8),
                    ..._bookmarks.take(3).map((item) => FollowedCaseCard(item: item, compact: true)),
                  ],
                  if (_recents.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Recently viewed'),
                    const SizedBox(height: 8),
                    ..._recents.take(4).map((item) => FollowedCaseCard(item: item, compact: true)),
                  ],
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.tile,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Live in-app: NCLAT, NCLT, UPREAT, NGT, RCT, DRT, CAT, ITAT, CESTAT, TDSAT, APTEL, SAT, AFT, NCDRC, ATFP and CGIT. Always verify on the source before filing.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double pad;
  final double top;
  final String greeting;
  final String date;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final VoidCallback onOpenAccount;

  const _Header({
    required this.pad,
    required this.top,
    required this.greeting,
    required this.date,
    required this.search,
    required this.onSearch,
    required this.onOpenAccount,
  });

  @override
  Widget build(BuildContext context) {
    final title = 'eTribunals';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(pad, top + 6, pad, 14),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting · $date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onOpenAccount,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  child: Text(
                    'E',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SearchBar(controller: search, onChanged: onSearch),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search tribunal or case no.',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int tribunals;
  final int saved;
  final int recents;
  final bool loading;
  final VoidCallback? onSaved;

  const _StatsRow({
    required this.tribunals,
    required this.saved,
    required this.recents,
    required this.loading,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Live', value: '$tribunals', icon: Icons.verified_outlined)),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onSaved,
            child: _StatCard(label: 'Saved', value: loading ? '—' : '$saved', icon: Icons.bookmark_outline),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Recent', value: loading ? '—' : '$recents', icon: Icons.history)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.subtitle, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 108,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.accent),
              const Spacer(),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TribunalCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color start;
  final Color end;
  final bool comingSoon;
  final VoidCallback onTap;

  const _TribunalCard({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.start,
    required this.end,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(colors: [start, end], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: start.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 8))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const Spacer(),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  comingSoon ? 'Coming soon · $subtitle' : subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
