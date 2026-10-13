import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:etribunals/core/constants/app_colors.dart';

class NcltCauseListScreen extends StatefulWidget {
  const NcltCauseListScreen({super.key});

  @override
  _NcltCauseListScreenState createState() => _NcltCauseListScreenState();
}

class _NcltCauseListScreenState extends State<NcltCauseListScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, String>> benches = [];
  String? selectedBench;
  String? captchaQuestion;
  String? captchaSid;
  String? captchaToken;
  final List<Map<String, String>> _tableData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    final response = await http.get(Uri.parse('https://nclt.gov.in/all-couse-list'));
    if (response.statusCode == 200) {
      final document = parser.parse(response.body);

      final benchOptions = document.querySelectorAll('select[name="field_nclt_benches_list_target_id"] option');
      benches = benchOptions
          .map((e) => {'label': e.text.trim(), 'value': e.attributes['value'] ?? ''})
          .where((e) => e['value'] != null && e['value']!.isNotEmpty && e['value']! != 'All')
          .toList();
      selectedBench = benches.isNotEmpty ? benches[0]['value'] : null;

      captchaQuestion = document.querySelector('span.field-prefix')?.text.trim();
      captchaSid = document.querySelector('input[name="captcha_sid"]')?.attributes['value'];
      captchaToken = document.querySelector('input[name="captcha_token"]')?.attributes['value'];

      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('MM/dd/yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('MM/dd/yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (selectedBench == null || captchaSid == null || captchaToken == null || _startDate == null || _endDate == null) {
      return;
    }

    setState(() => _isLoading = true);

    final queryParams = {
      'field_nclt_benches_list_target_id': selectedBench!,
      'field_cause_date_value': _startDateController.text,
      'field_cause_date_value_1': _endDateController.text,
      'captcha_sid': captchaSid!,
      'captcha_token': captchaToken!,
      'captcha_response': _captchaController.text,
    };

    final uri = Uri.https('nclt.gov.in', '/all-couse-list', queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      final table = document.querySelector('table');

      if (table == null) {
        setState(() {
          _tableData.clear();
          _isLoading = false;
        });
        return;
      }

      final headers = table.querySelectorAll('thead tr th').map((e) => e.text.trim()).toList();
      final rows = table.querySelectorAll('tbody tr');
      _tableData.clear();

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty || cells.length < headers.length) continue;

        final Map<String, String> rowData = {};
        for (int i = 0; i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];
          final anchor = cell.querySelector('a');

          if (anchor != null && anchor.attributes.containsKey('href')) {
            rowData[header] = anchor.attributes['href'] ?? 'No Link';
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        _tableData.add(rowData);
      }

      setState(() => _isLoading = false);
      _loadForm();
    } else {
      setState(() {
        _tableData.clear();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('NCLT Cause List'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : benches.isEmpty || captchaQuestion == null
              ? const Center(child: Text("No data available"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedBench,
                        items: benches.map((b) {
                          return DropdownMenuItem(
                            value: b['value'],
                            child: Text(b['label']!),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => selectedBench = value),
                        decoration: const InputDecoration(
                          labelText: 'NCLT Bench Court',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: AppColors.accent,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.white),
                        iconSize: 24,
                        borderRadius: BorderRadius.circular(8),
                        isExpanded: true,
                      ),
                      const SizedBox(height: 20),
                      _buildDatePicker("Start Date", _startDateController, true),
                      const SizedBox(height: 12),
                      _buildDatePicker("End Date", _endDateController, false),
                      const SizedBox(height: 20),
                      Text('CAPTCHA: $captchaQuestion',
                          style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _captchaController,
                        decoration: const InputDecoration(
                          labelText: 'Enter CAPTCHA Result',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.security, color: AppColors.accent),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.white),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                        child: const Text('Search Cause List', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 20),
                      if (_tableData.isNotEmpty) ...[
                        const Text("Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ..._tableData.map((data) => _buildCard(data)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller, bool isStartDate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, color: AppColors.accent),
        ),
        onTap: () => _selectDate(context, isStartDate),
      ),
    );
  }

  Widget _buildCard(Map<String, String> data) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${entry.key}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  entry.key == "PDF File" && entry.value != "No Link"
                      ? InkWell(
                          onTap: () async {
                            final uri = Uri.parse(entry.value);
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          child: const Text("View PDF",
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                        )
                      : Text(entry.value, style: const TextStyle(color: AppColors.secondary)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
