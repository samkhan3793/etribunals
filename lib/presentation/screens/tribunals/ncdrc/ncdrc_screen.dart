import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/ncdrc_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _ncdrcInk = Color(0xFF4A2A3A);

Future<void> openNcdrcDoc(BuildContext context, NcdrcHit hit, {int orderTypeId = 2}) async {
  try {
    if (hit.hasJudgement) {
      await InAppDocumentScreen.open(
        context,
        NcdrcClient.searchUrl,
        title: hit.caseNumber,
        showOfficialLink: false,
        htmlBody: hit.judgementHtml,
      );
      return;
    }
    final hearing = hit.hearingDate.isNotEmpty ? hit.hearingDate : hit.orderDate;
    if (hit.filingRef.isEmpty || hearing.isEmpty) {
      throw Exception('No NCDRC order file for this row.');
    }
    final bytes = await NcdrcClient.instance.orderPdf(
      filingRef: hit.filingRef,
      hearingDate: hearing,
      orderTypeId: orderTypeId,
    );
    if (!context.mounted) return;
    await InAppDocumentScreen.open(
      context,
      NcdrcClient.searchUrl,
      title: hit.caseNumber,
      showOfficialLink: false,
      pdfBytes: bytes,
    );
  } catch (e) {
    final msg = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (msg.startsWith('html:')) {
      await InAppDocumentScreen.open(
        context,
        NcdrcClient.searchUrl,
        title: hit.caseNumber,
        showOfficialLink: false,
        htmlBody: msg.substring(5),
      );
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class NCDRCScreen extends StatelessWidget {
  NCDRCScreen({super.key});

  final options = [
    {'title': 'Case status', 'route': '/ncdrc/case-status', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/ncdrc/cause-list', 'icon': Icons.list_alt},
    {'title': 'Daily orders', 'route': '/ncdrc/orders', 'icon': Icons.description_outlined},
    {'title': 'Judgements', 'route': '/ncdrc/judgements', 'icon': Icons.gavel},
    {'title': 'Display board', 'route': '/ncdrc/display-board', 'icon': Icons.tv_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('NCDRC', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Case Management Services',
        subtitle: 'Official e-jagriti.gov.in  ·  National Commission, New Delhi  ·  case status, cause list, orders, judgements',
        items: options,
      ),
    );
  }
}

class NcdrcCaseStatusScreen extends StatefulWidget {
  const NcdrcCaseStatusScreen({super.key});

  @override
  State<NcdrcCaseStatusScreen> createState() => _NcdrcCaseStatusScreenState();
}

class _NcdrcCaseStatusScreenState extends State<NcdrcCaseStatusScreen> {
  String _mode = 'case';
  final _no = TextEditingController();
  final _party = TextEditingController();
  DateTime _from = DateTime(DateTime.now().year, 1, 1);
  DateTime _to = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _no.dispose();
    _party.dispose();
    super.dispose();
  }

  Future<void> _pick(bool from) async {
    final start = from ? _from : _to;
    final picked = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2005), lastDate: DateTime.now());
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = _mode == 'case'
          ? await NcdrcClient.instance.searchByCaseNumber(_no.text)
          : await NcdrcClient.instance.searchByParty(_party.text, _from, _to);
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No NCDRC case found for this search.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => NcdrcHitsScreen(heading: 'NCDRC case status', rows: rows)));
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
      appBar: AppBar(title: const Text('NCDRC case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Case Status',
            subtitle: 'e-jagriti.gov.in  ·  case number (NC/CC/1/2024) or party',
            color: _ncdrcInk,
            icon: Icons.search,
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'case', label: Text('Case no.')),
              ButtonSegment(value: 'party', label: Text('Party')),
            ],
            selected: {_mode},
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          const SizedBox(height: 12),
          if (_mode == 'case')
            TextField(controller: _no, decoration: const InputDecoration(labelText: 'Case number', hintText: 'NC/AE/16/2024'))
          else ...[
            TextField(controller: _party, decoration: const InputDecoration(labelText: 'Party name')),
            ListTile(title: const Text('From'), subtitle: Text(DateFormat('dd-MM-yyyy').format(_from)), onTap: () => _pick(true)),
            ListTile(title: const Text('To'), subtitle: Text(DateFormat('dd-MM-yyyy').format(_to)), onTap: () => _pick(false)),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _search, child: Text(_busy ? 'Searching…' : 'Search')),
          const SourceFooter(tribunal: 'NCDRC', officialUrl: NcdrcClient.searchUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class NcdrcDateSearchScreen extends StatefulWidget {
  final String title;
  final bool judgementsOnly;
  final bool ordersOnly;
  const NcdrcDateSearchScreen({super.key, required this.title, this.judgementsOnly = false, this.ordersOnly = false});

  @override
  State<NcdrcDateSearchScreen> createState() => _NcdrcDateSearchScreenState();
}

class _NcdrcDateSearchScreenState extends State<NcdrcDateSearchScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _busy = false;

  Future<void> _pick(bool from) async {
    final start = from ? _from : _to;
    final picked = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2005), lastDate: DateTime.now());
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await NcdrcClient.instance.searchByDate(
        _from,
        _to,
        orderType: widget.ordersOnly ? NcdrcClient.orderDaily : NcdrcClient.orderJudgement,
      );
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No NCDRC records for these hearing dates.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => NcdrcHitsScreen(heading: widget.title, rows: rows, orderTypeId: widget.ordersOnly ? 1 : 2)));
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
          CourtBand(title: widget.title, subtitle: 'e-jagriti.gov.in  ·  hearing / order date on National Commission', color: _ncdrcInk, icon: Icons.gavel),
          ListTile(title: const Text('From'), subtitle: Text(DateFormat('dd-MM-yyyy').format(_from)), onTap: () => _pick(true)),
          ListTile(title: const Text('To'), subtitle: Text(DateFormat('dd-MM-yyyy').format(_to)), onTap: () => _pick(false)),
          FilledButton(onPressed: _busy ? null : _search, child: Text(_busy ? 'Searching…' : 'Search')),
          const SourceFooter(tribunal: 'NCDRC', officialUrl: NcdrcClient.searchUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class NcdrcCauseListScreen extends StatefulWidget {
  const NcdrcCauseListScreen({super.key});

  @override
  State<NcdrcCauseListScreen> createState() => _NcdrcCauseListScreenState();
}

class _NcdrcCauseListScreenState extends State<NcdrcCauseListScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _busy = false;
  List<NcdrcHit> _rows = [];

  Future<void> _pick(bool from) async {
    final start = from ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2005),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final rows = await NcdrcClient.instance.causeList(_from, _to);
      if (!mounted) return;
      setState(() => _rows = rows);
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No NCDRC listing for these hearing dates.')));
      }
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
      appBar: AppBar(title: const Text('NCDRC cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Cause list', subtitle: 'e-jagriti.gov.in  ·  National Commission hearings by date', color: _ncdrcInk, icon: Icons.list_alt),
          ListTile(title: const Text('From'), subtitle: Text(DateFormat('dd-MM-yyyy').format(_from)), onTap: () => _pick(true)),
          ListTile(title: const Text('To'), subtitle: Text(DateFormat('dd-MM-yyyy').format(_to)), onTap: () => _pick(false)),
          FilledButton(onPressed: _busy ? null : _load, child: Text(_busy ? 'Loading…' : 'Load listing')),
          const SizedBox(height: 12),
          for (final r in _rows)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(r.caseNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${r.parties}\n${[if (r.hearingDate.isNotEmpty) 'Hearing ${r.hearingDate}', r.stage].where((e) => e.isNotEmpty).join('  ·  ')}'),
                isThreeLine: true,
                trailing: TextButton(onPressed: () => openNcdrcDoc(context, r), child: const Text('View')),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NcdrcRecordScreen(hit: r))),
              ),
            ),
          const SourceFooter(tribunal: 'NCDRC', officialUrl: NcdrcClient.causeListUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class NcdrcDisplayBoardScreen extends StatefulWidget {
  const NcdrcDisplayBoardScreen({super.key});

  @override
  State<NcdrcDisplayBoardScreen> createState() => _NcdrcDisplayBoardScreenState();
}

class _NcdrcDisplayBoardScreenState extends State<NcdrcDisplayBoardScreen> {
  bool _busy = true;
  String? _error;
  List<NcdrcBoardRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await NcdrcClient.instance.displayBoard();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('NCDRC display board'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Display board', subtitle: 'e-jagriti.gov.in  ·  National Commission benches', color: _ncdrcInk, icon: Icons.tv_rounded),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          for (final r in _rows)
            Card(
              color: AppColors.paper,
              child: ListTile(title: Text('Bench ${r.bench}'), subtitle: Text('Item ${r.item}')),
            ),
          if (!_busy && _rows.isEmpty && _error == null) const Text('No display-board items right now.'),
          const SourceFooter(tribunal: 'NCDRC', officialUrl: NcdrcClient.host, showOfficialLink: false),
        ],
      ),
    );
  }
}

class NcdrcHitsScreen extends StatelessWidget {
  final String heading;
  final List<NcdrcHit> rows;
  final int orderTypeId;
  const NcdrcHitsScreen({super.key, required this.heading, required this.rows, this.orderTypeId = 2});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(heading)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: heading, subtitle: '${rows.length} record(s)', color: _ncdrcInk, icon: Icons.folder_open),
          for (final r in rows)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(r.caseNumber.isEmpty ? r.parties : r.caseNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text([r.parties, r.subtitle].where((e) => e.trim().isNotEmpty).join('\n')),
                isThreeLine: true,
                trailing: TextButton(onPressed: () => openNcdrcDoc(context, r, orderTypeId: orderTypeId), child: const Text('View')),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NcdrcRecordScreen(hit: r, orderTypeId: orderTypeId))),
              ),
            ),
          const SourceFooter(tribunal: 'NCDRC', officialUrl: NcdrcClient.searchUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class NcdrcRecordScreen extends StatefulWidget {
  final NcdrcHit hit;
  final int orderTypeId;
  const NcdrcRecordScreen({super.key, required this.hit, this.orderTypeId = 2});

  @override
  State<NcdrcRecordScreen> createState() => _NcdrcRecordScreenState();
}

class _NcdrcRecordScreenState extends State<NcdrcRecordScreen> {
  Map<String, dynamic>? _status;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await NcdrcClient.instance.caseStatus(widget.hit.caseNumber);
      if (!mounted) return;
      setState(() => _status = status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusError = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''));
    }
  }

  Map<String, String> get _statusFields {
    final s = _status;
    if (s == null) return const {};
    String v(String k) => '${s[k] ?? ''}'.trim();
    final apps = s['applicationsFiled'];
    final extra = <String, String>{
      'Filed in': v('filedInComissionName'),
      'Stage': v('caseStage'),
      'Filing reference': v('fillingReferenceNumber'),
      'Filing date': v('caseFilingDate'),
      'Complainant': v('complainant'),
      'Respondent': v('respondent'),
      if (apps is List && apps.isNotEmpty) 'Applications': apps.join(', '),
    }..removeWhere((_, val) => val.isEmpty);
    return extra;
  }

  @override
  Widget build(BuildContext context) {
    final hit = widget.hit;
    final fields = {...hit.fields, ..._statusFields};
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('NCDRC record'),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('NCDRC', hit.caseNumber),
              tribunal: 'NCDRC',
              filingNo: hit.filingRef.isEmpty ? hit.caseNumber : hit.filingRef,
              caseNo: hit.caseNumber,
              title: hit.parties,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'ncdrc_json',
              payload: jsonEncode({
                'caseNumber': hit.caseNumber,
                'complainant': hit.complainant,
                'respondent': hit.respondent,
                'stage': hit.stage,
                'filingDate': hit.filingDate,
                'orderDate': hit.orderDate,
                'disposalDate': hit.disposalDate,
                'hearingDate': hit.hearingDate,
                'judgementDate': hit.judgementDate,
                'filingRef': hit.filingRef,
                'judgementHtml': hit.judgementHtml,
                'dailyOrder': hit.dailyOrder,
                'fields': hit.fields,
              }),
              sourceUrl: NcdrcClient.searchUrl,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: hit.caseNumber, subtitle: hit.parties, color: _ncdrcInk, icon: Icons.groups_rounded),
          Card(
            color: AppColors.paper,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Case details', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final e in fields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: e.value),
                      ])),
                    ),
                  if (_status == null && _statusError == null) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Loading official status…')),
                  if (_statusError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_statusError!)),
                ],
              ),
            ),
          ),
          Card(
            color: AppColors.paper,
            child: ListTile(
              title: const Text('Order / judgement', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                hit.judgementDate.isNotEmpty
                    ? 'Dated ${hit.judgementDate}'
                    : (hit.orderDate.isNotEmpty ? 'Dated ${hit.orderDate}' : 'Official e-Jagriti file'),
              ),
              trailing: TextButton(
                onPressed: () => openNcdrcDoc(context, hit, orderTypeId: widget.orderTypeId),
                child: const Text('View'),
              ),
            ),
          ),
          const SourceFooter(tribunal: 'NCDRC', officialUrl: NcdrcClient.searchUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

NcdrcHit ncdrcHitFromJson(Map map) {
  final fields = <String, String>{};
  final raw = map['fields'];
  if (raw is Map) {
    for (final e in raw.entries) {
      fields['${e.key}'] = '${e.value}';
    }
  }
  return NcdrcHit(
    caseNumber: '${map['caseNumber'] ?? ''}',
    complainant: '${map['complainant'] ?? ''}',
    respondent: '${map['respondent'] ?? ''}',
    stage: '${map['stage'] ?? ''}',
    filingDate: '${map['filingDate'] ?? ''}',
    orderDate: '${map['orderDate'] ?? ''}',
    disposalDate: '${map['disposalDate'] ?? ''}',
    hearingDate: '${map['hearingDate'] ?? ''}',
    judgementDate: '${map['judgementDate'] ?? ''}',
    filingRef: '${map['filingRef'] ?? ''}',
    judgementHtml: map['judgementHtml'] == null ? null : '${map['judgementHtml']}',
    dailyOrder: map['dailyOrder'] == true,
    fields: fields,
  );
}
