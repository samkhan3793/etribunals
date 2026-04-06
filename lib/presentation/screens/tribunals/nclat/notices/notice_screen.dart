import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:etribunals/core/utils/web_scraper.dart' as web_scraper;
import 'package:etribunals/core/utils/model_bottom_sheet.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false;
  String? _error;
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7)); // Default end date
  String _formattedStartDate = '';
  String _formattedEndDate = '';

  List<Map<String, String>> _courtNames = [];
  String _selectedCourtId = 'All';

  @override
  void initState() {
    super.initState();
    _formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate);
    _formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate);
    _isLoading = true;
    _loadNoticeList();
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
        _error = 'Failed to load court names.';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, String>>> fetchCourtNames() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      {'id': 'All', 'name': 'Select All'},
      {'id': 'Registrar Court', 'name': 'Registrar Court'},
    ];
  }

  Future<void> _loadNoticeList() async {
    try {
      final data = await web_scraper.fetchNoticeListTable(_selectedCourtId, _formattedStartDate, _formattedEndDate);
      setState(() {
        _tableData = data.isNotEmpty ? data : [];
        _isLoading = false;
        _error = data.isEmpty ? 'No Data Found. Please modify your filter and try again.' : null;
      });
    } catch (e) {
      setState(() {
        _error = 'No Data Found. Please modify your filter and try again.';
        _tableData = [];
        _isLoading = false;
      });
    }
  }

  void _showFilterBottomSheet(BuildContext context, bool showDropdown) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BottomSheetContent(
          defaultStartDate: _startDate,
          defaultEndDate: _endDate,
          courtList: _courtNames, // Pass dynamic court list
          showDropdown: showDropdown,
          onFilterApplied: (selectedCourt, startDate, endDate) {
            setState(() {
              _selectedCourtId = selectedCourt;
              _formattedStartDate = startDate;
              _formattedEndDate = endDate!;
              _isLoading = true;
            });

            _loadNoticeList();
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
        title: customText("NCLAT Court Notices List", size: 20, color: AppColors.white),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterBottomSheet(context,false),
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
                                        child: entry.key == 'View/Download' &&
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
    print('Relative URL: $relativeUrl');
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
