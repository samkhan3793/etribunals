import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/ngt_case_client.dart';
import 'package:etribunals/core/widgets/case_summary_card.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/case-tracker/ngt_case_details_screen.dart';
import 'package:flutter/material.dart';

class NgtSearchResultsScreen extends StatefulWidget {
  final List<NgtCaseHit> hits;

  const NgtSearchResultsScreen(this.hits, {super.key});

  @override
  State<NgtSearchResultsScreen> createState() => _NgtSearchResultsScreenState();
}

class _NgtSearchResultsScreenState extends State<NgtSearchResultsScreen> {
  String? _loadingUrl;

  Future<void> _open(NgtCaseHit hit) async {
    setState(() => _loadingUrl = hit.detailsUrl);
    try {
      final html = await NgtCaseClient.instance.fetchCaseHtml(hit.detailsUrl);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NgtCaseDetailsScreen(hit: hit, html: html)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loadingUrl = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NGT search results')),
      backgroundColor: AppColors.secondary,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.hits.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final hit = widget.hits[index];
          return CaseSummaryCard(
            fields: {
              'Party': hit.party,
              'Diary / filing': hit.diaryNo,
              'Case no.': hit.caseNo,
              'Status': hit.status,
            },
            actionLabel: 'View details',
            loading: _loadingUrl == hit.detailsUrl,
            onAction: () => _open(hit),
          );
        },
      ),
    );
  }
}
