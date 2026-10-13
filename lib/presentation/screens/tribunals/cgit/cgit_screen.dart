import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/cgit_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _cgitInk = Color(0xFF3A3A2A);

class CGITScreen extends StatelessWidget {
  CGITScreen({super.key});

  final options = [
    {'title': 'Cause list', 'route': '/cgit/cause-list', 'icon': Icons.list_alt},
    {'title': 'Awards / orders', 'route': '/cgit/awards', 'icon': Icons.gavel},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('CGIT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Case Management Services',
        subtitle: 'Official apps.labour.gov.in/cgit  ·  cause list by bench / case / party, awards and orders',
        items: options,
      ),
    );
  }
}

class CgitCauseListScreen extends StatefulWidget {
  const CgitCauseListScreen({super.key});

  @override
  State<CgitCauseListScreen> createState() => _CgitCauseListScreenState();
}

class _CgitCauseListScreenState extends State<CgitCauseListScreen> {
  final _caseNo = TextEditingController();
  final _appellant = TextEditingController();
  final _respondent = TextEditingController();
  String _bench = 'All';
  String _type = 'All';
  DateTime? _date;
  int _page = 0;
  bool _busy = true;
  String? _error;
  List<CgitHit> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _caseNo.dispose();
    _appellant.dispose();
    _respondent.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await CgitClient.instance.causeList(
        date: _date,
        caseNo: _caseNo.text,
        caseType: _type,
        appellant: _appellant.text,
        respondent: _respondent.text,
        bench: _bench,
        page: _page,
      );
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
      appBar: AppBar(title: const Text('CGIT cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Cause list', subtitle: 'apps.labour.gov.in/cgit/cause-list  ·  benches across India', color: _cgitInk, icon: Icons.list_alt),
          TextField(controller: _caseNo, decoration: const InputDecoration(labelText: 'Case no.')),
          TextField(controller: _appellant, decoration: const InputDecoration(labelText: 'Appellant')),
          TextField(controller: _respondent, decoration: const InputDecoration(labelText: 'Respondent')),
          DropdownButtonFormField<String>(
            initialValue: _bench,
            items: [for (final e in CgitClient.benches) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _bench = v ?? _bench),
            decoration: const InputDecoration(labelText: 'Bench'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: [for (final e in CgitClient.caseTypes) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _type = v ?? _type),
            decoration: const InputDecoration(labelText: 'Case type'),
          ),
          ListTile(
            title: const Text('Hearing date'),
            subtitle: Text(_date == null ? 'Any' : DateFormat('dd-MM-yyyy').format(_date!)),
            trailing: _date == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _date = null),
                  ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2015),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    _page = 0;
                    _load();
                  },
            child: Text(_busy ? 'Loading…' : 'Search'),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!)),
          const SizedBox(height: 8),
          for (final r in _rows)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text([r.parties, r.subtitle].where((e) => e.trim().isNotEmpty).join('\n')),
                isThreeLine: true,
                trailing: r.fileUrls.isEmpty ? const Icon(Icons.chevron_right) : TextButton(onPressed: () => openCgitFiles(context, r), child: const Text('View')),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CgitRecordScreen(hit: r, heading: 'CGIT cause list'))),
              ),
            ),
          Row(
            children: [
              TextButton(
                onPressed: _busy || _page <= 0
                    ? null
                    : () {
                        setState(() => _page -= 1);
                        _load();
                      },
                child: const Text('Previous'),
              ),
              Text('Page ${_page + 1}'),
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
          const SourceFooter(tribunal: 'CGIT', officialUrl: CgitClient.causeListUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class CgitAwardsScreen extends StatefulWidget {
  const CgitAwardsScreen({super.key});

  @override
  State<CgitAwardsScreen> createState() => _CgitAwardsScreenState();
}

class _CgitAwardsScreenState extends State<CgitAwardsScreen> {
  final _q = TextEditingController();
  int _page = 0;
  bool _busy = true;
  String? _error;
  List<CgitHit> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await CgitClient.instance.awards(query: _q.text, page: _page);
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
      appBar: AppBar(title: const Text('CGIT awards / orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Awards / orders', subtitle: 'apps.labour.gov.in/cgit/awards-and-judgements-orders', color: _cgitInk, icon: Icons.gavel),
          TextField(controller: _q, decoration: const InputDecoration(labelText: 'Search (bench / subject)')),
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    _page = 0;
                    _load();
                  },
            child: Text(_busy ? 'Loading…' : 'Search'),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!)),
          for (final r in _rows)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(r.subject, style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: r.fileUrls.isEmpty ? const Icon(Icons.chevron_right) : TextButton(onPressed: () => openCgitFiles(context, r), child: const Text('View')),
                onTap: () => openCgitFiles(context, r),
              ),
            ),
          Row(
            children: [
              TextButton(
                onPressed: _busy || _page <= 0
                    ? null
                    : () {
                        setState(() => _page -= 1);
                        _load();
                      },
                child: const Text('Previous'),
              ),
              Text('Page ${_page + 1}'),
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
          const SourceFooter(tribunal: 'CGIT', officialUrl: CgitClient.awardsUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class CgitRecordScreen extends StatelessWidget {
  final CgitHit hit;
  final String heading;
  const CgitRecordScreen({super.key, required this.hit, required this.heading});

  @override
  Widget build(BuildContext context) {
    final fields = <String, String>{
      if (hit.caseNo.isNotEmpty) 'Case no.': hit.caseNo,
      if (hit.subject.isNotEmpty) 'Subject': hit.subject,
      if (hit.caseType.isNotEmpty) 'Type': hit.caseType,
      if (hit.appellant.isNotEmpty) 'Appellant': hit.appellant,
      if (hit.respondent.isNotEmpty) 'Respondent': hit.respondent,
      if (hit.nextDate.isNotEmpty) 'Next date': hit.nextDate,
      if (hit.details.isNotEmpty) 'Details': hit.details,
    };
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(heading),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('CGIT', hit.title),
              tribunal: 'CGIT',
              filingNo: hit.title,
              caseNo: hit.caseNo,
              title: hit.parties.isEmpty ? hit.subject : hit.parties,
              nextHearing: hit.nextDate,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'cgit_json',
              payload: jsonEncode({
                'heading': heading,
                'caseNo': hit.caseNo,
                'subject': hit.subject,
                'caseType': hit.caseType,
                'appellant': hit.appellant,
                'respondent': hit.respondent,
                'nextDate': hit.nextDate,
                'details': hit.details,
                'fileUrls': hit.fileUrls,
              }),
              sourceUrl: CgitClient.causeListUrl,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: hit.title, subtitle: hit.subtitle, color: _cgitInk, icon: Icons.factory_rounded),
          Card(
            color: AppColors.paper,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in fields.entries)
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
          for (var i = 0; i < hit.fileUrls.length; i++)
            Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(hit.fileUrls.length == 1 ? 'Official PDF' : 'Official PDF ${i + 1}'),
                trailing: TextButton(
                  onPressed: () async {
                    try {
                      final bytes = await CgitClient.instance.downloadPdf(hit.fileUrls[i]);
                      if (!context.mounted) return;
                      await InAppDocumentScreen.open(
                        context,
                        hit.fileUrls[i],
                        title: hit.title,
                        showOfficialLink: false,
                        pdfBytes: bytes,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))),
                      );
                    }
                  },
                  child: const Text('View'),
                ),
              ),
            ),
          const SourceFooter(tribunal: 'CGIT', officialUrl: CgitClient.host, showOfficialLink: false),
        ],
      ),
    );
  }
}

Future<void> openCgitFiles(BuildContext context, CgitHit hit) async {
  if (hit.fileUrls.isEmpty) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CgitRecordScreen(hit: hit, heading: 'CGIT record')));
    return;
  }
  if (hit.fileUrls.length > 1) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CgitRecordScreen(hit: hit, heading: 'CGIT record')));
    return;
  }
  try {
    final bytes = await CgitClient.instance.downloadPdf(hit.fileUrls.first);
    if (!context.mounted) return;
    await InAppDocumentScreen.open(
      context,
      hit.fileUrls.first,
      title: hit.title,
      showOfficialLink: false,
      pdfBytes: bytes,
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))),
    );
  }
}

CgitHit cgitHitFromJson(Map map) {
  return CgitHit(
    caseNo: '${map['caseNo'] ?? ''}',
    subject: '${map['subject'] ?? ''}',
    caseType: '${map['caseType'] ?? ''}',
    appellant: '${map['appellant'] ?? ''}',
    respondent: '${map['respondent'] ?? ''}',
    nextDate: '${map['nextDate'] ?? ''}',
    details: '${map['details'] ?? ''}',
    fileUrls: [for (final u in (map['fileUrls'] as List? ?? const [])) '$u'],
  );
}
