import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/theme/app_layout.dart';
import 'package:flutter/material.dart';

class FeatureGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String? heading;
  final String? subtitle;

  const FeatureGrid({
    super.key,
    required this.items,
    this.heading,
    this.subtitle,
  });

  static const _starts = [
    Color(0xFF14384A),
    Color(0xFF14685A),
    Color(0xFF8A6A32),
    Color(0xFF2E6B3A),
    Color(0xFF1F5A6E),
    Color(0xFF5A3D7A),
  ];
  static const _ends = [
    Color(0xFF1F5A6E),
    Color(0xFF1C7A68),
    Color(0xFFC4A265),
    Color(0xFF4C9A5B),
    Color(0xFF2A7A8A),
    Color(0xFF7A5AA0),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = AppLayout.pagePadding(context);
    return CustomScrollView(
      slivers: [
        if (heading != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 16, pad, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 24),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppLayout.gridCount(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return FeatureTile(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  start: _starts[index % _starts.length],
                  end: _ends[index % _ends.length],
                  onTap: () => Navigator.pushNamed(context, item['route'] as String),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}

class FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color start;
  final Color end;
  final VoidCallback onTap;

  const FeatureTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [start, end],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: start.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 6)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
