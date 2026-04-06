import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

/// View Details Screen: Fetches and displays table data from the clicked URL
class ViewDetailsScreen extends StatefulWidget {
  final String requestUrl; // URL from the "View" button

  const ViewDetailsScreen({super.key, required this.requestUrl});

  @override
  State<ViewDetailsScreen> createState() => _ViewDetailsScreenState();
}

class _ViewDetailsScreenState extends State<ViewDetailsScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTableData();
  }

  Future<void> _loadTableData() async {
    setState(() => _isLoading = true);

    try {
      final data = await fetchTableData(widget.requestUrl);
      setState(() {
        _tableData = data;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data. Please try again later.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: customText("View Details", size: 20, color: AppColors.white),
        backgroundColor: AppColors.primary,
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) { // Left swipe detected
            _loadTableData();
          }
        },
        child: RefreshIndicator(
          onRefresh: _loadTableData,
          color: AppColors.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: customText(_error!, size: 16, color: Colors.red))
                  : _tableData.isEmpty
                      ? Center(child: customText("No data found."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _tableData.length,
                          itemBuilder: (context, index) {
                            final row = _tableData[index];
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: row.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${entry.key}: ",
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              entry.value.toString(),
                                              style: const TextStyle(color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

/// Fetch and parse table data from the View Details page
Future<List<Map<String, dynamic>>> fetchTableData(String requestUrl) async {
  try {
    final response = await http.get(Uri.parse(requestUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }

    final document = html_parser.parse(response.body);

    // Select the specific table
    final table = document.querySelector('table.table-bordered');

    if (table == null) {
      throw Exception('No matching table found.');
    }

    // Extract headers
    final headers = table.querySelectorAll('thead tr th').map((e) => e.text.trim()).toList();

    // Extract table rows
    final rows = table.querySelectorAll('tbody tr');

    final List<Map<String, dynamic>> tableData = [];

    for (var row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;

      final Map<String, dynamic> rowData = {};
      for (int i = 0; i < cells.length && i < headers.length; i++) {
        final header = headers[i];
        final cell = cells[i];

        rowData[header] = cell.text.trim().isEmpty ? "Not In Session" : cell.text.trim();
      }
      tableData.add(rowData);
    }

    return tableData;
  } catch (e) {
    print('Error fetching table data: $e');
    rethrow;
  }
}
