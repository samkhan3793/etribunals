import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:etribunals/presentation/screens/tribunals/nclat/case_tracker/case_details_screen.dart';
import 'package:etribunals/core/constants/app_colors.dart';

class ResultScreen extends StatefulWidget {
  final String responseData;

  const ResultScreen({super.key, required this.responseData});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<Map<String, String>> _cases = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseResponse();
  }

  void _parseResponse() {
    try {
      var document = html.parse(widget.responseData);
      var rows = document.querySelectorAll('tr');

      for (var row in rows) {
        var columns = row.querySelectorAll('td');
        if (columns.length >= 5) {
          _cases.add({
            'sr_no': columns[0].text.trim(),
            'filing_no': columns[1].text.trim(),
            'case_no': columns[2].text.trim(),
            'case_title': columns[3].text.trim(),
            'registration_date': columns[4].text.trim(),
          });
        }
      }

      if (_cases.isEmpty) {
        setState(() => _errorMessage = 'No cases found for the given details.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error parsing case details.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCaseDetails(BuildContext context, String filingNo) async {
    setState(() => _isLoading = true);

    try {
      var response = await http.post(
        Uri.parse('https://efiling.nclat.gov.in/nclat/ajax/ajax.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'action': 'case_status_case_details', 'filing_no': filingNo, 'schema_name': 'delhi'},
      );

      if (response.statusCode == 200 && !response.body.contains("No Record Found")) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CaseDetailsScreen(filingNo: filingNo, responseData: response.body),
          ),
        );
      } else {
        setState(() => _errorMessage = 'No case details found for filing number: $filingNo');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error fetching case details.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Status Results', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      backgroundColor: AppColors.secondary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _cases.length,
                  itemBuilder: (context, index) {
                    final caseData = _cases[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('Case Title:', caseData['case_title']!, AppColors.primary),
                            const Divider(color: AppColors.accent),
                            _infoRow('Filing No.', caseData['filing_no']!, AppColors.secondary),
                            _infoRow('Case No.', caseData['case_no']!, AppColors.secondary),
                            _infoRow('Registration Date:', caseData['registration_date']!, AppColors.secondary),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _fetchCaseDetails(context, caseData['filing_no']!),
                                icon: const Icon(Icons.visibility, color: Colors.white),
                                label: const Text('View Details', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "Not Available" : value,
              style: TextStyle(color: textColor),
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
