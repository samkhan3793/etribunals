import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/ngt_case_client.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/case-tracker/ngt_case_details_screen.dart';
import 'package:flutter/material.dart';

class NgtJudgementResultsScreen extends StatefulWidget {
  final List<Map<String, String>> rows;
  final bool hasMore;
  final String zoneType;
  final String fromDate;
  final String toDate;
  final String orderBy;
  final String captcha;

  const NgtJudgementResultsScreen({
    super.key,
    required this.rows,
    required this.hasMore,
    required this.zoneType,
    required this.fromDate,
    required this.toDate,
    required this.orderBy,
    required this.captcha,
  });

  @override
  State<NgtJudgementResultsScreen> createState() => _NgtJudgementResultsScreenState();
}

class _NgtJudgementResultsScreenState extends State<NgtJudgementResultsScreen> {
  late final List<Map<String, String>> _rows = List.of(widget.rows);
  late bool _hasMore = widget.hasMore;
  int _page = 0;
  bool _loadingMore = false;
  String? _opening;

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = await NgtCaseClient.instance.searchJudgements(
        zoneType: widget.zoneType,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        orderBy: widget.orderBy,
        captcha: widget.captcha,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _page += 1;
        _rows.addAll(next.rows);
        _hasMore = next.hasMore && next.rows.isNotEmpty;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasMore = false;
        _loadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openPdf(String url) {
    return InAppDocumentScreen.open(context, url, title: 'NGT order / judgement');
  }

  Future<void> _openPdfForCase(Map<String, String> row) async {
    final caseUrl = row['case'];
    if (caseUrl == null || caseUrl.isEmpty) return;
    setState(() => _opening = 'pdf:$caseUrl');
    try {
      final listings = await NgtCaseClient.instance.fetchListingRows(caseUrl);
      final date = row['Date of Listing'] ?? '';
      NgtOrderLink? pdf;
      for (final listing in listings) {
        if (date.isNotEmpty && listing.listingDate == date && listing.pdfs.isNotEmpty) {
          pdf = listing.pdfs.first;
          break;
        }
      }
      if (pdf == null) {
        for (final listing in listings) {
          if (listing.pdfs.isNotEmpty) {
            pdf = listing.pdfs.first;
            break;
          }
        }
      }
      if (!mounted) return;
      if (pdf != null) {
        await InAppDocumentScreen.open(context, pdf.url, title: pdf.label);
      } else {
        await _openCase(caseUrl);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  Future<void> _openCase(String url) async {
    setState(() => _opening = url);
    try {
      final html = await NgtCaseClient.instance.fetchCaseHtml(url);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NgtCaseDetailsScreen(
            hit: NgtCaseHit(
              diaryNo: '',
              caseNo: '',
              party: '',
              status: '',
              detailsUrl: url,
              raw: const {},
            ),
            html: html,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NGT judgement results')),
      backgroundColor: AppColors.secondary,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _rows.length) {
            return ElevatedButton(
              onPressed: _loadingMore ? null : _loadMore,
              child: Text(_loadingMore ? 'Loading…' : 'Load more'),
            );
          }
          final row = _rows[index];
          final pdf = ngtRowHref(row, preferPdf: true);
          final caseUrl = ngtRowHref(row, preferPdf: false);
          return Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.outline),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if ((row['Party'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        row['Party']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  if ((row['Diary Number'] ?? '').isNotEmpty || (row['Case Number'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        [
                          if ((row['Diary Number'] ?? '').isNotEmpty) 'Diary ${row['Diary Number']}',
                          if ((row['Case Number'] ?? '').isNotEmpty) row['Case Number']!,
                        ].join('  •  '),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ),
                  if ((row['Date of Listing'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        row['Date of Listing']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  if (pdf != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _openPdf(pdf),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('View order PDF'),
                      ),
                    )
                  else if (caseUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton.icon(
                        onPressed: _opening == 'pdf:$caseUrl' ? null : () => _openPdfForCase(row),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: Text(_opening == 'pdf:$caseUrl' ? 'Opening…' : 'View order PDF'),
                      ),
                    ),
                  if (caseUrl != null)
                    OutlinedButton(
                      onPressed: _opening == caseUrl ? null : () => _openCase(caseUrl),
                      child: Text(_opening == caseUrl ? 'Opening…' : 'View case details'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
