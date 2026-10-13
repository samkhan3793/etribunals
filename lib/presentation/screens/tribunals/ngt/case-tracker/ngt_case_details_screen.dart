import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/utils/ngt_case_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class NgtCaseDetailsScreen extends StatefulWidget {
  final NgtCaseHit hit;
  final String html;

  const NgtCaseDetailsScreen({super.key, required this.hit, required this.html});

  @override
  State<NgtCaseDetailsScreen> createState() => _NgtCaseDetailsScreenState();
}

class _NgtCaseDetailsScreenState extends State<NgtCaseDetailsScreen> {
  List<NgtListingRow> _listings = const [];
  bool _loadingOrders = true;
  bool _showAllFields = false;

  static const _priority = [
    'Case Number',
    'Filing Number',
    'Party Name',
    'Status',
    'Last Listed',
    'Next Date',
    'Next Listing',
  ];

  @override
  void initState() {
    super.initState();
    _listings = parseNgtListingRows(widget.html);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final rows = await NgtCaseClient.instance.fetchListingRows(
        widget.hit.detailsUrl,
        caseHtml: widget.html,
      );
      if (!mounted) return;
      setState(() {
        _listings = rows;
        _loadingOrders = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = parseNgtCaseFields(widget.html);
    final filing = fields['Filing Number']?.isNotEmpty == true ? fields['Filing Number']! : widget.hit.diaryNo;
    final caseNo = fields['Case Number']?.isNotEmpty == true ? fields['Case Number']! : widget.hit.caseNo;
    final title = fields['Party Name']?.isNotEmpty == true ? fields['Party Name']! : widget.hit.party;
    final nextHearing = fields['Last Listed'] ?? fields['Next Date'] ?? fields['Next Listing'];
    final status = fields['Status'] ?? widget.hit.status;
    final official = widget.hit.detailsUrl.isEmpty ? TribunalSources.officialHome('NGT') : widget.hit.detailsUrl;

    final lead = <MapEntry<String, String>>[];
    final rest = <MapEntry<String, String>>[];
    for (final key in _priority) {
      final v = fields[key];
      if (v != null && v.trim().isNotEmpty) lead.add(MapEntry(key, v));
    }
    for (final e in fields.entries) {
      if (e.key.isEmpty) continue;
      if (_priority.contains(e.key)) continue;
      rest.add(e);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NGT case record'),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('NGT', filing),
              tribunal: 'NGT',
              filingNo: filing,
              caseNo: caseNo,
              title: title.isEmpty ? 'NGT $filing' : title,
              nextHearing: nextHearing,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'ngt_html',
              payload: widget.html,
              sourceUrl: widget.hit.detailsUrl,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.secondary,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: 'National Green Tribunal',
            subtitle: status.isEmpty ? 'Case record' : status,
            color: const Color(0xFF1F6B32),
            icon: Icons.eco_outlined,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x3314384A)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  color: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CASE NUMBER',
                        style: TextStyle(color: Color(0xFFC4A265), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caseNo.isEmpty ? filing : caseNo,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12.5, height: 1.35),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Column(
                    children: lead.map(_kv).toList(),
                  ),
                ),
                if (rest.isNotEmpty)
                  Container(
                    color: const Color(0xFFF3EEE6),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _showAllFields = !_showAllFields),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Text(
                                  _showAllFields ? 'Hide remaining particulars' : 'Remaining particulars',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.stampBlue),
                                ),
                                const Spacer(),
                                Icon(_showAllFields ? Icons.expand_less : Icons.expand_more, color: AppColors.stampBlue),
                              ],
                            ),
                          ),
                        ),
                        if (_showAllFields)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                            child: Column(children: rest.map(_kv).toList()),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const CourtBand(
            title: 'Listing / orders',
            subtitle: 'Date first · PDF under the date',
            color: AppColors.stampBlue,
            icon: Icons.history,
          ),
          const SizedBox(height: 10),
          if (_loadingOrders)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_listings.isEmpty)
            const Text(
              'No listing orders were found for this case.',
              style: TextStyle(color: AppColors.textMuted, height: 1.35),
            )
          else
            ..._listings.map((row) => _ListingDocket(row: row)),
          SourceFooter(tribunal: 'NGT', officialUrl: official),
        ],
      ),
    );
  }

  Widget _kv(MapEntry<String, String> e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              e.key,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              e.value.isEmpty ? 'N/A' : e.value,
              style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingDocket extends StatefulWidget {
  final NgtListingRow row;
  const _ListingDocket({required this.row});

  @override
  State<_ListingDocket> createState() => _ListingDocketState();
}

class _ListingDocketState extends State<_ListingDocket> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x3314384A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const MetaChip(label: 'Listed', color: AppColors.stampBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.listingDate.isEmpty ? 'Date N/A' : row.listingDate,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          if (row.pdfs.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No PDF for this date', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: row.pdfs
                    .map(
                      (pdf) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () => InAppDocumentScreen.open(context, pdf.url, title: pdf.label),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: Text(pdf.label, style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (row.coram.isNotEmpty || row.uploadDate.isNotEmpty)
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
                            _open ? 'Hide coram / upload' : 'Coram / upload',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (row.uploadDate.isNotEmpty)
                            Text('Uploaded  ${row.uploadDate}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          if (row.coram.isNotEmpty)
                            Text(row.coram, style: const TextStyle(fontSize: 12.5, height: 1.3, color: AppColors.ink)),
                        ],
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
