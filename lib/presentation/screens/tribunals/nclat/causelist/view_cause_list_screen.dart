import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/utils/web_scraper.dart';
import 'package:intl/intl.dart';
import 'package:etribunals/core/utils/model_bottom_sheet.dart';

class ViewCauseListScreen extends StatefulWidget {
  const ViewCauseListScreen({super.key});

  @override
  State<ViewCauseListScreen> createState() => _ViewCauseListScreenState();
}

class _ViewCauseListScreenState extends State<ViewCauseListScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;
  String? _error;

  final DateTime _startDate = DateTime.now();
  final DateTime _endDate = DateTime.now().add(const Duration(days: 7)); // Default end date

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
    _loadCauseList();
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
      {'id': '42', 'name': 'Chairperson Court'},
      {'id': '43', 'name': 'Chennai Bench'},
      {'id': '47', 'name': 'Registrar Court'},
      {'id': '44', 'name': 'Court - 2'},
      {'id': '45', 'name': 'Court - 3'},
      {'id': '46', 'name': 'Court - 4'},
    ];
  }

  Future<void> _loadCauseList() async {
    try {
      final data = await fetchCauseListTable(_selectedCourtId, _formattedStartDate, _formattedEndDate);
      setState(() {
        _tableData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cause list.';
        _isLoading = false;
      });
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 16,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Visual Grab Handle
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                BottomSheetContent(
                  defaultStartDate: DateTime.now(),
                  defaultEndDate: DateTime.now().add(const Duration(days: 7)),
                  courtList: _courtNames,
                  onFilterApplied: (selectedCourt, startDate, endDate) {
                    setState(() {
                      _selectedCourtId = selectedCourt;
                      _formattedStartDate = startDate;
                      _formattedEndDate = endDate!;
                      _isLoading = true;
                    });
                    _loadCauseList();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSelectedCourtName() {
    final court = _courtNames.firstWhere(
      (element) => element['id'] == _selectedCourtId,
      orElse: () => {'name': 'All Courts'},
    );
    return court['name']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('NCLAT cause list'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _loadCauseList();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CourtBand(
              title: _getSelectedCourtName(),
              subtitle: '$_formattedStartDate  â†’  $_formattedEndDate',
              icon: Icons.list_alt,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.account_balance, size: 16),
                  label: Text(_getSelectedCourtName()),
                  onPressed: () => _showFilterBottomSheet(context),
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month, size: 16),
                  label: Text('$_formattedStartDate â€“ $_formattedEndDate'),
                  onPressed: () => _showFilterBottomSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Center(child: customText(_error!, color: AppColors.stampRed, align: TextAlign.center))
            else if (_tableData.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('No cause lists for this filter')),
              )
            else
              ..._tableData.map(_buildDocumentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> row) {
    final downloadInfo = row['View/Download'] as Map<String, dynamic>?;
    final dateStr = row['Date']?.toString() ?? 'Date not listed';
    final courtStr = row['Court Name']?.toString() ?? 'Court';
    final pdfUrl = downloadInfo?['url']?.toString();

    return Card(
      color: AppColors.paper,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0x3314384A)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(courtStr, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15.5)),
            const SizedBox(height: 4),
            Text(dateStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: pdfUrl == null ? null : () => _openPdf(pdfUrl, courtStr),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Open PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdf(String relativeUrl, String title) async {
    final cleanPath = relativeUrl.startsWith('http')
        ? relativeUrl
        : (relativeUrl.startsWith('/') ? relativeUrl : '/$relativeUrl');
    final fullUrl = cleanPath.startsWith('http') ? cleanPath : 'https://nclat.nic.in$cleanPath';
    await InAppDocumentScreen.open(context, fullUrl, title: title);
  }
}
