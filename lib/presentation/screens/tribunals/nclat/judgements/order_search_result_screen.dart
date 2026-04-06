import 'package:etribunals/presentation/screens/tribunals/nclat/judgements/orders_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:etribunals/core/constants/app_colors.dart';

class OrderSearchResultScreen extends StatelessWidget {
  final String responseData;

  OrderSearchResultScreen({required this.responseData});

  @override
  Widget build(BuildContext context) {
    final cases = parseResponse(responseData);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Case Details for Orders Results',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      backgroundColor: AppColors.secondary,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: cases.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 80, color: AppColors.secondary),
                    SizedBox(height: 10),
                    Text(
                      'No results found',
                      style: TextStyle(fontSize: 18, color: AppColors.secondary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final caseData = cases[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 8,
                    margin: EdgeInsets.symmetric(vertical: 12),
                    color: AppColors.white, // Updated card color to white
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Case Title:', caseData['case_title']!, AppColors.primary),
                          Divider(color: AppColors.accent),
                          _infoRow('Filing No.', caseData['filing_no']!, AppColors.secondary),
                          _infoRow('Case No.', caseData['case_no']!, AppColors.secondary),
                          _infoRow('Registration Date:', caseData['registration_date']!, AppColors.secondary),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _fetchCaseDetails(context, caseData['filing_no']!),
                              icon: Icon(Icons.visibility, color: AppColors.white),
                              label: Text('View Details', style: TextStyle(color: AppColors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color textColor) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textColor),
            softWrap: true,
            maxLines: 2, // Limits excessive length
            overflow: TextOverflow.ellipsis, // Adds "..." for long content
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}


  void _fetchCaseDetails(BuildContext context, String filingNo) async {
    try {
      var response = await http.post(
        Uri.parse('https://efiling.nclat.gov.in/nclat/ajax/ajax.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'action': 'case_status_case_details', 'filing_no': filingNo, 'schema_name': 'delhi'},
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrdersDetailsScreen(filingNo: filingNo, responseData: response.body),
          ),
        );
      } else {
        _showSnackBar(context, 'Failed to fetch details');
      }
    } catch (e) {
      _showSnackBar(context, 'An error occurred');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
