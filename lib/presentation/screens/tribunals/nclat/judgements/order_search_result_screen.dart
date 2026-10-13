import 'package:etribunals/presentation/screens/tribunals/nclat/judgements/orders_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/case_summary_card.dart';

class OrderSearchResultScreen extends StatelessWidget {
  final String responseData;

  const OrderSearchResultScreen({super.key, required this.responseData});

  @override
  Widget build(BuildContext context) {
    final cases = parseResponse(responseData);

    return Scaffold(
      appBar: AppBar(title: const Text('Order search results')),
      backgroundColor: AppColors.secondary,
      body: cases.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 10),
                  Text(
                    'No results found',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final caseData = cases[index];
                return _OrderResultCard(caseData: caseData);
              },
            ),
    );
  }

  List<Map<String, String>> parseResponse(String responseData) {
    var document = html.parse(responseData);
    var cases = <Map<String, String>>[];
    var rows = document.querySelectorAll('tr');

    for (var row in rows) {
      var columns = row.querySelectorAll('td');
      if (columns.length >= 6) {
        cases.add({
          'sr_no': columns[0].text.trim(),
          'filing_no': columns[1].text.trim(),
          'case_no': columns[2].text.trim(),
          'case_title': columns[3].text.trim(),
          'registration_date': columns[4].text.trim(),
        });
      }
    }

    return cases;
  }
}

class _OrderResultCard extends StatefulWidget {
  final Map<String, String> caseData;

  const _OrderResultCard({required this.caseData});

  @override
  State<_OrderResultCard> createState() => _OrderResultCardState();
}

class _OrderResultCardState extends State<_OrderResultCard> {
  bool _loading = false;

  Future<void> _fetchCaseDetails() async {
    final filingNo = widget.caseData['filing_no'] ?? '';
    setState(() => _loading = true);
    try {
      var response = await http.post(
        Uri.parse('https://efiling.nclat.gov.in/nclat/ajax/ajax.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'action': 'case_status_case_details', 'filing_no': filingNo, 'schema_name': 'delhi'},
      );

      if (!mounted) return;
      setState(() => _loading = false);
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrdersDetailsScreen(filingNo: filingNo, responseData: response.body),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch details')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open details')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseData = widget.caseData;
    return CaseSummaryCard(
      fields: {
        'Case Title': caseData['case_title'] ?? '',
        'Filing No.': caseData['filing_no'] ?? '',
        'Case No.': caseData['case_no'] ?? '',
        'Registration Date': caseData['registration_date'] ?? '',
      },
      actionLabel: 'View details',
      loading: _loading,
      onAction: _fetchCaseDetails,
    );
  }
}
