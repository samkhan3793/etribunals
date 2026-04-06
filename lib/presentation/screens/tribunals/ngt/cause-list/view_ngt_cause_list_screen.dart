import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/utils/web_scraper.dart';

class ViewNgtCauseListScreen extends StatefulWidget {
  const ViewNgtCauseListScreen({super.key});

  @override
  State<ViewNgtCauseListScreen> createState() => _ViewNgtCauseListScreenState();
}

class _ViewNgtCauseListScreenState extends State<ViewNgtCauseListScreen> {
  List<Map<String, dynamic>> _tableData = [];
  List<Map<String, String>> _courtNames = [];
  String _selectedCourtId = 'principal-chairperson-bench';

  bool _isLoading = true;
  bool _isMoreLoading = false;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadCourtNames();
  }

  Future<void> _loadCourtNames() async {
    try {
      final courts = await fetchCourtNames();
      setState(() {
        _courtNames = courts;
        _selectedCourtId = courts.isNotEmpty ? courts[0]['id']! : 'all';
      });
      _loadCauseList(); // Load initial data
    } catch (e) {
      setState(() {
        _error = 'Failed to load court names.';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, String>>> fetchCourtNames() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'id': 'principal-chairperson-bench', 'name': 'Principal Chairperson Bench'},
      {'id': 'principal-court-II-cause-list', 'name': 'Principal Court-II Cause List'},
      {'id': 'principal-court-III-cause-list', 'name': 'Court-III Cause List'},
      {'id': 'principal-rg-court-cause-list', 'name': 'R G Court Cause List'},
      {'id': 'eastern-zone-cause-list', 'name': 'Eastern Zone Cause List'},
      {'id': 'western-zone-cause-list', 'name': 'Western Zone Cause List'},
      {'id': 'central-zone-cause-list', 'name': 'Central Zone Cause List'},
      {'id': 'southern-zone-cause-list', 'name': 'Southern Zone Cause List'},
    ];
  }

  Future<void> _loadCauseList({bool append = false}) async {
    if (!append) {
      setState(() {
        _currentPage = 0;
        _isLoading = true;
        _error = null;
        _tableData = [];
      });
    }

    try {
      final data = await fetchNgtCauseListTable(_selectedCourtId, _currentPage);
      setState(() {
        if (append) {
          _tableData.addAll(data);
          _isMoreLoading = false;
        } else {
          _tableData = data;
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cause list.';
        _isLoading = false;
        _isMoreLoading = false;
      });
    }
  }

  Widget _buildDownloadButton(Map<String, dynamic> valueMap) {
    final label = valueMap['label'] ?? 'Download';
    final url = valueMap['url'];
    return ElevatedButton.icon(
      icon: const Icon(Icons.download),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
      ),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          log('Could not launch $url');
        }
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> row) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    child: entry.value is Map<String, dynamic> && entry.value.containsKey('url')
                        ? _buildDownloadButton(entry.value)
                        : Text(
                            entry.value.toString(),
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text("NGT Cause List-(PDF)", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: customText(_error!, size: 16, color: Colors.red))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCourtId,
                        decoration: const InputDecoration(
                          labelText: 'Select Court',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        dropdownColor: AppColors.primary,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        isExpanded: true,
                        items: _courtNames.map((court) {
                          return DropdownMenuItem<String>(
                            value: court['id'],
                            child: Text(court['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (selected) {
                          if (selected != null && selected != _selectedCourtId) {
                            setState(() {
                              _selectedCourtId = selected;
                            });
                            _loadCauseList();
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _tableData.length + 1,
                        itemBuilder: (context, index) {
                          if (index < _tableData.length) {
                            return _buildCard(_tableData[index]);
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _isMoreLoading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton.icon(
                                        icon: const Icon(Icons.expand_more),
                                        label: const Text("View More"),
                                        onPressed: () {
                                          setState(() {
                                            _isMoreLoading = true;
                                            _currentPage += 1;
                                          });
                                          _loadCauseList(append: true);
                                        },
                                      ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
