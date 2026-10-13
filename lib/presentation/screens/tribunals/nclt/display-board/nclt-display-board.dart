import 'package:etribunals/presentation/screens/tribunals/nclat/displayboard/view-details-screen.dart';
import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/case_summary_card.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/utils/web_scraper.dart';

class NCLTDisplayBoardScreen extends StatefulWidget {
  const NCLTDisplayBoardScreen({super.key});

  @override
  State<NCLTDisplayBoardScreen> createState() => _NCLTDisplayBoardScreenState();
}

class _NCLTDisplayBoardScreenState extends State<NCLTDisplayBoardScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedLocation = '1';

  final List<Map<String, String>> _locations = [
    {'value': '1', 'label': 'New Delhi'},
    {'value': '3', 'label': 'Allahabad'},
    {'value': '4', 'label': 'Ahmedabad'},
    {'value': '5', 'label': 'Chennai'},
    {'value': '6', 'label': 'Mumbai'},
    {'value': '7', 'label': 'Chandigarh'},
    {'value': '8', 'label': 'Bengaluru'},
    {'value': '9', 'label': 'Jaipur'},
    {'value': '10', 'label': 'Hyderabad'},
    {'value': '14', 'label': 'Guwahati'},
    {'value': '15', 'label': 'Kochi'},
    {'value': '16', 'label': 'Kolkata'},
    {'value': '17', 'label': 'Indore'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDisplayBoard();
  }

  String get _benchLabel =>
      _locations.firstWhere((e) => e['value'] == _selectedLocation, orElse: () => {'label': 'Bench'})['label']!;

  Future<void> _loadDisplayBoard() async {
    setState(() => _isLoading = true);
    try {
      final data = await fetchNCLTDisplayBoardListTable(_selectedLocation!);
      setState(() {
        _tableData = data;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'No sitting listed for this bench.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _textOf(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final v = row[key];
      if (v == null) continue;
      if (v is Map) {
        final t = (v['label'] ?? v['text'] ?? '').toString().trim();
        if (t.isNotEmpty) return t;
      } else {
        final t = v.toString().trim();
        if (t.isNotEmpty) return t;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('NCLT display board')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedLocation,
              decoration: const InputDecoration(labelText: 'Bench'),
              items: _locations
                  .map((location) => DropdownMenuItem(value: location['value'], child: Text(location['label']!)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedLocation = value);
                _loadDisplayBoard();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDisplayBoard,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tableData.isEmpty ? 2 : _tableData.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return CourtBand(
                            title: _benchLabel,
                            subtitle: 'Official nclt.gov.in  ·  pull to refresh',
                            icon: Icons.tv_outlined,
                          );
                        }
                        if (_error != null) {
                          return Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.stampRed));
                        }
                        if (_tableData.isEmpty) {
                          return const Text('No sitting listed', textAlign: TextAlign.center);
                        }
                        final row = _tableData[index - 1];
                        Map<String, dynamic>? action;
                        for (final v in row.values) {
                          if (v is Map && v.containsKey('url')) {
                            action = Map<String, dynamic>.from(v);
                            break;
                          }
                        }
                        return CaseSummaryCard(
                          fields: {
                            'Case no.': _textOf(row, ['Case No.', 'Case No', 'Case Number']),
                            'Party': _textOf(row, ['Cause Title', 'Title', 'Party']),
                            'Status': _textOf(row, ['Item No.', 'Item No', 'Court']),
                            'Court': _textOf(row, ['Court Name', 'Court', 'Bench']),
                          },
                          actionLabel: action == null ? 'No list' : (action['label']?.toString() ?? 'View'),
                          loading: false,
                          onAction: () {
                            final url = action?['url']?.toString();
                            if (url == null || url.isEmpty) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ViewDetailsScreen(requestUrl: url)),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
