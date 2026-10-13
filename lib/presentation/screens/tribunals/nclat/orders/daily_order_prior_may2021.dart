import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/utils/drupal_listing.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/utils/web_scraper.dart' as web_scraper;
import 'package:etribunals/core/utils/model_bottom_sheet.dart';

class ViewPriorDailyOrdersScreen extends StatefulWidget {
  const ViewPriorDailyOrdersScreen({super.key});

  @override
  State<ViewPriorDailyOrdersScreen> createState() => _ViewPriorDailyOrdersScreenState();
}

class _ViewPriorDailyOrdersScreenState extends State<ViewPriorDailyOrdersScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false;
  String? _error;
  String _formattedStartDate = '';
  String _formattedEndDate = '';

  List<Map<String, String>> _courtNames = [];
  String _selectedCourtId = 'All';

  @override
  void initState() {
    super.initState();
    _formattedStartDate = '2021-05-01';
    _formattedEndDate = '2021-05-31';
    _isLoading = true;
    _loadDailyOrderList();
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
      {'id': 'Chairperson Court', 'name': 'Chairperson Court'},
      {'id': 'Chennai Bench', 'name': 'Chennai Bench'},
      {'id': 'Registrar Court', 'name': 'Registrar Court'},
      {'id': 'Court - 2', 'name': 'Court - 2'},
      {'id': 'Court - 3', 'name': 'Court - 3'},
      {'id': 'Court - 4', 'name': 'Court - 4'},
    ];
  }

  Future<void> _loadDailyOrderList() async {
    try {
      final data = await web_scraper.fetchDailyOrderPriorMay2021ListTable(_selectedCourtId, _formattedStartDate, _formattedEndDate);
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BottomSheetContent(
          defaultStartDate: DateTime(2021, 5, 1),
          defaultEndDate: DateTime(2021, 5, 31),
          courtList: _courtNames, // Pass dynamic court list
          onFilterApplied: (selectedCourt, startDate, endDate) {
            setState(() {
              _selectedCourtId = selectedCourt;
              _formattedStartDate = startDate;
              _formattedEndDate = endDate!;
              _isLoading = true;
            });

            _loadDailyOrderList();
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
        title: customText("Daily Order List Prior:May 2021", size: 20, color: AppColors.white),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterBottomSheet(context),
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
                                        child: entry.value is Map<String, dynamic> &&
                                                (entry.value as Map).containsKey('url')
                                            ? _buildDownloadWidget(Map<String, dynamic>.from(entry.value as Map))
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

    if (relativeUrl != null && relativeUrl.toString().isNotEmpty) {
      final fullUrl = absoluteUrl(relativeUrl.toString(), host: 'https://nclat.nic.in');
      return InkWell(
        onTap: () async {
          await InAppDocumentScreen.open(context, fullUrl, title: label.toString());
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
