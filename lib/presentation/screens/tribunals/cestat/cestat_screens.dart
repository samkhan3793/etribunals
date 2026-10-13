import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/cestat_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class CestatCaseDetailsSearchScreen extends StatefulWidget {
  const CestatCaseDetailsSearchScreen({super.key});

  @override
  State<CestatCaseDetailsSearchScreen> createState() => _CestatCaseDetailsSearchScreenState();
}

class _CestatCaseDetailsSearchScreenState extends State<CestatCaseDetailsSearchScreen> {
  final _value = TextEditingController();
  String _bench = 'delhi';
  String _type = 'cno';
  String _caseType = '1';
  late String _year;
  bool _busy = false;
  final _years = List.generate(40, (i) => '${DateTime.now().year - i}');

  @override
  void initState() {
    super.initState();
    _year = _years.first;
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await CestatClient.instance.searchCaseStatus(
        bench: _bench,
        type: _type,
        value: _value.text,
        year: _year,
        caseType: _caseType,
      );
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No CESTAT case found for this search.');
      await _openRows(context, rows, 'CESTAT case details');
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
      appBar: AppBar(title: const Text('CESTAT case details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Case Details',
            subtitle: 'cestat.gov.in/casestatus  ·  diary, case no, party or O-I-A',
            color: Color(0xFF4A3A1A),
            icon: Icons.search,
          ),
          const SizedBox(height: 14),
          _dd('Bench', _bench, CestatClient.slugBenches, (v) => setState(() => _bench = v)),
          const SizedBox(height: 12),
          _dd('Search by', _type, CestatClient.searchTypes, (v) => setState(() => _type = v)),
          const SizedBox(height: 12),
          if (_type == 'cno') ...[
            _dd('Case type', _caseType, CestatClient.caseTypes, (v) => setState(() => _caseType = v)),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _value,
            decoration: InputDecoration(
              labelText: _type == 'pno'
                  ? 'Party name'
                  : _type == 'ino'
                      ? 'O-I-A / O-I-O number'
                      : _type == 'cno'
                          ? 'Case number'
                          : 'Diary number',
            ),
          ),
          if (_type == 'dno' || _type == 'cno') ...[
            const SizedBox(height: 12),
            _dd('Year', _year, _years.map((y) => MapEntry(y, y)).toList(), (v) => setState(() => _year = v)),
          ],
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
          const SourceFooter(tribunal: 'CESTAT', officialUrl: CestatClient.caseStatusUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class CestatDateSearchScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String officialUrl;
  final Future<List<CestatRow>> Function(String benchId, String date) search;

  const CestatDateSearchScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.officialUrl,
    required this.search,
  });

  @override
  State<CestatDateSearchScreen> createState() => _CestatDateSearchScreenState();
}

class _CestatDateSearchScreenState extends State<CestatDateSearchScreen> {
  String _bench = '107079';
  DateTime _date = DateTime.now();
  bool _busy = false;

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final rows = await widget.search(_bench, CestatClient.instance.dateLabel(_date));
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No CESTAT records found for this date.');
      await _openRows(context, rows, widget.title);
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
          CourtBand(title: widget.title, subtitle: widget.subtitle, color: const Color(0xFF4A3A1A), icon: Icons.list_alt),
          const SizedBox(height: 14),
          _dd('Bench', _bench, CestatClient.idBenches, (v) => setState(() => _bench = v)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(CestatClient.instance.dateLabel(_date)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final next = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2015), lastDate: DateTime.now().add(const Duration(days: 30)));
              if (next != null) setState(() => _date = next);
            },
          ),
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
          SourceFooter(tribunal: 'CESTAT', officialUrl: widget.officialUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class CestatOrdersSearchScreen extends StatefulWidget {
  final String title;
  final bool finalOrders;
  final bool allBenches;

  const CestatOrdersSearchScreen({
    super.key,
    required this.title,
    this.finalOrders = false,
    this.allBenches = false,
  });

  @override
  State<CestatOrdersSearchScreen> createState() => _CestatOrdersSearchScreenState();
}

class _CestatOrdersSearchScreenState extends State<CestatOrdersSearchScreen> {
  final _caseNo = TextEditingController();
  final _caseYear = TextEditingController();
  final _diaryNo = TextEditingController();
  final _diaryYear = TextEditingController();
  final _keyword = TextEditingController();
  String _bench = '107079';
  String _type = '1';
  String _member = '';
  String _mode = 'case';
  DateTime? _from;
  DateTime? _to;
  List<MapEntry<String, String>> _members = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.allBenches) _mode = 'keyword';
    CestatClient.instance.members().then((v) {
      if (mounted) setState(() => _members = v);
    });
  }

  @override
  void dispose() {
    _caseNo.dispose();
    _caseYear.dispose();
    _diaryNo.dispose();
    _diaryYear.dispose();
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      late final List<CestatRow> rows;
      if (widget.allBenches) {
        final date = _from == null ? '' : CestatClient.instance.dateLabel(_from!);
        final to = _to == null ? '' : CestatClient.instance.dateLabel(_to!);
        final fields = <String, String>{
          'description': _mode == 'keyword' ? _keyword.text.trim() : '',
          'member_name': _mode == 'member' ? _member : '',
          'from_date': _mode == 'member' ? date : '',
          'to_date': _mode == 'member' ? to : '',
          'from_date_l': _mode == 'dates' ? date : '',
          'to_date_l': _mode == 'dates' ? to : '',
          'from_date_th': '',
          'to_date_th': '',
        };
        if (_mode == 'keyword' && fields['description']!.isEmpty) {
          throw Exception('Enter a keyword from the order, for example a party or subject word.');
        }
        if (_mode != 'keyword' && date.isEmpty) {
          throw Exception('Pick a from date for this search.');
        }
        rows = await CestatClient.instance.searchFinalAll(fields);
      } else {
        final fields = <String, String>{
          'bench': _bench,
          'case_type': _type,
          'member_name': _member,
          'case_no': _mode == 'case' ? _caseNo.text.trim() : '',
          'case_year': _mode == 'case' ? _caseYear.text.trim() : '',
          'diary_no': _mode == 'diary' ? _diaryNo.text.trim() : '',
          'diary_year': _mode == 'diary' ? _diaryYear.text.trim() : '',
          'from_date': _mode == 'dates' && _from != null ? CestatClient.instance.dateLabel(_from!) : '',
          'to_date': _mode == 'dates' && _to != null ? CestatClient.instance.dateLabel(_to!) : '',
        };
        if (_mode == 'case' && (fields['case_no']!.isEmpty || fields['case_year']!.isEmpty)) {
          throw Exception('Enter case number and year.');
        }
        if (_mode == 'diary' && (fields['diary_no']!.isEmpty || fields['diary_year']!.isEmpty)) {
          throw Exception('Enter diary number and year.');
        }
        if (_mode == 'dates' && (_from == null || _to == null)) {
          throw Exception('Pick from and to dates.');
        }
        rows = widget.finalOrders
            ? await CestatClient.instance.searchFinalOrders(fields)
            : await CestatClient.instance.searchDailyOrders(fields);
      }
      if (!mounted) return;
      if (rows.isEmpty) throw Exception('No CESTAT orders found.');
      await _openRows(context, rows, widget.title);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = widget.allBenches
        ? const [MapEntry('keyword', 'Keyword'), MapEntry('dates', 'Larger bench dates'), MapEntry('member', 'Member')]
        : const [MapEntry('case', 'Case no.'), MapEntry('diary', 'Diary no.'), MapEntry('dates', 'Order dates')];
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: widget.title,
            subtitle: widget.allBenches
                ? 'Search all benches by keyword, date or member'
                : 'Search with one method — case, diary or dates',
            color: const Color(0xFF4A3A1A),
            icon: Icons.gavel,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final m in modes)
                ChoiceChip(
                  label: Text(m.value),
                  selected: _mode == m.key,
                  onSelected: (_) => setState(() => _mode = m.key),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!widget.allBenches) ...[
            _dd('Bench', _bench, CestatClient.idBenches, (v) => setState(() => _bench = v)),
            const SizedBox(height: 12),
            if (_mode == 'case') ...[
              _dd('Case type', _type, CestatClient.caseTypes, (v) => setState(() => _type = v)),
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
          ],
          if (widget.allBenches && _mode == 'keyword')
            TextField(controller: _keyword, maxLines: 3, decoration: const InputDecoration(labelText: 'Keyword / brief description')),
          if (!widget.allBenches && _members.isNotEmpty && _mode != 'dates')
            _dd('Member (optional)', _member, [const MapEntry('', 'Any'), ..._members], (v) => setState(() => _member = v)),
          if (widget.allBenches && _mode == 'member' && _members.isNotEmpty)
            _dd('Member', _member, _members, (v) => setState(() => _member = v)),
          if (_mode == 'dates' || (widget.allBenches && _mode == 'member')) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('From date'),
              subtitle: Text(_from == null ? 'Required' : CestatClient.instance.dateLabel(_from!)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final next = await showDatePicker(context: context, initialDate: _from ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                if (next != null) setState(() => _from = next);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('To date'),
              subtitle: Text(_to == null ? 'Required' : CestatClient.instance.dateLabel(_to!)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final next = await showDatePicker(context: context, initialDate: _to ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
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
                  : const Text('Search orders'),
            ),
          ),
          const SourceFooter(tribunal: 'CESTAT', officialUrl: CestatClient.site, showOfficialLink: false),
        ],
      ),
    );
  }
}

class CestatDisplayBoardScreen extends StatefulWidget {
  const CestatDisplayBoardScreen({super.key});

  @override
  State<CestatDisplayBoardScreen> createState() => _CestatDisplayBoardScreenState();
}

class _CestatDisplayBoardScreenState extends State<CestatDisplayBoardScreen> {
  String _bench = '107079';
  List<CestatRow> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await CestatClient.instance.displayBoard(_bench);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
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
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('CESTAT display board'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Display board',
            subtitle: 'cestat.gov.in/displayboard  ·  live court items',
            color: Color(0xFF4A3A1A),
            icon: Icons.tv_rounded,
          ),
          const SizedBox(height: 12),
          _dd('Bench', _bench, CestatClient.idBenches, (v) {
            setState(() => _bench = v);
            _load();
          }),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.stampRed))
          else if (_rows.isEmpty)
            const Text('No items on this display board right now.')
          else
            ..._rows.map(
              (r) => Card(
                color: AppColors.paper,
                child: ListTile(
                  title: Text(r.fields['Subject'] ?? r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    [
                      if ((r.fields['Court No.'] ?? r.fields['Court No'] ?? '').isNotEmpty) 'Court ${r.fields['Court No.'] ?? r.fields['Court No']}',
                      if ((r.fields['Item No.'] ?? r.fields['Item No'] ?? '').isNotEmpty) 'Item ${r.fields['Item No.'] ?? r.fields['Item No']}',
                      if ((r.fields['Remark'] ?? '').isNotEmpty) r.fields['Remark']!,
                    ].join(' · '),
                  ),
                ),
              ),
            ),
          const SourceFooter(tribunal: 'CESTAT', officialUrl: CestatClient.displayUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class CestatDashboardScreen extends StatelessWidget {
  const CestatDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InAppDocumentScreen(url: CestatClient.dashboardUrl, title: 'CESTAT dashboard', showOfficialLink: false);
  }
}

class CestatRecordScreen extends StatelessWidget {
  final CestatRow row;
  final String heading;
  const CestatRecordScreen({super.key, required this.row, required this.heading});

  @override
  Widget build(BuildContext context) {
    final fields = Map<String, String>.from(row.fields)..remove('PDF')..remove('DETAIL');
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(heading),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('CESTAT', row.title),
              tribunal: 'CESTAT',
              filingNo: row.title,
              caseNo: row.fields['Case No'] ?? row.fields['Diary No'] ?? '',
              title: row.title,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'cestat_json',
              payload: jsonEncode({'fields': row.fields, 'heading': heading}),
              sourceUrl: CestatClient.site,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(title: row.title, subtitle: heading, color: const Color(0xFF4A3A1A), icon: Icons.folder_open),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x3314384A))),
            child: Column(
              children: [
                for (final e in fields.entries)
                  if (e.value.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 120, child: Text(e.key, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5))),
                          Expanded(child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          if (row.pdf != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => InAppDocumentScreen.open(context, row.pdf!, title: 'CESTAT document', showOfficialLink: false),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Open document'),
            ),
          ],
          if (row.isCaseStatusPage) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CestatFullRecordScreen(url: row.detail!, seed: row))),
              icon: const Icon(Icons.folder_open),
              label: const Text('Open full record'),
            ),
          ] else if (row.detail != null && row.detail != row.pdf) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => InAppDocumentScreen.open(context, row.detail!, title: 'CESTAT details', showOfficialLink: false),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Open full record'),
            ),
          ],
          const SourceFooter(tribunal: 'CESTAT', officialUrl: CestatClient.site, showOfficialLink: false),
        ],
      ),
    );
  }
}

Future<void> _openRows(BuildContext context, List<CestatRow> rows, String heading) async {
  Future<void> openOne(CestatRow r) {
    if (r.isCaseStatusPage) {
      return Navigator.push(context, MaterialPageRoute(builder: (_) => CestatFullRecordScreen(url: r.detail!, seed: r)));
    }
    return Navigator.push(context, MaterialPageRoute(builder: (_) => CestatRecordScreen(row: r, heading: heading)));
  }

  if (rows.length == 1) {
    await openOne(rows.first);
    return;
  }
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
                subtitle: Text(r.fields.entries.where((e) => e.key != 'PDF' && e.key != 'DETAIL' && e.value != r.title).take(3).map((e) => '${e.key}: ${e.value}').join('\n')),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openOne(r),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class CestatFullRecordScreen extends StatefulWidget {
  final String url;
  final CestatRow? seed;
  const CestatFullRecordScreen({super.key, required this.url, this.seed});

  @override
  State<CestatFullRecordScreen> createState() => _CestatFullRecordScreenState();
}

class _CestatFullRecordScreenState extends State<CestatFullRecordScreen> {
  List<CestatDetailBlock> _blocks = [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final blocks = await CestatClient.instance.fetchCaseDetail(widget.url);
      if (!mounted) return;
      setState(() {
        _blocks = blocks;
        _loading = false;
        if (blocks.isEmpty) _error = 'This case record did not return details.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  Map<String, String> get _flat {
    final out = <String, String>{};
    final seed = widget.seed?.fields ?? {};
    out.addAll(seed);
    for (final b in _blocks) {
      for (final f in b.fields) {
        if (f.value.trim().isNotEmpty) out[f.key] = f.value;
      }
    }
    out['DETAIL'] = widget.url;
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final flat = _flat;
    final title = flat['Petitioner Name']?.isNotEmpty == true
        ? '${flat['Petitioner Name']} vs ${flat['Respondent Name'] ?? ''}'.trim()
        : widget.seed?.title ?? 'CESTAT case';
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('CESTAT case details'),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('CESTAT', flat['Diary no/Year'] ?? title),
              tribunal: 'CESTAT',
              filingNo: flat['Diary no/Year'] ?? '',
              caseNo: flat['Case Type/Case No/Year'] ?? '',
              title: title,
              nextHearing: (flat['Next Hearing Date'] ?? '').trim().isEmpty ? null : flat['Next Hearing Date'],
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'cestat_json',
              payload: jsonEncode({'fields': flat, 'heading': 'CESTAT case details', 'detailUrl': widget.url}),
              sourceUrl: widget.url,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CourtBand(
                  title: title,
                  subtitle: [
                    if ((flat['Diary no/Year'] ?? '').isNotEmpty) 'Diary ${flat['Diary no/Year']}',
                    if ((flat['Case Type/Case No/Year'] ?? '').isNotEmpty) flat['Case Type/Case No/Year']!,
                    if ((flat['Case Status'] ?? '').isNotEmpty) flat['Case Status']!,
                  ].join('  ·  '),
                  color: const Color(0xFF4A3A1A),
                  icon: Icons.folder_open,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_error!, style: const TextStyle(color: AppColors.stampRed)),
                  ),
                for (final block in _blocks) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x3314384A)),
                    ),
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
                const SourceFooter(tribunal: 'CESTAT', officialUrl: CestatClient.caseStatusUrl, showOfficialLink: false),
              ],
            ),
    );
  }
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
