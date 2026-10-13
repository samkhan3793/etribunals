import 'dart:convert';
import 'dart:typed_data';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/aft_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class AFTScreen extends StatelessWidget {
  AFTScreen({super.key});

  final options = [
    {'title': 'Case status', 'route': '/aft/case-status', 'icon': Icons.search},
    {'title': 'Cause list', 'route': '/aft/cause-list', 'icon': Icons.list_alt},
    {'title': 'Daily orders', 'route': '/aft/orders', 'icon': Icons.description_outlined},
    {'title': 'Judgements', 'route': '/aft/judgements', 'icon': Icons.gavel},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('AFT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: FeatureGrid(
        heading: 'Case Management Services',
        subtitle: 'Official aft.gov.in  ·  Principal Bench, New Delhi  ·  case status, cause list, daily orders, judgements',
        items: options,
      ),
    );
  }
}

class AftCaseStatusScreen extends StatefulWidget {
  const AftCaseStatusScreen({super.key});

  @override
  State<AftCaseStatusScreen> createState() => _AftCaseStatusScreenState();
}

class _AftCaseStatusScreenState extends State<AftCaseStatusScreen> {
  String _mode = 'case';
  String _type = '1';
  final _no = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _party = TextEditingController();
  final _captcha = TextEditingController();
  Uint8List? _captchaImg;
  bool _busy = false;

  String get _page => _mode == 'diary'
      ? AftClient.diaryUrl
      : _mode == 'party'
          ? AftClient.partyUrl
          : AftClient.caseNumberUrl;

  @override
  void initState() {
    super.initState();
    _reloadCaptcha();
  }

  @override
  void dispose() {
    _no.dispose();
    _year.dispose();
    _party.dispose();
    _captcha.dispose();
    super.dispose();
  }

  Future<void> _reloadCaptcha() async {
    try {
      final img = await AftClient.instance.loadCaptcha(_page);
      if (!mounted) return;
      setState(() {
        _captchaImg = img;
        _captcha.clear();
      });
    } catch (_) {}
  }

  Future<void> _search() async {
    if (_captcha.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the captcha from the official AFT image.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final path = _mode == 'diary'
          ? '/casestatus/diarynumber/search'
          : _mode == 'party'
              ? '/casestatus/partyname/search'
              : '/casestatus/casenumber/search';
      final fields = _mode == 'diary'
          ? {'diary_no': _no.text.trim(), 'case_year': _year.text.trim()}
          : _mode == 'party'
              ? {'party_name': _party.text.trim(), 'case_year': _year.text.trim()}
              : {'case_type': _type, 'case_number': _no.text.trim(), 'case_year': _year.text.trim()};
      final rows = await AftClient.instance.search(pageUrl: _page, searchPath: path, fields: fields, captcha: _captcha.text);
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No AFT case found for this search.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AftHitsScreen(heading: 'AFT case status', rows: rows)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
      await _reloadCaptcha();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('AFT case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Case Status', subtitle: 'aft.gov.in  ·  case no., diary no. or party  ·  official captcha', color: Color(0xFF1F3D32), icon: Icons.search),
          const SizedBox(height: 14),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Case no.'), selected: _mode == 'case', onSelected: (_) { setState(() => _mode = 'case'); _reloadCaptcha(); }),
            ChoiceChip(label: const Text('Diary no.'), selected: _mode == 'diary', onSelected: (_) { setState(() => _mode = 'diary'); _reloadCaptcha(); }),
            ChoiceChip(label: const Text('Party'), selected: _mode == 'party', onSelected: (_) { setState(() => _mode = 'party'); _reloadCaptcha(); }),
          ]),
          const SizedBox(height: 12),
          if (_mode == 'case') _dd('Case type', _type, AftClient.caseTypes, (v) => setState(() => _type = v)),
          if (_mode == 'party') TextField(controller: _party, decoration: const InputDecoration(labelText: 'Party name')),
          if (_mode != 'party') TextField(controller: _no, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _mode == 'diary' ? 'Diary number' : 'Case number')),
          const SizedBox(height: 12),
          TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
          const SizedBox(height: 12),
          _captchaRow(_captchaImg, _captcha, _reloadCaptcha),
          _searchBtn(_busy, _search),
          const SourceFooter(tribunal: 'AFT', officialUrl: AftClient.caseNumberUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AftDateSearchScreen extends StatefulWidget {
  final String title;
  final String pageUrl;
  final String searchPath;
  const AftDateSearchScreen({super.key, required this.title, required this.pageUrl, required this.searchPath});

  @override
  State<AftDateSearchScreen> createState() => _AftDateSearchScreenState();
}

class _AftDateSearchScreenState extends State<AftDateSearchScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  final _captcha = TextEditingController();
  Uint8List? _captchaImg;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _captcha.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final img = await AftClient.instance.loadCaptcha(widget.pageUrl);
      if (!mounted) return;
      setState(() {
        _captchaImg = img;
        _captcha.clear();
      });
    } catch (_) {}
  }

  Future<void> _search() async {
    if (_captcha.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the captcha from the official AFT image.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final rows = await AftClient.instance.search(
        pageUrl: widget.pageUrl,
        searchPath: widget.searchPath,
        fields: {'start_date': AftClient.instance.iso(_from), 'end_date': AftClient.instance.iso(_to)},
        captcha: _captcha.text,
      );
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No AFT records for these dates.');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AftHitsScreen(heading: widget.title, rows: rows)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
      await _reload();
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
          CourtBand(title: widget.title, subtitle: 'aft.gov.in  ·  date-wise official listing  ·  captcha', color: const Color(0xFF1F3D32), icon: Icons.gavel),
          const SizedBox(height: 14),
          _dateTile('From', _from, (d) => setState(() => _from = d)),
          _dateTile('To', _to, (d) => setState(() => _to = d)),
          _captchaRow(_captchaImg, _captcha, _reload),
          _searchBtn(_busy, _search),
          SourceFooter(tribunal: 'AFT', officialUrl: widget.pageUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AftCauseListScreen extends StatefulWidget {
  const AftCauseListScreen({super.key});

  @override
  State<AftCauseListScreen> createState() => _AftCauseListScreenState();
}

class _AftCauseListScreenState extends State<AftCauseListScreen> {
  DateTime _date = DateTime.now();
  List<AftCourt> _courts = const [AftCourt('3', 'Court 1'), AftCourt('4', 'Court 2'), AftCourt('5', 'Court 3'), AftCourt('9', 'PR Court 4')];
  String _court = '3';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    try {
      final courts = await AftClient.instance.courts(_date);
      if (!mounted || courts.isEmpty) return;
      setState(() {
        _courts = courts;
        if (!_courts.any((c) => c.id == _court)) _court = _courts.first.id;
      });
    } catch (_) {}
  }

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      final url = AftClient.instance.causeListPdf(_date, _court);
      if (!mounted) return;
      await InAppDocumentScreen.open(context, url, title: 'AFT cause list', showOfficialLink: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('AFT cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(title: 'Daily cause list', subtitle: 'aft.gov.in  ·  court-wise PDF for the selected date', color: Color(0xFF1F3D32), icon: Icons.list_alt),
          const SizedBox(height: 14),
          _dateTile('Cause list date', _date, (d) { setState(() => _date = d); _loadCourts(); }),
          _dd('Court', _court, [for (final c in _courts) MapEntry(c.id, c.name)], (v) => setState(() => _court = v)),
          _searchBtn(_busy, _open, label: 'Open cause list'),
          const SourceFooter(tribunal: 'AFT', officialUrl: AftClient.causeListUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AftHitsScreen extends StatelessWidget {
  final String heading;
  final List<AftHit> rows;
  const AftHitsScreen({super.key, required this.heading, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(heading)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: heading, subtitle: '${rows.length} official record${rows.length == 1 ? '' : 's'}', color: const Color(0xFF1F3D32), icon: Icons.folder_open),
          const SizedBox(height: 12),
          for (final r in rows) AftHitTile(hit: r),
          const SourceFooter(tribunal: 'AFT', officialUrl: AftClient.host, showOfficialLink: false),
        ],
      ),
    );
  }
}

class AftHitTile extends StatelessWidget {
  final AftHit hit;
  const AftHitTile({super.key, required this.hit});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.paper,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1F3D32),
          child: Text(
            hit.title.trim().isEmpty ? 'A' : hit.title.trim()[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(_aftDisplayTitle(hit.title), style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: hit.subtitle.isEmpty ? null : Text(_aftDisplayTitle(hit.subtitle)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openAftHit(context, hit),
      ),
    );
  }
}

Future<void> _openAftHit(BuildContext context, AftHit hit) async {
  try {
    final dossier = AftClient.instance.dossierFor(hit);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AftRecordScreen(dossier: dossier, heading: 'AFT case record'),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    }
  }
}

Future<void> _openAftPdf(BuildContext context, String url, String title) async {
  try {
    final bytes = await AftClient.instance.fetchBytes(url);
    if (!context.mounted) return;
    await InAppDocumentScreen.open(context, AftClient.rewriteDocUrl(url), title: title, showOfficialLink: false, pdfBytes: bytes);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    }
  }
}

class AftRecordScreen extends StatelessWidget {
  final AftDossier? dossier;
  final List<AftBlock> blocks;
  final String heading;
  final String? seedTitle;
  const AftRecordScreen({super.key, this.dossier, this.blocks = const [], required this.heading, this.seedTitle});

  Map<String, String> get _fields {
    if (dossier != null) return dossier!.fields;
    final out = <String, String>{};
    for (final b in blocks) {
      for (final f in b.fields) {
        if (f.value.trim().isNotEmpty) out[f.key] = f.value;
      }
    }
    return out;
  }

  List<AftHit> get _docs => dossier?.documents ?? const [];

  @override
  Widget build(BuildContext context) {
    final fields = _fields;
    final title = seedTitle ?? dossier?.title ?? heading;
    final subtitle = dossier?.subtitle ?? fields.values.take(2).join('  ·  ');
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(heading),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('AFT', title),
              tribunal: 'AFT',
              filingNo: title,
              caseNo: title,
              title: title,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'aft_json',
              payload: jsonEncode({
                'heading': heading,
                'title': title,
                'subtitle': subtitle,
                'fields': fields,
                'documents': [
                  for (final d in _docs) {'title': d.title, 'fileUrl': d.fileUrl},
                ],
                'blocks': [
                  for (final b in blocks)
                    {
                      'title': b.title,
                      'fields': [for (final f in b.fields) {'k': f.key, 'v': f.value}],
                      'headers': b.headers,
                      'rows': b.rows,
                      'links': [for (final l in b.links) l],
                    },
                ],
              }),
              sourceUrl: AftClient.host,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x3314384A)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFF1F3D32),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ARMED FORCES TRIBUNAL', style: TextStyle(color: Color(0xFFC4A265), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12.5, height: 1.35)),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    children: [
                      for (final e in fields.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 110, child: Text(e.key, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700))),
                              Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_docs.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.fromLTRB(2, 16, 2, 8), child: Text('Orders / judgements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            for (final doc in _docs)
              Card(
                color: AppColors.paper,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF1F3D32)),
                  title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Official AFT PDF'),
                  trailing: TextButton(
                    onPressed: () => _openAftPdf(context, doc.fileUrl ?? '', doc.title),
                    child: const Text('View'),
                  ),
                ),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 16, 2, 8),
              child: Text('No order/judgement PDF was linked on this official row.'),
            ),
          const SourceFooter(tribunal: 'AFT', officialUrl: AftClient.host, showOfficialLink: false),
        ],
      ),
    );
  }
}

String _aftDisplayTitle(String text) {
  if (text.contains('upload_document') || text.startsWith('http')) return 'AFT record';
  return text;
}

List<AftBlock> aftBlocksFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map)
        AftBlock(
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
          links: [
            for (final l in (item['links'] as List? ?? const []))
              l == null || '$l' == 'null' ? null : '$l',
          ],
        ),
  ];
}

Widget _captchaRow(Uint8List? img, TextEditingController controller, VoidCallback refresh) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (img != null)
        Image.memory(img, width: 140, height: 48, fit: BoxFit.contain)
      else
        const SizedBox(width: 140, height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)),
      Expanded(child: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Captcha'))),
    ],
  );
}

Widget _dd(String label, String value, List<MapEntry<String, String>> items, ValueChanged<String> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: items.any((e) => e.key == value) ? value : (items.isNotEmpty ? items.first.key : null),
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
      subtitle: Text(AftClient.instance.iso(value)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final next = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2008), lastDate: DateTime.now().add(const Duration(days: 14)));
        if (next != null) onChanged(next);
      },
    ),
  );
}

Widget _searchBtn(bool busy, VoidCallback onPressed, {String label = 'Search'}) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    ),
  );
}
