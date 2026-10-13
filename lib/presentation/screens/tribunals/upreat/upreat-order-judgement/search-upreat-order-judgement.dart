// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/upreat-order-judgement/nclt_order_judgement_search_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchUpreatOrderJudgementScreen extends StatefulWidget {
  const SearchUpreatOrderJudgementScreen({super.key});

  @override
  State<SearchUpreatOrderJudgementScreen> createState() =>
      _SearchUpreatOrderJudgementScreenState();
}

class _SearchUpreatOrderJudgementScreenState
    extends State<SearchUpreatOrderJudgementScreen> {
  final TextEditingController _filingNumberController = TextEditingController();
  final TextEditingController _caseNumberController = TextEditingController();
  String? _selectedSearchType = 'filingnumber';
  String? _selectedBench = '1';
  String? _selectedCaseType = '1';
  String? _selectedCaseYear;
  bool _isLoading = false;

  final List<Map<String, String>> _benches = [
    {'value': '1', 'label': 'UPREAT Lucknow'}
  ];

  final List<Map<String, String>> _caseTypes = [
    {'value': '0', 'label': 'Select Case Type'},
    {'value': '1', 'label': 'Appeal'},
    {'value': '22', 'label': 'Miscellaneous/Defective Appeal'},
    
  ];

  late final List<String> _caseYears;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _caseYears = List.generate(15, (index) => (currentYear - index).toString());
    _selectedCaseYear = _caseYears.first;
  }

  @override
  void dispose() {
    _filingNumberController.dispose();
    _caseNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final selectedSearchType = _selectedSearchType;
    if (selectedSearchType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a search type")),
      );
      return;
    }

    FocusScope.of(context).unfocus(); // Dismiss keyboard

    if (selectedSearchType == 'filingnumber') {
      if (_filingNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a filing number")),
        );
        return;
      }
    } else if (selectedSearchType == 'casenumber') {
      if ((_selectedBench ?? '1') == '0') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a bench")),
        );
        return;
      }
      if ((_selectedCaseType ?? '0') == '0') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a case type")),
        );
        return;
      }
      if (_caseNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a case number")),
        );
        return;
      }
    }

    setState(() => _isLoading = true); // Show loader

    final Map<String, dynamic> payload = {
      "wayofselection": selectedSearchType,
      "i_bench_id": "0",
      "filing_no": _filingNumberController.text,
      "i_bench_id_case_no": _selectedBench ?? "0",
      "i_case_type_caseno": _selectedCaseType ?? "0",
      "i_case_year_caseno": _selectedCaseYear ?? "",
      "case_no": _caseNumberController.text,
      "i_party_search": "E",
      "i_bench_id_party": "0",
      "party_type_party": "0",
      "party_name_party": "",
      "i_case_year_party": "0",
      "status_party": "0",
      "i_adv_search": "E",
      "i_bench_id_lawyer": "0",
      "party_lawer_name": "",
      "i_case_year_lawyer": "0",
      "bar_council_advocate": "",
    };

    try {
      final response = await http
          .post(
        Uri.parse("https://efilingreat.up.gov.in/caseHistoryoptional.in"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData;
        try {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException("Unexpected response format");
          }
          responseData = decoded;
        } on FormatException {
          final snippet =
              response.body.length > 200 ? response.body.substring(0, 200) : response.body;
          throw FormatException("Unexpected response from server: $snippet");
        }
        if (!mounted) return;
        setState(() => _isLoading = false); // Hide loader

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpreatOrderJudgementSearchResultsScreen(responseData), // Pass data
          ),
        );
      } else {
        final snippet =
            response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        throw Exception("Failed to fetch data: ${response.statusCode} ($snippet)");
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request timed out. Please try again.")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data: $e")),
      );
    }
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String label,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('UPREAT judgements / orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Search official orders',
            subtitle: 'eFiling REAT Lucknow  Â·  then open PDFs in-app',
            icon: Icons.gavel,
          ),
          const SizedBox(height: 14),
          _buildDropdown<String>(
            value: _selectedSearchType,
            label: 'Search by',
            onChanged: (value) {
              setState(() {
                _selectedSearchType = value;
                _filingNumberController.clear();
                _caseNumberController.clear();
              });
            },
            items: const [
              DropdownMenuItem(value: 'filingnumber', child: Text('Filing / diary no.')),
              DropdownMenuItem(value: 'casenumber', child: Text('Case number')),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedSearchType == 'filingnumber')
            TextField(
              controller: _filingNumberController,
              decoration: const InputDecoration(labelText: 'Filing number'),
            ),
          if (_selectedSearchType == 'casenumber') ...[
            _buildDropdown<String>(
              value: _selectedBench,
              label: 'Bench',
              onChanged: (value) => setState(() => _selectedBench = value),
              items: _benches.map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!))).toList(),
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _selectedCaseType,
              label: 'Case type',
              onChanged: (value) => setState(() => _selectedCaseType = value),
              items: _caseTypes.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!))).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caseNumberController,
              decoration: const InputDecoration(labelText: 'Case number (serial only)'),
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _selectedCaseYear,
              label: 'Year',
              onChanged: (value) => setState(() => _selectedCaseYear = value),
              items: _caseYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search'),
            ),
          ),
          SourceFooter(tribunal: 'UPREAT', officialUrl: TribunalSources.officialHome('UPREAT')),
        ],
      ),
    );
  }
}
