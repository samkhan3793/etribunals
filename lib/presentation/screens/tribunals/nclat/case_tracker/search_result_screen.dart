import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:etribunals/presentation/screens/tribunals/nclat/case_tracker/case_details_screen.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/case_summary_card.dart';

class ResultScreen extends StatefulWidget {
  final String responseData;
  final String schemaName;
  final String tribunal;

  const ResultScreen({
    super.key,
    required this.responseData,
    this.schemaName = 'delhi',
    this.tribunal = 'NCLAT',
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const String _ajaxUrl = 'https://efiling.nclat.gov.in/nclat/ajax/ajax.php';

  static const String _kSrNo = 'sr_no';
  static const String _kFilingNo = 'filing_no';
  static const String _kCaseNo = 'case_no';
  static const String _kCaseTitle = 'case_title';
  static const String _kRegistrationDate = 'registration_date';

  final List<Map<String, String>> _cases = [];
  bool _parseLoading = true;
  String? _loadingFiling;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseResponse();
  }

  void _parseResponse() {
    final parsedCases = <Map<String, String>>[];
    String? errorMessage;

    try {
      var document = html.parse(widget.responseData);
      var rows = document.querySelectorAll('tr');

      for (var row in rows) {
        var columns = row.querySelectorAll('td');
        if (columns.length >= 5) {
          parsedCases.add({
            _kSrNo: columns[0].text.trim(),
            _kFilingNo: columns[1].text.trim(),
            _kCaseNo: columns[2].text.trim(),
            _kCaseTitle: columns[3].text.trim(),
            _kRegistrationDate: columns[4].text.trim(),
          });
        }
      }

      if (parsedCases.isEmpty) errorMessage = 'No cases found for the given details.';
    } catch (e) {
      errorMessage = 'Error parsing case details.';
    } finally {
      if (!mounted) return;
      setState(() {
        _cases
          ..clear()
          ..addAll(parsedCases);
        _errorMessage = errorMessage;
        _parseLoading = false;
      });
    }
  }

  Future<void> _fetchCaseDetails(Map<String, String> caseRow) async {
    final filing = caseRow[_kFilingNo] ?? '';
    if (!mounted) return;
    setState(() => _loadingFiling = filing);

    try {
      var response = await http.post(
        Uri.parse(_ajaxUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'case_status_case_details',
          'filing_no': filing,
          'schema_name': widget.schemaName,
        },
      );

      if (response.statusCode == 200 && !response.body.contains('No Record Found')) {
        if (!mounted) return;
        setState(() => _loadingFiling = null);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CaseDetailsScreen(
              filingNo: filing,
              responseData: response.body,
              tribunal: widget.tribunal,
              caseTitle: caseRow[_kCaseTitle] ?? '',
              caseNo: caseRow[_kCaseNo] ?? '',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _loadingFiling = null;
          _errorMessage = 'No case details found for filing number: $filing';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No case details found for filing number: $filing')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFiling = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open details. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case status results')),
      backgroundColor: AppColors.secondary,
      body: _parseLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _cases.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final caseData = _cases[index];
                    final filing = caseData[_kFilingNo] ?? '';
                    return CaseSummaryCard(
                      fields: {
                        'Case no.': caseData[_kCaseNo] ?? '',
                        'Diary / filing': filing,
                        'Party': caseData[_kCaseTitle] ?? '',
                        'Registered': caseData[_kRegistrationDate] ?? '',
                      },
                      actionLabel: 'View details',
                      loading: _loadingFiling == filing,
                      onAction: () => _fetchCaseDetails(caseData),
                    );
                  },
                ),
    );
  }
}
