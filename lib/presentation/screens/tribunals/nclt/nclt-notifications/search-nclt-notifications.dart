import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:etribunals/core/constants/app_colors.dart';

class SearchNcltNotificationsScreen extends StatefulWidget {
  @override
  _SearchNcltNotificationsScreenState createState() => _SearchNcltNotificationsScreenState();
}

class _SearchNcltNotificationsScreenState extends State<SearchNcltNotificationsScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  final TextEditingController _notificationTitleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? captchaQuestion;
  String? captchaSid;
  String? captchaToken;
  

  List<Map<String, String>> _tableData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    final response = await http.get(Uri.parse('https://nclt.gov.in/notifcations'));
    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
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
    if ( captchaSid == null || captchaToken == null || _startDate == null || _endDate == null) {
      return;
    }

    setState(() => _isLoading = true);

    final queryParams = {
      'title': _notificationTitleController.text,
      'field_issue_date_value': _startDateController.text,
      'field_issue_date_value_1': _endDateController.text,
      'captcha_sid': captchaSid!,
      'captcha_token': captchaToken!,
      'captcha_response': _captchaController.text,
    };

    final uri = Uri.https('nclt.gov.in', '/notifcationss', queryParams);
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

      setState(() {
        _isLoading = false;
        _captchaController.clear();
        _notificationTitleController.clear();
        _startDateController.clear();
        _endDateController.clear();
      });
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
        title: const Text('Search NCLT Notifications',
            style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          :captchaQuestion == null
              ? const Center(child: Text("No data available"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _notificationTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Notifications Title (Optional)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.text_fields, color: AppColors.accent),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.white),
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
                        child: const Text('Search Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      if (_tableData.isNotEmpty) ...[
                        const Text("Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ..._tableData.map((data) => _buildCard(data)).toList(),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap title text inside Flexible
                Flexible(
                  flex: 2, // Adjust flex ratio as needed
                  child: Text(
                    "${entry.key}: ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis, // Prevents overflow
                    maxLines: 2, // Limits to 2 lines
                  ),
                ),
                const SizedBox(width: 8), // Space between title and value
                
                Expanded(
  flex: 3, // Adjust flex ratio as needed
  child: entry.key == "Documents" && entry.value != "No Link"
      ? InkWell(
          onTap: () async {
            final uri = Uri.parse("https://nclt.gov.in${entry.value}");
            print("Opening URL: $uri");
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: const Text(
            "View PDF",
            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          ),
        )
      : Text(
          entry.value,
          style: const TextStyle(color: AppColors.secondary),
          overflow: TextOverflow.ellipsis, // Handles long text
          maxLines: 2, // Limits to 2 lines to prevent UI breaking
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

}
