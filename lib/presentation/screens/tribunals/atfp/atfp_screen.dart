import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/atfp_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _atfpInk = Color(0xFF3A2A4A);

class ATFPScreen extends StatelessWidget {
  ATFPScreen({super.key});

  final options = [
    {'title': 'Cause list', 'route': '/atfp/cause-list', 'icon': Icons.list_alt},
    {'title': 'Orders', 'route': '/atfp/orders', 'icon': Icons.description_outlined},
    {'title': 'Judgements', 'route': '/atfp/judgements', 'icon': Icons.gavel},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('ATFP', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Case Management Services',
        subtitle: 'Official atfp.gov.in  ·  Appellate Tribunal under SAFEMA / PMLA / FEMA  ·  cause list, orders, judgements',
        items: options,
      ),
    );
  }
}

class AtfpCauseListScreen extends StatefulWidget {
  const AtfpCauseListScreen({super.key});

  @override
  State<AtfpCauseListScreen> createState() => _AtfpCauseListScreenState();
}

class _AtfpCauseListScreenState extends State<AtfpCauseListScreen> {
  int _page = 1;
  bool _busy = true;
  String? _error;
  List<AtfpHit> _rows = [];

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
      final rows = await AtfpClient.instance.causeList(page: _page);
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
      appBar: AppBar(title: const Text('ATFP cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Cause list', subtitle: 'atfp.gov.in/cause-list.asp  ·  court-wise PDFs', color: _atfpInk, icon: Icons.list_alt),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
          for (final r in _rows)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: r.fileUrl == null ? null : TextButton(onPressed: () => openAtfpDoc(context, r), child: const Text('View')),
                onTap: r.fileUrl == null ? null : () => openAtfpDoc(context, r),
              ),
            ),
          Row(
            children: [
              TextButton(
                onPressed: _busy || _page <= 1
                    ? null
                    : () {
                        setState(() => _page -= 1);
                        _load();
                      },
                child: const Text('Previous'),
              ),
              Text('Page $_page'),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() => _page += 1);
                        _load();
                      },
                child: const Text('Next'),
              ),
            ],
          ),
          const SourceFooter(tribunal: 'ATFP', officialUrl: AtfpClient.causeListUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AtfpSearchScreen extends StatefulWidget {
  final String title;
  final bool judgements;
  const AtfpSearchScreen({super.key, required this.title, this.judgements = false});

  @override
  State<AtfpSearchScreen> createState() => _AtfpSearchScreenState();
}

class _AtfpSearchScreenState extends State<AtfpSearchScreen> {
  String _mode = 'party';
  String _act = AtfpClient.actTypes.first.key;
  final _q = TextEditingController();
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = widget.judgements
          ? await AtfpClient.instance.searchJudgements(mode: _mode, query: _q.text, act: _act, date: _date)
          : await AtfpClient.instance.searchOrders(mode: _mode, query: _q.text, act: _act, date: _date);
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No ATFP records for this search.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AtfpHitsScreen(heading: widget.title, rows: rows)));
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
          CourtBand(
            title: widget.title,
            subtitle: widget.judgements ? 'atfp.gov.in/judgements.asp' : 'atfp.gov.in/orders.asp',
            color: _atfpInk,
            icon: Icons.gavel,
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'party', label: Text('Party / case')),
              ButtonSegment(value: 'date', label: Text('Date')),
              ButtonSegment(value: 'act', label: Text('Act + case')),
            ],
            selected: {_mode},
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          const SizedBox(height: 12),
          if (_mode != 'date') TextField(controller: _q, decoration: const InputDecoration(labelText: 'Party name / case no.')),
          if (_mode == 'act')
            DropdownButtonFormField<String>(
              initialValue: _act,
              items: [for (final e in AtfpClient.actTypes) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _act = v ?? _act),
              decoration: const InputDecoration(labelText: 'Act / appeal type'),
            ),
          if (_mode != 'act')
            ListTile(
              title: Text(_mode == 'date' ? 'Order date' : 'Month / year'),
              subtitle: Text(_mode == 'date' ? DateFormat('dd-MM-yyyy').format(_date) : DateFormat('MMMM yyyy').format(_date)),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2012), lastDate: DateTime.now());
                if (picked != null) setState(() => _date = picked);
              },
            ),
          FilledButton(onPressed: _busy ? null : _search, child: Text(_busy ? 'Searching…' : 'Search')),
          SourceFooter(tribunal: 'ATFP', officialUrl: widget.judgements ? AtfpClient.judgementsUrl : AtfpClient.ordersUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AtfpHitsScreen extends StatelessWidget {
  final String heading;
  final List<AtfpHit> rows;
  const AtfpHitsScreen({super.key, required this.heading, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(heading)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: heading, subtitle: '${rows.length} record(s)', color: _atfpInk, icon: Icons.folder_open),
          for (final r in rows)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(r.subtitle),
                isThreeLine: r.subtitle.length > 40,
                trailing: r.fileUrl == null ? null : TextButton(onPressed: () => openAtfpDoc(context, r), child: const Text('View')),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AtfpRecordScreen(hit: r, heading: heading))),
              ),
            ),
          const SourceFooter(tribunal: 'ATFP', officialUrl: AtfpClient.host, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AtfpRecordScreen extends StatelessWidget {
  final AtfpHit hit;
  final String heading;
  const AtfpRecordScreen({super.key, required this.hit, required this.heading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(heading),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('ATFP', hit.title),
              tribunal: 'ATFP',
              filingNo: hit.title,
              caseNo: hit.title,
              title: hit.subtitle.isEmpty ? hit.title : hit.subtitle,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'atfp_json',
              payload: jsonEncode({
                'heading': heading,
                'title': hit.title,
                'subtitle': hit.subtitle,
                'fileUrl': hit.fileUrl,
                'fields': hit.fields,
              }),
              sourceUrl: hit.fileUrl ?? AtfpClient.host,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: hit.title, subtitle: hit.subtitle, color: _atfpInk, icon: Icons.policy_rounded),
          Card(
            color: AppColors.paper,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in hit.fields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: e.value),
                      ])),
                    ),
                ],
              ),
            ),
          ),
          if (hit.fileUrl != null)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: const Text('Official PDF', style: TextStyle(fontWeight: FontWeight.w800)),
                trailing: TextButton(onPressed: () => openAtfpDoc(context, hit), child: const Text('View')),
              ),
            ),
          const SourceFooter(tribunal: 'ATFP', officialUrl: AtfpClient.host, showOfficialLink: false),
        ],
      ),
    );
  }
}

Future<void> openAtfpDoc(BuildContext context, AtfpHit hit) {
  final url = hit.fileUrl;
  if (url == null || url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No ATFP PDF for this row.')));
    return Future.value();
  }
  return InAppDocumentScreen.open(context, url, title: hit.title, showOfficialLink: false);
}

AtfpHit atfpHitFromJson(Map map) {
  final fields = <String, String>{};
  final raw = map['fields'];
  if (raw is Map) {
    for (final e in raw.entries) {
      fields['${e.key}'] = '${e.value}';
    }
  }
  return AtfpHit(
    title: '${map['title'] ?? ''}',
    subtitle: '${map['subtitle'] ?? ''}',
    fileUrl: map['fileUrl'] == null ? null : '${map['fileUrl']}',
    fields: fields,
  );
}
