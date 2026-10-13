import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/tdsat_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class TDSATScreen extends StatelessWidget {
  TDSATScreen({super.key});

  final options = [
    {'title': 'Case status', 'route': '/tdsat/case-status', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/tdsat/cause-list', 'icon': Icons.list_alt},
    {'title': 'Daily orders', 'route': '/tdsat/daily-orders', 'icon': Icons.description_outlined},
    {'title': 'Judgments', 'route': '/tdsat/judgments', 'icon': Icons.gavel},
    {'title': 'Record of proceedings', 'route': '/tdsat/proceedings', 'icon': Icons.menu_book_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('TDSAT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Case Management Services',
        subtitle: 'Official tdsat.gov.in Delhi  ·  cause list, case status, orders, judgments, proceedings',
        items: options,
      ),
    );
  }
}

class TdsatCaseStatusScreen extends StatefulWidget {
  const TdsatCaseStatusScreen({super.key});

  @override
  State<TdsatCaseStatusScreen> createState() => _TdsatCaseStatusScreenState();
}

class _TdsatCaseStatusScreenState extends State<TdsatCaseStatusScreen> {
  final _value = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  String _mode = 'case';
  String _type = '1';
  bool _busy = false;

  @override
  void dispose() {
    _value.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_value.text.trim().isEmpty || _year.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter number and year.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await TdsatClient.instance.searchCaseStatus(
        diary: _mode == 'diary',
        value: _value.text,
        year: _year.text,
        caseType: _type,
      );
      if (!mounted) return;
      if (file.blocks.isEmpty && file.orders.isEmpty) throw Exception('No TDSAT case found for this search.');
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TdsatRecordScreen(blocks: file.blocks, orders: file.orders, heading: 'TDSAT case status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('TDSAT case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Case Status',
            subtitle: 'tdsat.gov.in  ·  case no. or diary no.',
            color: Color(0xFF1A3A5A),
            icon: Icons.search,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Case no.'), selected: _mode == 'case', onSelected: (_) => setState(() => _mode = 'case')),
              ChoiceChip(label: const Text('Diary no.'), selected: _mode == 'diary', onSelected: (_) => setState(() => _mode = 'diary')),
            ],
          ),
          const SizedBox(height: 12),
          if (_mode == 'case') ...[
            _dd('Case type', _type, TdsatClient.caseTypes, (v) => setState(() => _type = v)),
            const SizedBox(height: 12),
          ],
          TextField(controller: _value, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _mode == 'diary' ? 'Diary number' : 'Case number')),
          const SizedBox(height: 12),
          TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : _search,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search'),
            ),
          ),
          const SourceFooter(tribunal: 'TDSAT', officialUrl: TdsatClient.caseStatusUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class TdsatCauseListScreen extends StatefulWidget {
  const TdsatCauseListScreen({super.key});

  @override
  State<TdsatCauseListScreen> createState() => _TdsatCauseListScreenState();
}

class _TdsatCauseListScreenState extends State<TdsatCauseListScreen> {
  DateTime _date = DateTime.now();
  bool _busy = false;
  List<TdsatHit> _rows = [];

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await TdsatClient.instance.causeList(_date);
      if (!mounted) return;
      setState(() => _rows = rows);
      if (rows.isEmpty) throw Exception('No TDSAT cause list for this date.');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('TDSAT cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Cause list', subtitle: 'tdsat.gov.in/Delhi daily cause list PDFs', color: Color(0xFF1A3A5A), icon: Icons.list_alt),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cause list date'),
            subtitle: Text(TdsatClient.instance.dateLabel(_date)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final next = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2015), lastDate: DateTime.now().add(const Duration(days: 14)));
              if (next != null) setState(() => _date = next);
            },
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : _search,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search'),
            ),
          ),
          const SizedBox(height: 12),
          for (final r in _rows)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(r.subtitle),
                trailing: const Icon(Icons.picture_as_pdf_outlined),
                onTap: r.fileUrl == null ? null : () => InAppDocumentScreen.open(context, r.fileUrl!, title: r.title, showOfficialLink: false),
              ),
            ),
          const SourceFooter(tribunal: 'TDSAT', officialUrl: TdsatClient.causeListUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class TdsatListingSearchScreen extends StatefulWidget {
  final String title;
  final String pageUrl;
  const TdsatListingSearchScreen({super.key, required this.title, required this.pageUrl});

  @override
  State<TdsatListingSearchScreen> createState() => _TdsatListingSearchScreenState();
}

class _TdsatListingSearchScreenState extends State<TdsatListingSearchScreen> {
  final _caseNo = TextEditingController();
  final _caseYear = TextEditingController();
  final _diaryNo = TextEditingController();
  final _diaryYear = TextEditingController();
  String _mode = 'dates';
  String _type = '1';
  DateTime _from = DateTime(DateTime.now().year - 1, DateTime.now().month, DateTime.now().day);
  DateTime _to = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _caseNo.dispose();
    _caseYear.dispose();
    _diaryNo.dispose();
    _diaryYear.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await TdsatClient.instance.searchOrders(
        pageUrl: widget.pageUrl,
        mode: _mode,
        caseType: _type,
        caseNo: _caseNo.text,
        caseYear: _caseYear.text,
        diaryNo: _diaryNo.text,
        diaryYear: _diaryYear.text,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No records for this search. Try a wider date range, or case/diary number.');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('${rows.length} results')),
            body: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final r = rows[i];
                return Card(
                  color: AppColors.paper,
                  child: ListTile(
                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(r.subtitle),
                    isThreeLine: r.subtitle.length > 40,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: r.fileUrl == null ? null : () => _openTdsatHit(context, r),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: widget.title, subtitle: 'Search by case, diary or date range', color: const Color(0xFF1A3A5A), icon: Icons.gavel),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Case no.'), selected: _mode == 'case', onSelected: (_) => setState(() => _mode = 'case')),
              ChoiceChip(label: const Text('Diary no.'), selected: _mode == 'diary', onSelected: (_) => setState(() => _mode = 'diary')),
              ChoiceChip(label: const Text('Dates (last 1 year)'), selected: _mode == 'dates', onSelected: (_) => setState(() => _mode = 'dates')),
            ],
          ),
          const SizedBox(height: 12),
          if (_mode == 'case') ...[
            _dd('Case type', _type, TdsatClient.caseTypes, (v) => setState(() => _type = v)),
            const SizedBox(height: 12),
            TextField(controller: _caseNo, decoration: const InputDecoration(labelText: 'Case number')),
            const SizedBox(height: 12),
            TextField(controller: _caseYear, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Case year')),
          ],
          if (_mode == 'diary') ...[
            TextField(controller: _diaryNo, decoration: const InputDecoration(labelText: 'Diary number')),
            const SizedBox(height: 12),
            TextField(controller: _diaryYear, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diary year')),
          ],
          if (_mode == 'dates') ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('From date'),
              subtitle: Text(TdsatClient.instance.dateLabel(_from)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final next = await showDatePicker(context: context, initialDate: _from, firstDate: DateTime(2000), lastDate: DateTime.now());
                if (next != null) setState(() => _from = next);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('To date'),
              subtitle: Text(TdsatClient.instance.dateLabel(_to)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final next = await showDatePicker(context: context, initialDate: _to, firstDate: DateTime(2000), lastDate: DateTime.now());
                if (next != null) setState(() => _to = next);
              },
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : _search,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search'),
            ),
          ),
          SourceFooter(tribunal: 'TDSAT', officialUrl: widget.pageUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class TdsatViewScreen extends StatefulWidget {
  final String url;
  final String heading;
  final TdsatHit? seed;
  const TdsatViewScreen({super.key, required this.url, required this.heading, this.seed});

  @override
  State<TdsatViewScreen> createState() => _TdsatViewScreenState();
}

class _TdsatViewScreenState extends State<TdsatViewScreen> {
  List<TdsatBlock> _blocks = [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse(widget.url);
      final filing = uri.queryParameters['filing_no'] ?? widget.seed?.fields['filing_no'] ?? '';
      final blocks = filing.isEmpty ? TdsatClient.parseBlocks('') : await TdsatClient.instance.orderView(filing);
      if (!mounted) return;
      setState(() {
        _blocks = blocks;
        _loading = false;
        if (blocks.isEmpty) _error = 'No document text returned.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text(widget.heading)), body: const Center(child: CircularProgressIndicator()));
    }
    return TdsatRecordScreen(blocks: _blocks, heading: widget.heading, seedTitle: widget.seed?.title, error: _error);
  }
}

class TdsatRecordScreen extends StatelessWidget {
  final List<TdsatBlock> blocks;
  final List<TdsatHit> orders;
  final String heading;
  final String? seedTitle;
  final String? error;
  const TdsatRecordScreen({
    super.key,
    required this.blocks,
    this.orders = const [],
    required this.heading,
    this.seedTitle,
    this.error,
  });

  Map<String, String> get _flat {
    final out = <String, String>{};
    for (final b in blocks) {
      for (final f in b.fields) {
        if (f.value.trim().isNotEmpty) out[f.key] = f.value;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final flat = _flat;
    final title = seedTitle ??
        flat['Case Type/Case No/Year'] ??
        flat['Diary no/Year'] ??
        heading;
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(heading),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('TDSAT', flat['Diary no/Year'] ?? title),
              tribunal: 'TDSAT',
              filingNo: flat['Diary no/Year'] ?? '',
              caseNo: flat['Case Type/Case No/Year'] ?? title,
              title: title,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'tdsat_json',
              payload: jsonEncode({
                'heading': heading,
                'orders': [
                  for (final o in orders)
                    {'title': o.title, 'subtitle': o.subtitle, 'fileUrl': o.fileUrl, 'fields': o.fields},
                ],
                'blocks': [
                  for (final b in blocks)
                    {
                      'title': b.title,
                      'fields': [for (final f in b.fields) {'k': f.key, 'v': f.value}],
                      'headers': b.headers,
                      'rows': b.rows,
                    },
                ],
              }),
              sourceUrl: TdsatClient.home,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: title,
            subtitle: [
              if ((flat['Diary no/Year'] ?? '').isNotEmpty) 'Diary ${flat['Diary no/Year']}',
              if ((flat['Case Status'] ?? '').isNotEmpty) flat['Case Status']!,
            ].join('  ·  '),
            color: const Color(0xFF1A3A5A),
            icon: Icons.folder_open,
          ),
          if (error != null)
            Padding(padding: const EdgeInsets.only(top: 16), child: Text(error!, style: const TextStyle(color: AppColors.stampRed))),
          for (final block in blocks) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x3314384A))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.title.toUpperCase(), style: const TextStyle(color: Color(0xFFC4A265), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  for (final f in block.fields)
                    if (f.value.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 120, child: Text(f.key, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5))),
                            Expanded(child: Text(f.value, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35))),
                          ],
                        ),
                      ),
                  if (block.fields.isEmpty && block.rows.isEmpty)
                    Text(block.title, style: const TextStyle(height: 1.35)),
                  if (block.rows.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 36,
                        columns: [
                          for (final h in (block.headers.isEmpty ? List.generate(block.rows.first.length, (i) => 'Col ${i + 1}') : block.headers))
                            DataColumn(label: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                        ],
                        rows: [
                          for (final r in block.rows)
                            DataRow(
                              cells: [
                                for (var i = 0; i < (block.headers.isEmpty ? r.length : block.headers.length); i++)
                                  DataCell(Text(i < r.length ? r[i] : '', style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (orders.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('ORDER DETAILS', style: TextStyle(color: Color(0xFFC4A265), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            for (final o in orders)
              Card(
                color: AppColors.paper,
                child: ListTile(
                  leading: const Icon(Icons.description_outlined, color: Color(0xFF1A3A5A)),
                  title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(o.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: o.fileUrl == null ? null : () => _openTdsatHit(context, o),
                ),
              ),
          ],
          const SourceFooter(tribunal: 'TDSAT', officialUrl: TdsatClient.home, showOfficialLink: false),
        ],
      ),
    );
  }
}

Future<void> _openTdsatHit(BuildContext context, TdsatHit hit) {
  final url = hit.fileUrl ?? '';
  if (url.toLowerCase().contains('.pdf')) {
    return InAppDocumentScreen.open(context, url, title: hit.title, showOfficialLink: false);
  }
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TdsatViewScreen(url: url, heading: hit.title, seed: hit)),
  );
}

List<TdsatBlock> tdsatBlocksFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map)
        TdsatBlock(
          title: '${item['title'] ?? 'Record'}',
          fields: [
            for (final f in (item['fields'] as List? ?? const []))
              if (f is Map) MapEntry('${f['k'] ?? ''}', '${f['v'] ?? ''}'),
          ],
          headers: [for (final h in (item['headers'] as List? ?? const [])) '$h'],
          rows: [
            for (final r in (item['rows'] as List? ?? const []))
              if (r is List) [for (final c in r) '$c'],
          ],
        ),
  ];
}

List<TdsatHit> tdsatHitsFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map)
        TdsatHit(
          title: '${item['title'] ?? 'Order'}',
          subtitle: '${item['subtitle'] ?? ''}',
          fileUrl: item['fileUrl'] == null ? null : '${item['fileUrl']}',
          fields: {
            if (item['fields'] is Map)
              for (final e in (item['fields'] as Map).entries) '${e.key}': '${e.value}',
          },
        ),
  ];
}

Widget _dd(String label, String value, List<MapEntry<String, String>> items, ValueChanged<String> onChanged) {
  final exists = items.any((e) => e.key == value);
  return InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: exists ? value : items.first.key,
        items: items.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}
