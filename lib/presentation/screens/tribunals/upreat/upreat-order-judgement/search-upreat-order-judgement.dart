import 'dart:convert';

import 'package:etribunals/presentation/screens/tribunals/upreat/upreat-order-judgement/nclt_order_judgement_search_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchUpreatOrderJudgementScreen extends StatefulWidget {
  const SearchUpreatOrderJudgementScreen({super.key});

  @override
  _SearchUpreatOrderJudgementScreenState createState() =>
      _SearchUpreatOrderJudgementScreenState();
}

class _SearchUpreatOrderJudgementScreenState
    extends State<SearchUpreatOrderJudgementScreen> {
  final TextEditingController _filingNumberController = TextEditingController();
  final TextEditingController _caseNumberController = TextEditingController();
  String? _selectedSearchType = 'Select Search Type';
  String? _selectedBench = '0';
  String? _selectedCaseType = '0';
  String? _selectedCaseYear = '0';
  bool _isLoading = false;

  final List<String> _searchTypes = [
    'Select Search Type',
    'filingnumber',
    'casenumber'
  ];

  final List<Map<String, String>> _benches = [
    {'value': '0', 'label': 'Select Zonal Bench'},
    {'value': '1', 'label': 'UPREAT LUCKNOW'}
  ];

  final List<Map<String, String>> _caseTypes = [
    {'value': '0', 'label': 'Select Case Type'},
    {'value': '1', 'label': 'Appeal'},
    {'value': '22', 'label': 'Miscellaneous/Defective Appeal'},
    
  ];

  final List<String> _caseYears = List.generate(
    15,
    (index) => (2025 - index).toString(),
  );

  Future<void> _submitForm() async {
    setState(() => _isLoading = true); // Show loader

    final Map<String, dynamic> payload = {
      "wayofselection": _selectedSearchType,
      "i_bench_id": "0",
      "filing_no": _filingNumberController.text,
      "i_bench_id_case_no": _selectedBench,
      "i_case_type_caseno": _selectedCaseType,
      "i_case_year_caseno": _selectedCaseYear,
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
      final response = await http.post(
        Uri.parse("https://www.efilingreat.up.gov.in/caseHistoryoptional.in"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() => _isLoading = false); // Hide loader

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => UpreatOrderJudgementSearcResultsScreen(responseData), // Pass data
          ),
        );
      } else {
        throw Exception("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching data: $e")));
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
      decoration: InputDecoration(labelText: label, isDense: true),
      dropdownColor: Theme.of(context).cardColor,
      isExpanded: true,
      menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Upreat Order/ Judgement"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    _buildDropdown<String>(
                      value: _selectedSearchType,
                      label: "Select Search Type",
                      onChanged: (value) => setState(() => _selectedSearchType = value),
                      items: _searchTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedSearchType == 'filingnumber')
                      TextField(
                        controller: _filingNumberController,
                        decoration: const InputDecoration(
                          labelText: "Enter Filing Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (_selectedSearchType == 'casenumber') ...[
                      _buildDropdown<String>(
                        value: _selectedBench,
                        label: "Select Bench",
                        onChanged: (value) => setState(() => _selectedBench = value),
                        items: _benches.map((bench) {
                          return DropdownMenuItem(
                            value: bench['value'],
                            child: Text(bench['label']!),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown<String>(
                        value: _selectedCaseType,
                        label: "Select Case Type",
                        onChanged: (value) => setState(() => _selectedCaseType = value),
                        items: _caseTypes.map((caseType) {
                          return DropdownMenuItem(
                            value: caseType['value'],
                            child: Text(caseType['label']!),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _caseNumberController,
                        decoration: const InputDecoration(labelText: "Enter Case Number"),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown<String>(
                        value: _caseYears.contains(_selectedCaseYear) ? _selectedCaseYear : _caseYears.first,
                        label: "Select Case Year",
                        onChanged: (value) => setState(() => _selectedCaseYear = value),
                        items: _caseYears.map((year) {
                          return DropdownMenuItem(value: year, child: Text(year));
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text("Search Case Status"),
                      ),
                    )
                  ],
                ),
      ),
    );
  }
}
