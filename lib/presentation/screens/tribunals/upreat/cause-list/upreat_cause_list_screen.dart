import 'dart:developer';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/cause-list/upreat_cause_list_details.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';

class ViewUpreatCauseListScreen extends StatefulWidget {
  const ViewUpreatCauseListScreen({super.key});

  @override
  State<ViewUpreatCauseListScreen> createState() => _ViewUpreatCauseListScreenState();
}

class _ViewUpreatCauseListScreenState extends State<ViewUpreatCauseListScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCsrfToken = '';
  String _sessionCookie = '';

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _formattedStartDate = '';
  String _formattedEndDate = '';

  @override
  void initState() {
    super.initState();
   _initializeDates();
    _fetchCsrfToken();
  }
void _initializeDates() {
    DateTime now = DateTime.now();

    // If June, set default values from May
    if (now.month == 6) {
      _startDate = DateTime(2025, 5, 1);
      _endDate = DateTime(2025, 5, 15);
    } else {
      _startDate = now;
      _endDate = now.add(const Duration(days: 7));
    }

    _formattedStartDate = DateFormat('dd/MM/yyyy').format(_startDate);
    _formattedEndDate = DateFormat('dd/MM/yyyy').format(_endDate);
  }

  /// Fetch CSRF Token & Session Cookies
  Future<void> _fetchCsrfToken() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri.parse('https://efilingreat.up.gov.in/upreat/cause_list.php'), headers: {
        'User-Agent': 'Mozilla/5.0',
      });

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final tokenElement = document.querySelector('input[name="generate_token_csrf"]');
        final csrfToken = tokenElement?.attributes['value'];

        final cookies = response.headers['set-cookie'] ?? '';
        _sessionCookie = cookies.split(',').map((c) => c.split(';')[0]).join('; ');

        if (csrfToken != null) {
          setState(() {
            _selectedCsrfToken = csrfToken;
            _isLoading = true;
          });

          _fetchCauseList();
        } else {
          throw Exception("Failed to retrieve CSRF token.");
        }
      } else {
        throw Exception("Failed to load CSRF token.");
      }
    } catch (e) {
      log("Error fetching CSRF token: $e");
      setState(() {
        _error = "Error fetching CSRF token.";
        _isLoading = false;
      });
    }
  }

  /// Fetch Cause List Using CSRF Token & Session Cookie
  Future<void> _fetchCauseList() async {
    try {
      final response = await http.post(
        Uri.parse('https://efilingreat.up.gov.in/upreat/ajax/ajax.php'),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://efilingreat.up.gov.in/upreat/cause_list.php',
          'Cookie': _sessionCookie,
          'X-Requested-With': 'XMLHttpRequest',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'case_status_datewise',
          'listing_date': _formattedStartDate,
          'date_to': _formattedEndDate,
          'token': _selectedCsrfToken,
        },
      );

      if (response.statusCode == 200 && !response.body.contains("Invalid Request") && !response.body.contains("Direct access not allowed")) {
        setState(() {
          _tableData = _parseHtmlResponse(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Invalid request or authentication failed.");
      }
    } catch (e) {
      log("Error fetching cause list: $e");
      setState(() {
        _error = "Error fetching cause list.";
        _isLoading = false;
      });
    }
  }

  /// Parses HTML Table Response
  List<Map<String, dynamic>> _parseHtmlResponse(String responseBody) {
  final document = html_parser.parse(responseBody);
  final table = document.querySelector('table');

  if (table == null) {
    throw Exception('No table found.');
  }

  final headers = table.querySelectorAll('tr th').map((e) => e.text.trim()).toList();
  final rows = table.querySelectorAll('tbody tr');

  final List<Map<String, dynamic>> parsedData = [];

  for (var row in rows) {
    final cells = row.querySelectorAll('td');
    if (cells.isEmpty) continue;

    final Map<String, dynamic> rowData = {};
    for (int i = 0; i < headers.length && i < cells.length; i++) {
      final header = headers[i];
      final cell = cells[i];

      final hiddenFields = cell.querySelectorAll("input[type='hidden']");
      for (var hiddenField in hiddenFields) {
        final name = hiddenField.attributes['name'];
        final value = hiddenField.attributes['value'] ?? "";

        if (name == "next_list_date") rowData["next_list_date"] = value;
        if (name == "lis_date") rowData["lis_date"] = value;
        if (name == "bench_no") rowData["bench_no"] = value;
      }

      rowData[header] = cell.text.trim();
    }

    parsedData.add(rowData);
  }

  return parsedData;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UPREAT Cause List", style: TextStyle(fontSize: 20)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: () => _showDateFilterBottomSheet(context)),
        ],
      ),
      backgroundColor: AppColors.secondary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _tableData.isEmpty
                  ? const Center(child: Text("No data found."))
                  : ListView.builder(
                      itemCount: _tableData.length,
                      itemBuilder: (context, index) {
                        final row = _tableData[index];
                        return _buildCardView(row);
                      },
                    ),
    );
  }

  /// Builds each row as a Card with key-value pairs
  Widget _buildCardView(Map<String, dynamic> rowData) {  return Card(
    color: AppColors.white,
    margin: const EdgeInsets.all(8),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: AppColors.primary, width: 1),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowData.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.key != "View") // Show key only if it's not "View"
                  Text(
                    "${entry.key}: ",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: entry.key == "View" && rowData.containsKey("bench_no")
                      ? ElevatedButton(
                          onPressed: () {
                            // Dynamically extract values
                            final nextListDate = rowData["next_list_date"]!;
                            final lisDate = rowData["lis_date"]!;
                            final benchNo = rowData["bench_no"]!;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CauseListDetailScreen(
                                  causeType: "1", // Fixed as required
                                  nextListDate: nextListDate,
                                  lisDate: lisDate,
                                  benchNo: benchNo,
                                ),
                              ),
                            );
                          },
                          child: const Text("View Details", style: TextStyle(fontSize: 16)
, overflow: TextOverflow.clip, textAlign: TextAlign.center),
                        )
                      : Text(entry.value.toString(),
                          style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.normal,overflow: TextOverflow.clip),
                        ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}



/// Shows Date Selection Modal
void _showDateFilterBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select Date Range", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2030),
                          );
                          if (selectedDate != null) {
                            setState(() => _startDate = selectedDate);
                          }
                        },
                        child: Text("Start Date: ${DateFormat('dd/MM/yyyy').format(_startDate)}"),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime(2030),
                          );
                          if (selectedDate != null) {
                            setState(() => _endDate = selectedDate);
                          }
                        },
                        child: Text("End Date: ${DateFormat('dd/MM/yyyy').format(_endDate)}"),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _formattedStartDate = DateFormat('dd/MM/yyyy').format(_startDate);
                      _formattedEndDate = DateFormat('dd/MM/yyyy').format(_endDate);
                      _isLoading = true;
                    });
                    Navigator.pop(context);
                    _fetchCsrfToken();
                  },
                  child: const Text("Apply Filter"),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


}
