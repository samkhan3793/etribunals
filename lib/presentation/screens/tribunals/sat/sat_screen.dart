import 'dart:convert';
import 'dart:typed_data';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/sat_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class SATScreen extends StatelessWidget {
  SATScreen({super.key});

  final options = [
    {'title': 'Case status', 'route': '/sat/case-status', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/sat/cause-list', 'icon': Icons.list_alt},
    {'title': 'Orders', 'route': '/sat/orders', 'icon': Icons.gavel},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('SAT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Case Information',
        subtitle: 'Official satweb.sat.gov.in  ·  Mumbai bench  ·  case status, cause list, orders',
        items: options,
      ),
    );
  }
}

class SatCaseStatusScreen extends StatefulWidget {
  const SatCaseStatusScreen({super.key});

  @override
  State<SatCaseStatusScreen> createState() => _SatCaseStatusScreenState();
}

class _SatCaseStatusScreenState extends State<SatCaseStatusScreen> {
  final _no = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _party = TextEditingController();
  String _mode = 'case';
  String _type = '1';
  bool _busy = false;

  @override
  void dispose() {
    _no.dispose();
    _year.dispose();
    _party.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await SatClient.instance.searchCase(
        mode: _mode,
        caseType: _type,
        caseNo: _no.text,
        year: _year.text,
        alNo: _no.text,
        party: _party.text,
      );
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No SAT case found for this search.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => SatHitsScreen(heading: 'SAT case status', rows: rows)));
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
      appBar: AppBar(title: const Text('SAT case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Case Status', subtitle: 'satweb.sat.gov.in  ·  appeal no., AL no. or party', color: Color(0xFF1E3A4A), icon: Icons.search),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Appeal no.'), selected: _mode == 'case', onSelected: (_) => setState(() => _mode = 'case')),
            ChoiceChip(label: const Text('AL no.'), selected: _mode == 'al', onSelected: (_) => setState(() => _mode = 'al')),
            ChoiceChip(label: const Text('Party'), selected: _mode == 'party', onSelected: (_) => setState(() => _mode = 'party')),
          ]),
          const SizedBox(height: 12),
          if (_mode == 'case') _dd('Appeal type', _type, SatClient.appealTypes, (v) => setState(() => _type = v)),
          if (_mode == 'party') TextField(controller: _party, decoration: const InputDecoration(labelText: 'Party name')),
          if (_mode != 'party') TextField(controller: _no, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _mode == 'al' ? 'AL number' : 'Appeal number')),
          const SizedBox(height: 12),
          TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          _searchBtn(_busy, _search),
          const SourceFooter(tribunal: 'SAT', officialUrl: SatClient.caseStatusUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class SatCauseListScreen extends StatefulWidget {
  const SatCauseListScreen({super.key});

  @override
  State<SatCauseListScreen> createState() => _SatCauseListScreenState();
}

class _SatCauseListScreenState extends State<SatCauseListScreen> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  bool _busy = false;
  List<SatHit> _rows = [];

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await SatClient.instance.causeList(_from, _to);
      if (!mounted) return;
      setState(() => _rows = rows);
      if (rows.isEmpty) throw Exception('No SAT cause list for these dates.');
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
      appBar: AppBar(title: const Text('SAT cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Cause list', subtitle: 'satweb.sat.gov.in/causelist', color: Color(0xFF1E3A4A), icon: Icons.list_alt),
          _dateTile('Start date', _from, (d) => setState(() => _from = d)),
          _dateTile('End date', _to, (d) => setState(() => _to = d)),
          _searchBtn(_busy, _search),
          const SizedBox(height: 12),
          for (final r in _rows) SatHitTile(hit: r),
          const SourceFooter(tribunal: 'SAT', officialUrl: SatClient.causeListUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class SatOrdersSearchScreen extends StatefulWidget {
  const SatOrdersSearchScreen({super.key});

  @override
  State<SatOrdersSearchScreen> createState() => _SatOrdersSearchScreenState();
}

class _SatOrdersSearchScreenState extends State<SatOrdersSearchScreen> {
  String _mode = 'case';
  final _no = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _party = TextEditingController();
  String _type = '1';
  DateTime _from = DateTime(DateTime.now().year - 1, DateTime.now().month, DateTime.now().day);
  DateTime _to = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _no.dispose();
    _year.dispose();
    _party.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await SatClient.instance.searchOrders(
        mode: _mode,
        caseType: _type,
        caseNo: _no.text,
        year: _year.text,
        alNo: _no.text,
        party: _party.text,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No SAT order found for this search.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => SatHitsScreen(heading: 'SAT orders', rows: rows)));
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
      appBar: AppBar(title: const Text('SAT orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Orders', subtitle: 'satweb.sat.gov.in/orders', color: Color(0xFF1E3A4A), icon: Icons.gavel),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Appeal no.'), selected: _mode == 'case', onSelected: (_) => setState(() => _mode = 'case')),
            ChoiceChip(label: const Text('AL no.'), selected: _mode == 'al', onSelected: (_) => setState(() => _mode = 'al')),
            ChoiceChip(label: const Text('Party'), selected: _mode == 'party', onSelected: (_) => setState(() => _mode = 'party')),
            ChoiceChip(label: const Text('Date'), selected: _mode == 'date', onSelected: (_) => setState(() => _mode = 'date')),
          ]),
          if (_mode == 'case' || _mode == 'date') _dd('Appeal type', _type, SatClient.appealTypes, (v) => setState(() => _type = v)),
          if (_mode == 'date') ...[
            _dateTile('From', _from, (d) => setState(() => _from = d)),
            _dateTile('To', _to, (d) => setState(() => _to = d)),
          ],
          if (_mode == 'party') TextField(controller: _party, decoration: const InputDecoration(labelText: 'Party name')),
          if (_mode == 'case' || _mode == 'al') TextField(controller: _no, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _mode == 'al' ? 'AL number' : 'Appeal number')),
          if (_mode != 'date') TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          _searchBtn(_busy, _search),
          const SourceFooter(tribunal: 'SAT', officialUrl: SatClient.ordersUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class SatHitsScreen extends StatelessWidget {
  final String heading;
  final List<SatHit> rows;
  const SatHitsScreen({super.key, required this.heading, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(heading)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in rows) SatHitTile(hit: r),
          const SourceFooter(tribunal: 'SAT', officialUrl: SatClient.host, showOfficialLink: false),
        ],
      ),
    );
  }
}

class SatHitTile extends StatelessWidget {
  final SatHit hit;
  const SatHitTile({super.key, required this.hit});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.paper,
      child: ListTile(
        title: Text(hit.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: hit.subtitle.isEmpty ? null : Text(hit.subtitle),
        trailing: Icon(hit.fileUrl != null ? Icons.picture_as_pdf_outlined : Icons.chevron_right),
        onTap: () => _openSatHit(context, hit),
      ),
    );
  }
}

Future<void> _openSatDoc(BuildContext context, String url, String title) async {
  try {
    if (url.contains('/view-order/')) {
      final bytes = await SatClient.instance.orderPdf(url);
      if (!context.mounted) return;
      await InAppDocumentScreen.open(
        context,
        url,
        title: title,
        showOfficialLink: false,
        pdfBytes: Uint8List.fromList(bytes),
      );
      return;
    }
    if (url.contains('/view-causelist/')) {
      final html = await SatClient.instance.causeListHtml(url);
      if (!context.mounted) return;
      await InAppDocumentScreen.open(context, url, title: title, showOfficialLink: false, htmlBody: html);
      return;
    }
    await InAppDocumentScreen.open(context, url, title: title, showOfficialLink: false);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    }
  }
}

Future<void> _openSatHit(BuildContext context, SatHit hit) async {
  if (hit.fileUrl != null) {
    await _openSatDoc(context, hit.fileUrl!, hit.title);
    return;
  }
  if (hit.filingNo == null || hit.filingNo!.isEmpty) return;
  try {
    final blocks = await SatClient.instance.caseHistory(hit.filingNo!);
    if (!context.mounted) return;
    if (blocks.isEmpty) throw Exception('No SAT case details found.');
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SatRecordScreen(blocks: blocks, heading: 'SAT case status', seedTitle: hit.title, filingNo: hit.filingNo!)),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    }
  }
}

class SatRecordScreen extends StatelessWidget {
  final List<SatBlock> blocks;
  final String heading;
  final String? seedTitle;
  final String filingNo;
  const SatRecordScreen({super.key, required this.blocks, required this.heading, this.seedTitle, required this.filingNo});

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
    final title = seedTitle ?? flat['Applicant'] ?? heading;
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(heading),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('SAT', filingNo),
              tribunal: 'SAT',
              filingNo: filingNo,
              caseNo: seedTitle ?? title,
              title: title,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'sat_json',
              payload: jsonEncode({
                'heading': heading,
                'filingNo': filingNo,
                'blocks': [
                  for (final b in blocks)
                    {
                      'title': b.title,
                      'fields': [for (final f in b.fields) {'k': f.key, 'v': f.value}],
                      'headers': b.headers,
                      'rows': b.rows,
                      'links': b.links,
                    },
                ],
              }),
              sourceUrl: SatClient.caseStatusUrl,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: title, subtitle: 'Filing $filingNo', color: const Color(0xFF1E3A4A), icon: Icons.show_chart_outlined),
          for (final b in blocks)
            Card(
              color: AppColors.paper,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (b.fields.isNotEmpty)
                      for (final f in b.fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: '${f.key}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: f.value),
                          ])),
                        )
                    else if (b.headers.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [for (final h in b.headers) DataColumn(label: Text(h))],
                          rows: [
                            for (var ri = 0; ri < b.rows.length; ri++)
                              DataRow(
                                cells: [
                                  for (var i = 0; i < b.headers.length; i++)
                                    DataCell(
                                      i < b.rows[ri].length &&
                                              b.rows[ri][i].toLowerCase() == 'view' &&
                                              ri < b.links.length &&
                                              (b.links[ri] ?? '').isNotEmpty
                                          ? TextButton(
                                              onPressed: () => _openSatDoc(context, b.links[ri]!, 'SAT order'),
                                              child: const Text('View'),
                                            )
                                          : Text(i < b.rows[ri].length ? b.rows[ri][i] : ''),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SourceFooter(tribunal: 'SAT', officialUrl: SatClient.caseStatusUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

List<SatBlock> satBlocksFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map)
        SatBlock(
          title: '${item['title'] ?? ''}',
          fields: [
            for (final f in (item['fields'] as List? ?? const []))
              if (f is Map) MapEntry('${f['k'] ?? ''}', '${f['v'] ?? ''}'),
          ],
          headers: [for (final h in (item['headers'] as List? ?? const [])) '$h'],
          rows: [
            for (final r in (item['rows'] as List? ?? const []))
              if (r is List) [for (final c in r) '$c'],
          ],
          links: [for (final l in (item['links'] as List? ?? const [])) l == null ? null : '$l'],
        ),
  ];
}

Widget _dd(String label, String value, List<MapEntry<String, String>> items, ValueChanged<String> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: [for (final e in items) DropdownMenuItem(value: e.key, child: Text(e.value))],
      onChanged: (v) { if (v != null) onChanged(v); },
    ),
  );
}

Widget _dateTile(String label, DateTime value, ValueChanged<DateTime> onChanged) {
  return Builder(
    builder: (context) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(SatClient.instance.uiDate(value)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final next = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2005), lastDate: DateTime.now().add(const Duration(days: 14)));
        if (next != null) onChanged(next);
      },
    ),
  );
}

Widget _searchBtn(bool busy, VoidCallback onPressed) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Search'),
      ),
    ),
  );
}
