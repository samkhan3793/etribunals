import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/case-status/search_upreat_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchUpreatCaseStatusScreen extends StatefulWidget {
  const SearchUpreatCaseStatusScreen({super.key});

  @override
  State<SearchUpreatCaseStatusScreen> createState() =>
      _SearchUpreatCaseStatusScreenState();
}

class _SearchUpreatCaseStatusScreenState extends State<SearchUpreatCaseStatusScreen> {
  final TextEditingController _filingNumberController = TextEditingController();
  final TextEditingController _caseNumberController = TextEditingController();
  String? _selectedSearchType = 'filingnumber';
  String? _selectedBench = '1';
  String? _selectedCaseType = '1';
  String? _selectedCaseYear;
  bool _isLoading = false;

  final List<Map<String, String>> _benches = [
    {'value': '1', 'label': 'UPREAT Lucknow'},
  ];

  final List<Map<String, String>> _caseTypes = [
    {'value': '1', 'label': 'Appeal'},
    {'value': '22', 'label': 'Miscellaneous / defective appeal'},
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
    if (_selectedSearchType == 'filingnumber' && _filingNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter filing number')),
      );
      return;
    }
    if (_selectedSearchType == 'casenumber' && _caseNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter case number (serial only)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> payload = {
      'wayofselection': _selectedSearchType,
      'i_bench_id': '0',
      'filing_no': _filingNumberController.text,
      'i_bench_id_case_no': _selectedBench,
      'i_case_type_caseno': _selectedCaseType,
      'i_case_year_caseno': _selectedCaseYear,
      'case_no': _caseNumberController.text,
      'i_party_search': 'E',
      'i_bench_id_party': '0',
      'party_type_party': '0',
      'party_name_party': '',
      'i_case_year_party': '0',
      'status_party': '0',
      'i_adv_search': 'E',
      'i_bench_id_lawyer': '0',
      'party_lawer_name': '',
      'i_case_year_lawyer': '0',
      'bar_council_advocate': '',
    };

    try {
      final response = await http.post(
        Uri.parse('https://www.efilingreat.up.gov.in/caseHistoryoptional.in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchUpreatResultsScreen(responseData)),
        );
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('UPREAT case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Search official record',
            subtitle: 'eFiling REAT  ·  Lucknow  ·  filing no. or case no.',
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
            onChanged: (value) => setState(() => _selectedSearchType = value),
          ),
          const SizedBox(height: 12),
          if (_selectedSearchType == 'filingnumber')
            TextField(
              controller: _filingNumberController,
              decoration: const InputDecoration(labelText: 'Filing number'),
            ),
          if (_selectedSearchType == 'casenumber') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedBench,
              decoration: const InputDecoration(labelText: 'Bench'),
              items: _benches
                  .map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedBench = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedCaseType,
              decoration: const InputDecoration(labelText: 'Case type'),
              items: _caseTypes
                  .map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCaseType = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caseNumberController,
              decoration: const InputDecoration(labelText: 'Case number (serial only)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedCaseYear,
              decoration: const InputDecoration(labelText: 'Year'),
              items: _caseYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (value) => setState(() => _selectedCaseYear = value),
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
