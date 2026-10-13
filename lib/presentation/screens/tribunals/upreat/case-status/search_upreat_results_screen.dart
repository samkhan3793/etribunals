import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/widgets/case_summary_card.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/case-status/upreat_case_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchUpreatResultsScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const SearchUpreatResultsScreen(this.data, {super.key});

  @override
  State<SearchUpreatResultsScreen> createState() => _SearchUpreatResultsScreenState();
}

class _SearchUpreatResultsScreenState extends State<SearchUpreatResultsScreen> {
  bool _isLoading = false;

  Map<String, dynamic> _firstPanel() {
    final list = widget.data['mainpanellist'];
    if (list is List && list.isNotEmpty && list.first is Map) {
      return Map<String, dynamic>.from(list.first as Map);
    }
    return {};
  }

  Future<void> _fetchCaseDetails(Map<String, dynamic> details) async {
    final filingNo = fieldStr(details, 'filing_no', '');
    final mainCaseFno = fieldStr(details, 'main_case_fno', 'NA');
    if (filingNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filing number missing for this case')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final flagIA = mainCaseFno == 'NA' ? 'false' : 'true';
    final url =
        'https://efilingreat.up.gov.in/caseHistoryalldetails.in?filing_no=$filingNo&flagIA=$flagIA';

    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;
      if (response.statusCode != 200) {
        throw Exception('Server ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response from UPREAT');
      }
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UpreatCaseDetailsScreen(decoded)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseHeader = widget.data['caseHheader']?.toString() ?? 'Case Details';
    final caseDetails = _firstPanel();

    return Scaffold(
      appBar: AppBar(title: const Text('Case status results')),
      backgroundColor: AppColors.secondary,
      body: caseDetails.isEmpty
          ? const Center(child: Text('No case details available'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  caseHeader,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                CaseSummaryCard(
                  fields: {
                    'Case no.': fieldStr(caseDetails, 'case_no'),
                    'Diary / filing': fieldStr(caseDetails, 'filing_no'),
                    'Party':
                        '${fieldStr(caseDetails, 'case_title1')} vs ${fieldStr(caseDetails, 'case_title2')}',
                    'Status': fieldStr(caseDetails, 'status'),
                    'Case Type': fieldStr(caseDetails, 'case_type_desc_cis'),
                    'Bench / Court':
                        '${fieldStr(caseDetails, 'bench_location_name')} / ${fieldStr(caseDetails, 'court_no')}',
                    'Main Case Filing No': fieldStr(caseDetails, 'main_case_fno'),
                    'Filing / Registration':
                        '${fieldStr(caseDetails, 'date_of_filing')} / ${fieldStr(caseDetails, 'regis_date')}',
                    'Next listing / Dispose':
                        '${fieldStr(caseDetails, 'next_list_date')} / ${fieldStr(caseDetails, 'disposal_date')}',
                    'All Hearings': fieldStr(caseDetails, 'allhearing'),
                    'Effective Hearings': fieldStr(caseDetails, 'effhearing'),
                  },
                  actionLabel: 'View details',
                  loading: _isLoading,
                  onAction: () => _fetchCaseDetails(caseDetails),
                ),
                SourceFooter(
                  tribunal: 'UPREAT',
                  officialUrl: TribunalSources.officialHome('UPREAT'),
                ),
              ],
            ),
    );
  }
}
