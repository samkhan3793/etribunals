import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/drupal_listing.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Maps live Drupal listings from nclt.gov.in (typo paths on the official site are real).
class NcltPublicListScreen extends StatefulWidget {
  final String path;
  final String heading;
  final bool showTitleFilter;
  final bool showBenchFilter;

  const NcltPublicListScreen({
    super.key,
    required this.path,
    required this.heading,
    this.showTitleFilter = true,
    this.showBenchFilter = false,
  });

  @override
  State<NcltPublicListScreen> createState() => _NcltPublicListScreenState();
}

class _NcltPublicListScreenState extends State<NcltPublicListScreen> {
  final _title = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  List<Map<String, String>> _rows = [];
  Map<String, String> _benches = {};
  String? _bench;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _title.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final params = <String, String>{};
    if (widget.showTitleFilter && _title.text.trim().isNotEmpty) {
      params['title'] = _title.text.trim();
    }
    if (_start.text.isNotEmpty) params['field_issue_date_value'] = _start.text;
    if (_end.text.isNotEmpty) params['field_issue_date_value_1'] = _end.text;
    if (widget.showBenchFilter) {
      if (_start.text.isNotEmpty) params['field_cause_date_value'] = _start.text;
      if (_end.text.isNotEmpty) params['field_cause_date_value_1'] = _end.text;
      params.remove('field_issue_date_value');
      params.remove('field_issue_date_value_1');
      if (_bench != null) params['field_nclt_benches_list_target_id'] = _bench!;
    }

    try {
      final uri = Uri.https('nclt.gov.in', widget.path, params.isEmpty ? null : params);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Official page returned ${response.statusCode}');
      }
      final rows = parseDrupalListingTable(response.body);
      final benches = parseSelectOptions(response.body, 'field_nclt_benches_list_target_id');
      if (!mounted) return;
      setState(() {
        _rows = rows;
        if (benches.isNotEmpty) {
          _benches = benches;
          _bench ??= benches.keys.first;
        }
        _loading = false;
        if (rows.isEmpty) _error = 'No rows on nclt.gov.in${widget.path} for this filter.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      controller.text = DateFormat('MM/dd/yyyy').format(picked);
    }
  }

  bool _isLink(MapEntry<String, String> entry) {
    if (entry.key.endsWith('_label')) return false;
    final v = entry.value.toLowerCase();
    return v.contains('.pdf') || v.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(widget.heading)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                if (widget.showBenchFilter && _benches.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _bench,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(labelText: 'Bench'),
                    items: _benches.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _bench = v),
                  ),
                if (widget.showTitleFilter)
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title (optional)'),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _start,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'From'),
                        onTap: () => _pickDate(_start),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _end,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'To'),
                        onTap: () => _pickDate(_end),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _fetch, child: const Text('Refresh from nclt.gov.in')),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error ?? 'Loading official listing…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return Card(
                        color: AppColors.paper,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0x3314384A)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: row.entries.where((e) => !e.key.endsWith('_label')).map((entry) {
                              final link = _isLink(entry);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted, fontSize: 12)),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: link
                                          ? TextButton(
                                              onPressed: () => InAppDocumentScreen.open(
                                                context,
                                                entry.value,
                                                title: row['${entry.key}_label'] ?? 'Document',
                                              ),
                                              child: Text(row['${entry.key}_label'] ?? 'Open PDF'),
                                            )
                                          : Text(entry.value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
          ),
        ],
      ),
    );
  }
}
