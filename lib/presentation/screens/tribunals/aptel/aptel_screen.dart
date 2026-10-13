import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/aptel_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class APTELScreen extends StatelessWidget {
  APTELScreen({super.key});

  final options = [
    {'title': 'Case status', 'route': '/aptel/case-status', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/aptel/cause-list', 'icon': Icons.list_alt},
    {'title': 'Daily orders', 'route': '/aptel/daily-orders', 'icon': Icons.description_outlined},
    {'title': 'Orders / judgements', 'route': '/aptel/judgements', 'icon': Icons.gavel},
    {'title': 'Display board', 'route': '/aptel/display-board', 'icon': Icons.tv_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('APTEL', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Case Management Services',
        subtitle: 'Official aptel.gov.in  ·  case status, cause list, daily orders, judgements, display board',
        items: options,
      ),
    );
  }
}

class AptelCaseStatusScreen extends StatefulWidget {
  const AptelCaseStatusScreen({super.key});

  @override
  State<AptelCaseStatusScreen> createState() => _AptelCaseStatusScreenState();
}

class _AptelCaseStatusScreenState extends State<AptelCaseStatusScreen> {
  final _no = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _party = TextEditingController();
  String _mode = 'case';
  String _type = '1';
  String _partyType = '1';
  DateTime _from = DateTime.now().subtract(const Duration(days: 14));
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
      final rows = await AptelClient.instance.searchCase(
        mode: _mode,
        diaryNo: _no.text,
        caseNo: _no.text,
        year: _year.text,
        caseType: _type,
        partyName: _party.text,
        partyType: _partyType,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No APTEL case found for this search.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AptelHitsScreen(heading: 'APTEL case status', rows: rows)));
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
      appBar: AppBar(title: const Text('APTEL case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Case Status', subtitle: 'aptel.gov.in  ·  DFR, case no., party or date', color: Color(0xFF5A4A1A), icon: Icons.search),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Case no.'), selected: _mode == 'case', onSelected: (_) => setState(() => _mode = 'case')),
              ChoiceChip(label: const Text('DFR no.'), selected: _mode == 'dfr', onSelected: (_) => setState(() => _mode = 'dfr')),
              ChoiceChip(label: const Text('Party'), selected: _mode == 'party', onSelected: (_) => setState(() => _mode = 'party')),
              ChoiceChip(label: const Text('Date'), selected: _mode == 'date', onSelected: (_) => setState(() => _mode = 'date')),
            ],
          ),
          const SizedBox(height: 12),
          if (_mode == 'case') _dd('Case type', _type, AptelClient.caseTypes, (v) => setState(() => _type = v)),
          if (_mode == 'case' || _mode == 'dfr') ...[
            TextField(controller: _no, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _mode == 'dfr' ? 'DFR number' : 'Case number')),
            const SizedBox(height: 12),
            TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          ],
          if (_mode == 'party') ...[
            _dd('Party type', _partyType, AptelClient.partyTypes, (v) => setState(() => _partyType = v)),
            TextField(controller: _party, decoration: const InputDecoration(labelText: 'Party name')),
            const SizedBox(height: 12),
            TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          ],
          if (_mode == 'date') ...[
            _dateTile('From', _from, (d) => setState(() => _from = d)),
            _dateTile('To', _to, (d) => setState(() => _to = d)),
          ],
          const SizedBox(height: 18),
          _searchBtn(_busy, _search),
          const SourceFooter(tribunal: 'APTEL', officialUrl: AptelClient.caseStatusUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AptelCauseListScreen extends StatefulWidget {
  const AptelCauseListScreen({super.key});

  @override
  State<AptelCauseListScreen> createState() => _AptelCauseListScreenState();
}

class _AptelCauseListScreenState extends State<AptelCauseListScreen> {
  String _mode = 'today';
  final _no = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  String _type = '1';
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  bool _busy = false;
  List<AptelHit> _rows = [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _no.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await AptelClient.instance.searchCauseList(
        mode: _mode,
        diaryNo: _no.text,
        caseNo: _no.text,
        year: _year.text,
        caseType: _type,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      setState(() => _rows = rows);
      if (rows.isEmpty) throw Exception('No APTEL cause list for this search.');
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
      appBar: AppBar(title: const Text('APTEL cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Cause list', subtitle: 'aptel.gov.in/causelist  ·  CIS PDF', color: Color(0xFF5A4A1A), icon: Icons.list_alt),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Today'), selected: _mode == 'today', onSelected: (_) => setState(() => _mode = 'today')),
              ChoiceChip(label: const Text('Date'), selected: _mode == 'date', onSelected: (_) => setState(() => _mode = 'date')),
              ChoiceChip(label: const Text('Case no.'), selected: _mode == 'case', onSelected: (_) => setState(() => _mode = 'case')),
              ChoiceChip(label: const Text('DFR'), selected: _mode == 'dfr', onSelected: (_) => setState(() => _mode = 'dfr')),
            ],
          ),
          if (_mode == 'date') ...[
            _dateTile('From', _from, (d) => setState(() => _from = d)),
            _dateTile('To', _to, (d) => setState(() => _to = d)),
          ],
          if (_mode == 'case') _dd('Case type', _type, AptelClient.caseTypes, (v) => setState(() => _type = v)),
          if (_mode == 'case' || _mode == 'dfr') ...[
            TextField(controller: _no, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _mode == 'dfr' ? 'DFR number' : 'Case number')),
            TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          ],
          _searchBtn(_busy, _search),
          const SizedBox(height: 12),
          for (final r in _rows) AptelHitTile(hit: r),
          const SourceFooter(tribunal: 'APTEL', officialUrl: AptelClient.causeListUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AptelOrdersSearchScreen extends StatefulWidget {
  final String title;
  final bool judgement;
  const AptelOrdersSearchScreen({super.key, required this.title, this.judgement = false});

  @override
  State<AptelOrdersSearchScreen> createState() => _AptelOrdersSearchScreenState();
}

class _AptelOrdersSearchScreenState extends State<AptelOrdersSearchScreen> {
  String _mode = 'date';
  final _no = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _party = TextEditingController();
  String _type = '1';
  String _partyType = '1';
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
      final rows = await AptelClient.instance.searchOrders(
        judgement: widget.judgement,
        mode: _mode,
        diaryNo: _no.text,
        caseNo: _no.text,
        year: _year.text,
        caseType: _type,
        partyName: _party.text,
        partyType: _partyType,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No APTEL ${widget.judgement ? 'judgement' : 'daily order'} found.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AptelHitsScreen(heading: widget.title, rows: rows)));
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
          CourtBand(title: widget.title, subtitle: widget.judgement ? 'aptel.gov.in/judgementorder' : 'aptel.gov.in/dailyorder', color: const Color(0xFF5A4A1A), icon: Icons.gavel),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Date'), selected: _mode == 'date', onSelected: (_) => setState(() => _mode = 'date')),
              ChoiceChip(label: const Text('Case no.'), selected: _mode == 'case', onSelected: (_) => setState(() => _mode = 'case')),
              ChoiceChip(label: const Text('DFR'), selected: _mode == 'dfr', onSelected: (_) => setState(() => _mode = 'dfr')),
              ChoiceChip(label: const Text('Party'), selected: _mode == 'party', onSelected: (_) => setState(() => _mode = 'party')),
            ],
          ),
          if (_mode == 'date') ...[
            _dateTile('From', _from, (d) => setState(() => _from = d)),
            _dateTile('To', _to, (d) => setState(() => _to = d)),
          ],
          if (_mode == 'case') _dd('Case type', _type, AptelClient.caseTypes, (v) => setState(() => _type = v)),
          if (_mode == 'case' || _mode == 'dfr') ...[
            TextField(controller: _no, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _mode == 'dfr' ? 'DFR number' : 'Case number')),
            TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          ],
          if (_mode == 'party') ...[
            _dd('Party type', _partyType, AptelClient.partyTypes, (v) => setState(() => _partyType = v)),
            TextField(controller: _party, decoration: const InputDecoration(labelText: 'Party name')),
            TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          ],
          _searchBtn(_busy, _search),
          SourceFooter(tribunal: 'APTEL', officialUrl: widget.judgement ? AptelClient.judgementUrl : AptelClient.dailyOrderUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AptelDisplayBoardScreen extends StatefulWidget {
  const AptelDisplayBoardScreen({super.key});

  @override
  State<AptelDisplayBoardScreen> createState() => _AptelDisplayBoardScreenState();
}

class _AptelDisplayBoardScreenState extends State<AptelDisplayBoardScreen> {
  int _court = 2;
  bool _busy = false;
  List<AptelHit> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final rows = await AptelClient.instance.displayBoard(_court);
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('APTEL display board')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Display board', subtitle: 'cis.aptel.gov.in court boards', color: Color(0xFF5A4A1A), icon: Icons.tv_outlined),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Court 1'), selected: _court == 1, onSelected: (_) { setState(() => _court = 1); _load(); }),
              ChoiceChip(label: const Text('Court 2'), selected: _court == 2, onSelected: (_) { setState(() => _court = 2); _load(); }),
            ],
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (!_busy && _rows.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No items listed on this court board right now.')),
          for (final r in _rows) AptelHitTile(hit: r),
          const SourceFooter(tribunal: 'APTEL', officialUrl: AptelClient.displayBoardUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AptelHitsScreen extends StatelessWidget {
  final String heading;
  final List<AptelHit> rows;
  const AptelHitsScreen({super.key, required this.heading, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(heading)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in rows) AptelHitTile(hit: r),
          const SourceFooter(tribunal: 'APTEL', officialUrl: AptelClient.home, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AptelHitTile extends StatelessWidget {
  final AptelHit hit;
  const AptelHitTile({super.key, required this.hit});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.paper,
      child: ListTile(
        title: Text(hit.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: hit.subtitle.isEmpty ? null : Text(hit.subtitle),
        trailing: Icon(hit.fileUrl != null ? Icons.picture_as_pdf_outlined : Icons.chevron_right),
        onTap: () => _openAptelHit(context, hit),
      ),
    );
  }
}

Future<void> _openAptelHit(BuildContext context, AptelHit hit) async {
  if (hit.detailUrl != null && hit.detailUrl!.isNotEmpty) {
    try {
      final file = await AptelClient.instance.caseDetails(hit.detailUrl!);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AptelRecordScreen(blocks: file.blocks, files: file.files, heading: 'APTEL case status', seedTitle: hit.title),
        ),
      );
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
  }
  if (hit.fileUrl != null) {
    await InAppDocumentScreen.open(context, hit.fileUrl!, title: hit.title, showOfficialLink: false);
  }
}

class AptelRecordScreen extends StatelessWidget {
  final List<AptelBlock> blocks;
  final List<AptelHit> files;
  final String heading;
  final String? seedTitle;
  const AptelRecordScreen({
    super.key,
    required this.blocks,
    this.files = const [],
    required this.heading,
    this.seedTitle,
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
        flat['DFR No/Year'] ??
        heading;
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(heading),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('APTEL', flat['DFR No/Year'] ?? title),
              tribunal: 'APTEL',
              filingNo: flat['DFR No/Year'] ?? '',
              caseNo: flat['Case Type/Case No/Year'] ?? title,
              title: title,
              nextHearing: flat['Next Listing Date'],
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'aptel_json',
              payload: jsonEncode({
                'heading': heading,
                'files': [
                  for (final o in files) {'title': o.title, 'subtitle': o.subtitle, 'fileUrl': o.fileUrl, 'fields': o.fields},
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
              sourceUrl: AptelClient.home,
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
              if ((flat['DFR No/Year'] ?? '').isNotEmpty) 'DFR ${flat['DFR No/Year']}',
              if ((flat['Case Status'] ?? '').isNotEmpty) flat['Case Status']!,
            ].join('  ·  '),
            color: const Color(0xFF5A4A1A),
            icon: Icons.bolt_outlined,
          ),
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
                    for (final f in b.fields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: '${f.key}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: f.value),
                        ])),
                      ),
                  ],
                ),
              ),
            ),
          if (files.isNotEmpty) const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('Orders', style: TextStyle(fontWeight: FontWeight.w800))),
          for (final f in files)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: const Icon(Icons.picture_as_pdf_outlined),
                onTap: f.fileUrl == null ? null : () => InAppDocumentScreen.open(context, f.fileUrl!, title: f.title, showOfficialLink: false),
              ),
            ),
          const SourceFooter(tribunal: 'APTEL', officialUrl: AptelClient.home, showOfficialLink: false),
        ],
      ),
    );
  }
}

List<AptelBlock> aptelBlocksFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map)
        AptelBlock(
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
        ),
  ];
}

List<AptelHit> aptelHitsFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map)
        AptelHit(
          title: '${item['title'] ?? ''}',
          subtitle: '${item['subtitle'] ?? ''}',
          fileUrl: item['fileUrl'] as String?,
          detailUrl: item['detailUrl'] as String?,
          fields: {
            if (item['fields'] is Map)
              for (final e in (item['fields'] as Map).entries) '${e.key}': '${e.value}',
          },
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
      subtitle: Text(AptelClient.instance.isoDate(value)),
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
