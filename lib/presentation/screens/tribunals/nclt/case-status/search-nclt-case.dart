import 'dart:async';
import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/case-status/search_nclt_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchNCLTCaseStatusScreen extends StatefulWidget {
  const SearchNCLTCaseStatusScreen({super.key});

  @override
  _SearchNCLTCaseStatusScreenState createState() =>
      _SearchNCLTCaseStatusScreenState();
}

class _SearchNCLTCaseStatusScreenState
    extends State<SearchNCLTCaseStatusScreen> {
  final TextEditingController _filingNumberController = TextEditingController();
  final TextEditingController _caseNumberController = TextEditingController();
  String? _selectedSearchType = 'filingnumber';
  String? _selectedBench = '0';
  String? _selectedCaseType = '0';
  String? _selectedCaseYear;
  bool _isLoading = false;

  final List<Map<String, String>> _benches = [
    {'value': '0', 'label': 'Select Bench'},
    {'value': '10', 'label': 'NCLT New Delhi/Principal Bench'},
    {'value': '9', 'label': 'NCLT Mumbai Bench'},
    {'value': '13', 'label': 'NCLT Cuttack Bench'},
    {'value': '1', 'label': 'NCLT Ahmedabad Bench'},
    {'value': '12', 'label': 'NCLT Amaravati Bench'},
    {'value': '4', 'label': 'NCLT Chandigarh Bench'},
    {'value': '8', 'label': 'NCLT Kolkata Bench'},
    {'value': '11', 'label': 'NCLT Jaipur Bench'},
    {'value': '2', 'label': 'NCLT Allahabad Bench'},
    {'value': '3', 'label': 'NCLT Bengaluru Bench'},
    {'value': '5', 'label': 'NCLT Chennai Bench'},
    {'value': '6', 'label': 'NCLT Guwahati Bench'},
    {'value': '7', 'label': 'NCLT Hyderabad Bench'},
    {'value': '14', 'label': 'NCLT Kochi Bench'},
    {'value': '15', 'label': 'NCLT Indore Bench'},
  ];

  final List<Map<String, String>> _caseTypes = [
    {'value': '0', 'label': 'Select Case Type'},
    {'value': '1', 'label': 'Transfer Petition (Company Act)'},
    {'value': '2', 'label': 'Company Petition (Company Act)'},
    {'value': '3', 'label': 'Rehabilitation Petition (Company Act)'},
    {'value': '4', 'label': 'Interlocutory Application (Company Act)'},
    {'value': '5', 'label': 'Review Application (Company Act)'},
    {'value': '6', 'label': 'Restoration Application (Company Act)'},
    {'value': '7', 'label': 'Intervention Petition (Company Act)'},
    {'value': '8', 'label': 'Cross Application (Company Act)'},
    {'value': '9', 'label': 'Contempt Petition (Company Act)'},
    {'value': '10', 'label': 'Miscellaneous Application (Company Act)'},
    {'value': '11', 'label': 'Company Appeal (Company Act)'},
    {'value': '12', 'label': 'Cross Appeal (Company Act)'},
    {'value': '13', 'label': 'Company Application (Company Act)'},
    {'value': '14', 'label': 'CA(A) Merger & Amalgamation (Company Act)'},
    {'value': '15', 'label': 'CP(AA) Merger & Amalgamation (Company Act)'},
    {'value': '16', 'label': 'Company Petition IB (IBC)'},
    {'value': '18', 'label': 'Company Application (IBC)'},
    {'value': '19', 'label': 'Rehabilitation Petition (IBC)'},
    {'value': '20', 'label': 'Interlocutory Application (IBC)'},
    {'value': '21', 'label': 'Review Application (IBC)'},
    {'value': '22', 'label': 'Restoration Application (IBC)'},
    {'value': '23', 'label': 'Intervention Petition (IBC)'},
    {'value': '24', 'label': 'Cross Application (IBC)'},
    {'value': '25', 'label': 'Contempt Petition (IBC)'},
    {'value': '26', 'label': 'Miscellaneous Application (IBC)'},
    {'value': '27', 'label': 'Company Appeal (IBC)'},
    {'value': '28', 'label': 'Cross Appeal (IBC)'},
    {'value': '29', 'label': 'Transfer Petition (IBC)'},
    {'value': '30', 'label': 'Execution Petition (Company Act)'},
    {'value': '31', 'label': 'Interlocutory Application (IBC)'},
    {'value': '32', 'label': 'Transfer Application (Company Act)'},
    {'value': '33', 'label': 'Insolvency & Bankruptcy (Pre-Packaged)'},
    {'value': '34', 'label': 'Transfer Application (IBC)'},
    {'value': '35', 'label': 'Voluntary Liquidation (IBC)'},
    {'value': '36', 'label': 'Restored Company Petition (IBC)'},
    {'value': '37', 'label': 'Restored Company Petition (Companies Act)'},
    {'value': '38', 'label': 'Interlocutory Application (IBC) - Plan'},
    {'value': '39', 'label': 'Interlocutory Application (IBC) - Liquidation'},
    {'value': '40', 'label': 'Interlocutory Application (IBC) - Dispute'},
    {'value': '41', 'label': 'IA (Liq.) Progress Report (IBC)'},
    {'value': '42', 'label': 'Rule 63 Appeal'},
  ];

  final List<String> _caseYears = List.generate(
    15,
    (index) => (DateTime.now().year - index).toString(),
  );

  @override
  void initState() {
    super.initState();
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

    FocusScope.of(context).unfocus(); // Close keyboard before loading

    // Validation logic
    if (selectedSearchType == 'filingnumber') {
      if (_filingNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a filing number")),
        );
        return;
      }
    } else if (selectedSearchType == 'casenumber') {
      if ((_selectedBench ?? '0') == '0') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a bench")),
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
    };

    try {
      final response = await http.post(
        Uri.parse("https://efiling.nclt.gov.in/caseHistoryoptional.drt"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData;
        try {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException("Unexpected response format");
          }
          responseData = decoded;
        } on FormatException {
          throw const FormatException("Invalid data received from server");
        }

        if (!mounted) return;
        setState(() => _isLoading = false); // Hide loader

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchNCLTResultsScreen(responseData),
          ),
        );
      } else {
        throw Exception("Failed to fetch data: ${response.statusCode}");
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
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label, isDense: true),
      dropdownColor: Theme.of(context).cardColor,
      isExpanded: true,
      menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('NCLT case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Search official record',
            subtitle: 'eFiling NCLT  Â·  filing no. or bench + case no.',
            icon: Icons.search,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedSearchType,
            decoration: const InputDecoration(labelText: 'Search by'),
            items: const [
              DropdownMenuItem(value: 'filingnumber', child: Text('Filing / diary no.')),
              DropdownMenuItem(value: 'casenumber', child: Text('Case number')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSearchType = value;
                _filingNumberController.clear();
                _caseNumberController.clear();
                _selectedBench = '0';
                _selectedCaseType = '0';
                _selectedCaseYear = _caseYears.first;
              });
            },
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
              items: _benches
                  .map((bench) => DropdownMenuItem(value: bench['value'], child: Text(bench['label']!)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _selectedCaseType,
              label: 'Case type',
              onChanged: (value) => setState(() => _selectedCaseType = value),
              items: _caseTypes
                  .map((caseType) => DropdownMenuItem(value: caseType['value'], child: Text(caseType['label']!)))
                  .toList(),
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
              items: _caseYears.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
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
          SourceFooter(tribunal: 'NCLT', officialUrl: TribunalSources.officialHome('NCLT')),
        ],
      ),
    );
  }
}
