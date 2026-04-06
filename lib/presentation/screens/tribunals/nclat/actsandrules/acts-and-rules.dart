import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:etribunals/core/utils/web_scraper.dart';
import 'package:etribunals/core/utils/model_bottom_sheet.dart';

class ActsAndRulesScreen extends StatefulWidget {
  const ActsAndRulesScreen({super.key});

  @override
  State<ActsAndRulesScreen> createState() => _ActsAndRulesScreenState();
}

class _ActsAndRulesScreenState extends State<ActsAndRulesScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;
  String? _error;

// Default end date

  String _formattedStartDate = '';
  String _formattedEndDate = '';

  List<Map<String, String>> _courtNames = [];
  String _selectedCourtId = 'All';

  @override
  void initState() {
    super.initState();
    _formattedStartDate = '';
    _formattedEndDate = '';
    _isLoading = true;
    _loadActsAndRules();
    _loadCourtNames();
  }

  Future<void> _loadCourtNames() async {
    try {
      List<Map<String, String>> fetchedCourtNames = await fetchCourtNames();
      setState(() {
        _courtNames = fetchedCourtNames;
        _selectedCourtId = _courtNames.isNotEmpty ? _courtNames[0]['id']! : 'All';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Dropdown names.';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, String>>> fetchCourtNames() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      {'id': 'All', 'name': 'Select All'},
      {'id': '52', 'name': 'Acts'},
      {'id': '53', 'name': 'Rules'},
    ];
  }

  Future<void> _loadActsAndRules() async {
    try {
      final data = await fetchActsAndRulesListTable(_selectedCourtId, _formattedStartDate, _formattedEndDate);
      setState(() {
        _tableData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
         _error = 'No Data Found. Please modify your filter and try again.';
        _isLoading = false;
      });
    }
  }

  void _showFilterBottomSheet(BuildContext context, bool showDropdown, bool showStartDate, bool showEndDate) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BottomSheetContent(
          defaultStartDate: DateTime.now(),
          defaultEndDate: DateTime.now().add(const Duration(days: 7)),
          courtList: _courtNames, // Pass dynamic court list
          showDropdown: showDropdown,
          showStartDate: showStartDate,
          showEndDate: showEndDate,
          onFilterApplied: (selectedCourt, startDate, endDate) {
            setState(() {
              _selectedCourtId = selectedCourt;
              _formattedStartDate = startDate;
              _formattedEndDate = endDate!;
              _isLoading = true;
            });

            _loadActsAndRules();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: customText("Acts and Rules List", size: 20, color: AppColors.white),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterBottomSheet(context,true,false,false),
          ),
        ],
      ),
      body: _isLoading
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
                                        child: entry.key == 'Download/Details' &&
                                                entry.value is Map<String, dynamic>
                                            ? _buildDownloadWidget(entry.value)
                                            : Text(
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
    );
  }

  Widget _buildDownloadWidget(Map<String, dynamic> valueMap) {
    final label = valueMap['label'] ?? 'Download';
    final relativeUrl = valueMap['url'];

    if (relativeUrl != null && relativeUrl.toString().endsWith('.pdf')) {
      final fullUrl = 'https://nclat.nic.in$relativeUrl';
      return InkWell(
        onTap: () async {
          final uri = Uri.parse(fullUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      );
    } else {
      return const Text("No PDF available", style: TextStyle(color: Colors.black54));
    }
  }
}
