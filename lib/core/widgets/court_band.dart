import 'package:etribunals/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CourtBand extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final IconData icon;

  const CourtBand({
    super.key,
    required this.title,
    this.subtitle,
    this.color = AppColors.primary,
    this.icon = Icons.account_balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.82)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, height: 1.25),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? fg;

  const MetaChip({super.key, required this.label, required this.color, this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg ?? Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
