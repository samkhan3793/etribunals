import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/case_share.dart';
import 'package:etribunals/core/utils/hearing_date.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:etribunals/data/services/followed_case_opener.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class FollowedCaseCard extends StatefulWidget {
  final BookmarkedCase item;
  final VoidCallback? onDelete;
  final bool highlight;
  final bool compact;

  const FollowedCaseCard({
    super.key,
    required this.item,
    this.onDelete,
    this.highlight = false,
    this.compact = false,
  });

  static Color stripe(String tribunal) {
    switch (tribunal.toUpperCase()) {
      case 'NCLT':
        return const Color(0xFF0E7A62);
      case 'UPREAT':
        return const Color(0xFFB8862B);
      case 'NGT':
        return const Color(0xFF1F6B32);
      case 'RCT':
        return const Color(0xFF8B2E2E);
      case 'DRT':
        return const Color(0xFF1A4A6B);
      case 'CAT':
        return const Color(0xFF3D4A6B);
      case 'ITAT':
        return const Color(0xFF1A4A3A);
      case 'CESTAT':
        return const Color(0xFF4A3A1A);
      case 'TDSAT':
        return const Color(0xFF1A3A5A);
      case 'APTEL':
        return const Color(0xFF5A4A1A);
      case 'SAT':
        return const Color(0xFF1E3A4A);
      case 'AFT':
        return const Color(0xFF2A3A2A);
      case 'NCDRC':
        return const Color(0xFF4A2A3A);
      case 'ATFP':
        return const Color(0xFF3A2A4A);
      case 'CGIT':
        return const Color(0xFF3A3A2A);
      default:
        return AppColors.stampBlue;
    }
  }

  @override
  State<FollowedCaseCard> createState() => _FollowedCaseCardState();
}

class _FollowedCaseCardState extends State<FollowedCaseCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = FollowedCaseCard.stripe(item.tribunal);
    final caseNo = item.caseNo.trim().isNotEmpty ? item.caseNo.trim() : item.filingNo.trim();
    final parties = item.title.trim();
    final hearing = parseHearingDate(item.nextHearing);
    final hearingLabel = hearing == null
        ? (item.nextHearing ?? '').trim()
        : DateFormat('dd-MM-yyyy').format(hearing);

    return Padding(
      padding: EdgeInsets.only(bottom: widget.compact ? 8 : 10),
      child: Material(
        color: widget.highlight ? const Color(0xFFE8F6EF) : AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: widget.highlight ? color : const Color(0x3314384A)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () => FollowedCaseOpener.open(context, item),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: color),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                MetaChip(label: item.tribunal, color: color),
                                if (widget.highlight) ...[
                                  const SizedBox(width: 6),
                                  const MetaChip(label: 'Listed today', color: AppColors.stampRed),
                                ],
                                if (item.listingChanged) ...[
                                  const SizedBox(width: 6),
                                  const MetaChip(label: 'Date changed', color: AppColors.stampBlue),
                                ],
                                const Spacer(),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  tooltip: 'Share',
                                  onPressed: () => shareBookmarkedCase(item),
                                  icon: const Icon(Icons.share_outlined, size: 16, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              caseNo.isEmpty ? 'Case no. pending' : caseNo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                letterSpacing: 0.15,
                              ),
                            ),
                            if (hearingLabel.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.event, size: 14, color: color),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Next listing  ',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                                  ),
                                  Text(
                                    hearingLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (parties.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                parties,
                                maxLines: widget.compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!widget.compact)
              Container(
                color: const Color(0xFFF3EEE6),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _open = !_open),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        child: Row(
                          children: [
                            Text(
                              _open ? 'Hide particulars' : 'More particulars',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.stampBlue,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _open ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: AppColors.stampBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_open)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: Column(
                          children: [
                            _kv('Diary / filing', item.filingNo),
                            _kv('Case number', item.caseNo),
                            _kv('Parties', parties),
                            _kv('Next listing', hearingLabel),
                            if ((item.previousNextHearing ?? '').trim().isNotEmpty)
                              _kv('Earlier listing', item.previousNextHearing!),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  await copyBookmarkedCase(item);
                                  Fluttertoast.showToast(msg: 'Copied case details');
                                },
                                icon: const Icon(Icons.copy, size: 16, color: AppColors.stampBlue),
                                label: const Text('Copy', style: TextStyle(color: AppColors.stampBlue, fontSize: 12.5)),
                              ),
                            ),
                            if (widget.onDelete != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: widget.onDelete,
                                  icon: const Icon(Icons.bookmark_remove_outlined, size: 16, color: AppColors.stampRed),
                                  label: const Text('Unfollow', style: TextStyle(color: AppColors.stampRed, fontSize: 12.5)),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    if (v.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              k,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
