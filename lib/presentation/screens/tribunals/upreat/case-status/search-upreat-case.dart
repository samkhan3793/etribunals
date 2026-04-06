import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/presentation/screens/tribunals/Upreat/case-status/search_Upreat_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchUpreatCaseStatusScreen extends StatefulWidget {
  @override
  _SearchUpreatCaseStatusScreenState createState() =>
      _SearchUpreatCaseStatusScreenState();
}

class _SearchUpreatCaseStatusScreenState
    extends State<SearchUpreatCaseStatusScreen> {
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
                (context) => SearchUpreatResultsScreen(responseData), // Pass data
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Upreat Case Status"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.secondary,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSearchType,
                      items: _searchTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: Text(
                              type.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedSearchType = value),
                      decoration: const InputDecoration(
                        labelText: "Select Search Type",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        isDense: true,
                      ),
                      dropdownColor: AppColors.secondary,
                      isExpanded: true,
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
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
                      DropdownButtonFormField<String>(
                        value: _selectedBench,
                        items: _benches.map((bench) {
                          return DropdownMenuItem(
                            value: bench['value'],
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: Text(
                                bench['label']!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedBench = value),
                        decoration: const InputDecoration(
                          labelText: "Select Bench",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          isDense: true,
                        ),
                        dropdownColor: AppColors.secondary,
                        isExpanded: true,
                        menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedCaseType,
                        items: _caseTypes.map((caseType) {
                          return DropdownMenuItem(
                            value: caseType['value'],
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: Text(
                                caseType['label']!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCaseType = value),
                        decoration: const InputDecoration(
                          labelText: "Select Case Type",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          isDense: true,
                        ),
                        dropdownColor: AppColors.secondary,
                        isExpanded: true,
                        menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _caseNumberController,
                        decoration: const InputDecoration(
                          labelText: "Enter Case Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedCaseYear != null &&
                                _caseYears.contains(_selectedCaseYear)
                            ? _selectedCaseYear
                            : (_caseYears.isNotEmpty ? _caseYears.first : null),
                        items: _caseYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: Text(
                                year,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCaseYear = value),
                        decoration: const InputDecoration(
                          labelText: "Select Case Year",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          isDense: true,
                        ),
                        dropdownColor: AppColors.secondary,
                        isExpanded: true,
                        menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: const Text(
                        "Search Case Status",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
