import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:flutter/material.dart';

class CaseSummaryCard extends StatefulWidget {
  final Map<String, String> fields;
  final String actionLabel;
  final bool loading;
  final VoidCallback onAction;

  const CaseSummaryCard({
    super.key,
    required this.fields,
    required this.actionLabel,
    required this.loading,
    required this.onAction,
  });

  @override
  State<CaseSummaryCard> createState() => _CaseSummaryCardState();
}

class _CaseSummaryCardState extends State<CaseSummaryCard> {
  bool _open = false;

  static const _leadKeys = ['Case no.', 'Case Number', 'Diary / filing', 'Filing Number', 'Party', 'Party Name', 'Status'];

  @override
  Widget build(BuildContext context) {
    final entries = widget.fields.entries.where((e) => e.key.isNotEmpty).toList();
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = widget.fields[k];
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    final caseNo = pick(['Case no.', 'Case Number']);
    final diary = pick(['Diary / filing', 'Filing Number', 'Diary']);
    final party = pick(['Party', 'Party Name']);
    final status = pick(['Status']);
    final rest = entries.where((e) => !_leadKeys.contains(e.key)).toList();

    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0x3314384A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: AppColors.accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (status.isNotEmpty) MetaChip(label: status, color: AppColors.stampBlue),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          caseNo.isNotEmpty ? caseNo : (diary.isEmpty ? 'Matter' : diary),
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.2,
                          ),
                        ),
                        if (caseNo.isNotEmpty && diary.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Diary / filing  $diary',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                          ),
                        ],
                        if (party.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            party,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 42,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.loading ? null : widget.onAction,
                            child: widget.loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(widget.actionLabel, style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (rest.isNotEmpty)
            Container(
              color: const Color(0xFFF3EEE6),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _open = !_open),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            _open ? 'Hide other fields' : 'Other fields',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.stampBlue),
                          ),
                          const Spacer(),
                          Icon(_open ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.stampBlue),
                        ],
                      ),
                    ),
                  ),
                  if (_open)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Column(
                        children: rest
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        e.key,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        e.value.isEmpty ? 'N/A' : e.value,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String fieldStr(Map<String, dynamic> details, String key, [String fallback = 'N/A']) {
  final value = details[key];
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}
