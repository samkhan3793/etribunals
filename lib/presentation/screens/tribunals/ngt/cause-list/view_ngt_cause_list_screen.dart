import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/drupal_listing.dart';
import 'package:etribunals/core/utils/web_scraper.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:flutter/material.dart';

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

  String get _courtLabel {
    for (final court in _courtNames) {
      if (court['id'] == _selectedCourtId) return court['name'] ?? 'Cause list';
    }
    return 'Cause list';
  }

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
      await _loadCauseList();
    } catch (_) {
      setState(() {
        _error = 'Could not load benches.';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, String>>> fetchCourtNames() async {
    return [
      {'id': 'principal-chairperson-bench', 'name': 'Principal Chairperson Bench'},
      {'id': 'principal-court-II-cause-list', 'name': 'Principal Court-II'},
      {'id': 'principal-court-III-cause-list', 'name': 'Principal Court-III'},
      {'id': 'principal-rg-court-cause-list', 'name': 'R G Court'},
      {'id': 'eastern-zone-cause-list', 'name': 'Eastern Zone'},
      {'id': 'western-zone-cause-list', 'name': 'Western Zone'},
      {'id': 'central-zone-cause-list', 'name': 'Central Zone'},
      {'id': 'southern-zone-cause-list', 'name': 'Southern Zone'},
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
      if (!mounted) return;
      setState(() {
        if (append) {
          _tableData.addAll(data);
          _isMoreLoading = false;
        } else {
          _tableData = data;
          _isLoading = false;
        }
        if (!append && data.isEmpty) _error = 'No cause list PDFs for this bench.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the official NGT cause list.';
        _isLoading = false;
        _isMoreLoading = false;
      });
    }
  }

  String _plain(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      final label = (value['label'] ?? '').toString().trim();
      final url = (value['url'] ?? '').toString().trim();
      return '$label $url'.trim();
    }
    return value.toString().trim();
  }

  String? _extractDate(String text) {
    var decoded = text.replaceAll('%20', ' ');
    try {
      decoded = Uri.decodeComponent(decoded);
    } catch (_) {}
    final long = RegExp(
      r'(\d{1,2}(?:st|nd|rd|th)?\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4})',
      caseSensitive: false,
    ).firstMatch(decoded);
    if (long != null) return long.group(1)!.replaceAll(RegExp(r'(st|nd|rd|th)(?=\s)'), '');
    final numeric = RegExp(r'(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})').firstMatch(decoded);
    return numeric?.group(1);
  }

  Map<String, dynamic>? _pdf(Map<String, dynamic> row) {
    for (final value in row.values) {
      if (value is Map && value['url'] != null) return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String _title(Map<String, dynamic> row) {
    for (final key in ['Title', 'Cause List', 'Subject', 'Description', 'Particulars']) {
      final text = _plain(row[key]);
      if (text.isNotEmpty) {
        return text
            .replaceAll(RegExp(r'https?:\/\/\S+'), '')
            .replaceFirst(RegExp(r'^Click here to see\s*', caseSensitive: false), '')
            .trim();
      }
    }
    for (final entry in row.entries) {
      if (entry.value is Map) continue;
      final text = _plain(entry.value);
      if (text.isNotEmpty && !RegExp(r'^\d+$').hasMatch(text)) return text;
    }
    return 'Cause list PDF';
  }

  String _date(Map<String, dynamic> row) {
    for (final entry in row.entries) {
      if (entry.key.toLowerCase().contains('date')) {
        final found = _extractDate(_plain(entry.value));
        if (found != null) return found;
        final raw = _plain(entry.value);
        if (raw.isNotEmpty && !raw.toLowerCase().startsWith('http')) return raw;
      }
    }
    for (final value in row.values) {
      final found = _extractDate(_plain(value));
      if (found != null) return found;
    }
    return '';
  }

  void _openPdf(Map<String, dynamic> pdf) {
    final href = pdf['url'].toString();
    InAppDocumentScreen.open(
      context,
      href.startsWith('http') ? href : absoluteUrl(href, host: 'https://www.greentribunal.gov.in'),
      title: (pdf['label'] ?? 'Cause list').toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('NGT cause list')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CourtBand(
              title: 'NGT daily cause list',
              subtitle: _isLoading ? 'Fetching official PDFs…' : '$_courtLabel  ·  ${_tableData.length} lists',
              color: const Color(0xFF1F6B32),
              icon: Icons.list_alt_rounded,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _courtNames.any((c) => c['id'] == _selectedCourtId) ? _selectedCourtId : null,
              decoration: const InputDecoration(
                labelText: 'Bench',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              dropdownColor: Colors.white,
              isExpanded: true,
              items: _courtNames
                  .map((court) => DropdownMenuItem(value: court['id'], child: Text(court['name'] ?? '')))
                  .toList(),
              onChanged: (selected) {
                if (selected != null && selected != _selectedCourtId) {
                  setState(() => _selectedCourtId = selected);
                  _loadCauseList();
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _tableData.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadCauseList, child: const Text('Try again')),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: () => _loadCauseList(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _tableData.length + 1,
                          itemBuilder: (context, index) {
                            if (index >= _tableData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _isMoreLoading
                                    ? const Center(child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ))
                                    : OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _isMoreLoading = true;
                                            _currentPage += 1;
                                          });
                                          _loadCauseList(append: true);
                                        },
                                        icon: const Icon(Icons.expand_more),
                                        label: const Text('Load more lists'),
                                      ),
                              );
                            }
                            return _causeCard(_tableData[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _causeCard(Map<String, dynamic> row) {
    return _NgtCauseDocket(
      date: _date(row),
      title: _title(row),
      pdf: _pdf(row),
      onOpen: _openPdf,
    );
  }
}

class _NgtCauseDocket extends StatefulWidget {
  final String date;
  final String title;
  final Map<String, dynamic>? pdf;
  final void Function(Map<String, dynamic> pdf) onOpen;

  const _NgtCauseDocket({
    required this.date,
    required this.title,
    required this.pdf,
    required this.onOpen,
  });

  @override
  State<_NgtCauseDocket> createState() => _NgtCauseDocketState();
}

class _NgtCauseDocketState extends State<_NgtCauseDocket> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x3314384A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: const Color(0xFF1F6B32)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const MetaChip(label: 'Cause list', color: Color(0xFF1F6B32)),
                            const Spacer(),
                            Text(
                              widget.date.isEmpty ? 'Date N/A' : widget.date,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.pdf != null)
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F6B32),
                                minimumSize: const Size.fromHeight(40),
                              ),
                              onPressed: () => widget.onOpen(widget.pdf!),
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text('Open PDF', style: TextStyle(fontSize: 13.5)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFF3EEE6),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _open = !_open),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      children: [
                        Text(
                          _open ? 'Hide particulars' : 'Particulars',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.stampBlue),
                        ),
                        const Spacer(),
                        Icon(_open ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.stampBlue),
                      ],
                    ),
                  ),
                ),
                if (_open)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600, color: AppColors.ink),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
