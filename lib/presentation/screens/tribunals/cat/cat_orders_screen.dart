import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/cat_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:flutter/material.dart';

class CatOrdersScreen extends StatefulWidget {
  final bool oralFinal;

  const CatOrdersScreen({super.key, this.oralFinal = false});

  @override
  State<CatOrdersScreen> createState() => _CatOrdersScreenState();
}

class _CatOrdersScreenState extends State<CatOrdersScreen> {
  final _diary = TextEditingController();
  final _caseNo = TextEditingController();
  final _party = TextEditingController();
  String? _schemaId;
  String _by = 'date';
  String _typeId = '1';
  String _partyType = '3';
  String? _member;
  late String _year;
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _searching = false;
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _members = [];

  final _years = List.generate(40, (i) => '${DateTime.now().year - i}');

  @override
  void initState() {
    super.initState();
    _year = _years.first;
    _schemaId = CatSession.instance.bench?.id ?? '100';
    if (widget.oralFinal) _loadMembers();
  }

  @override
  void dispose() {
    _diary.dispose();
    _caseNo.dispose();
    _party.dispose();
    super.dispose();
  }

  CatBench get _bench {
    final id = _schemaId ?? '100';
    return CatClient.benches.firstWhere((e) => e.id == id, orElse: () => CatClient.benches.first);
  }

  Future<void> _loadMembers() async {
    final id = _schemaId;
    if (id == null) return;
    try {
      final rows = CatClient.instance.asRows(
        await CatClient.instance.post('MemberName', {'catschemaId': id}),
        empty: 'No members listed.',
      );
      if (!mounted) return;
      setState(() {
        _members = rows;
        _member = _memberId(rows.first);
      });
    } catch (_) {}
  }

  String _memberId(Map<String, dynamic> row) {
    return '${row['JudgeCode'] ?? row['judgeCode'] ?? row['memberCode'] ?? row['id'] ?? ''}'.trim();
  }

  String _memberLabel(Map<String, dynamic> row) {
    return '${row['memberName'] ?? row['JudgeName'] ?? row['name'] ?? row['MemberName'] ?? _memberId(row)}'.trim();
  }

  Future<void> _pick(bool from) async {
    final initial = from ? _from : _to;
    final next = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1985), lastDate: DateTime.now());
    if (next == null) return;
    setState(() {
      if (from) {
        _from = next;
      } else {
        _to = next;
      }
    });
  }

  Future<void> _search() async {
    final id = _schemaId;
    if (id == null) return;
    CatSession.instance.bench = _bench;
    setState(() => _searching = true);
    try {
      final oral = widget.oralFinal;
      late String path;
      late Map<String, dynamic> body;
      if (_by == 'date') {
        path = oral ? 'getCatFinalOrderReportDatewise' : 'getCatDailyOrderReportDatewise';
        body = {
          'catschemaId': id,
          'fromDate': CatClient.instance.listingDate(_from),
          'toDate': CatClient.instance.listingDate(_to),
        };
      } else if (_by == 'diary') {
        path = oral ? 'getCatFinalOrderReportDiaryNo' : 'getCatDailyOrderReportDiaryNo';
        body = {'catschemaId': id, 'diaryNo': _diary.text.trim(), 'diaryYear': _year};
      } else if (_by == 'case') {
        path = oral ? 'getCatFinalOrderReportCaseNo' : 'getCatDailyOrderReportCaseNo';
        body = {'caseType': _typeId, 'catschemaId': id, 'caseNo': _caseNo.text.trim(), 'caseYear': _year};
      } else if (_by == 'member') {
        path = 'getCatFinalOrderReportMemberwise';
        body = {'catschemaId': id, 'JudgeCode': _member ?? ''};
      } else {
        path = 'getCatDailyOrderReportPartywise';
        body = {'catschemaId': id, 'partyType': _partyType, 'partyName': _party.text.trim()};
      }
      final rows = CatClient.instance.asRows(await CatClient.instance.post(path, body), empty: 'No orders found.');
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _rows = []);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oral = widget.oralFinal;
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(oral ? 'CAT oral and final orders' : 'CAT daily orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: _bench.name,
            subtitle: oral ? 'Oral and final orders from cgat.gov.in' : 'Daily orders from cgat.gov.in',
            color: const Color(0xFF3D4A6B),
            icon: Icons.gavel,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _schemaId,
            decoration: const InputDecoration(labelText: 'Bench'),
            items: CatClient.benches.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
            onChanged: (v) {
              setState(() => _schemaId = v);
              if (oral) _loadMembers();
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _byChip('date', 'Date'),
              _byChip('diary', 'Diary no.'),
              _byChip('case', 'Case no.'),
              if (!oral) _byChip('party', 'Party'),
              if (oral) _byChip('member', 'Member'),
            ],
          ),
          const SizedBox(height: 12),
          if (_by == 'date') ...[
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('From'), subtitle: Text(CatClient.instance.listingDate(_from)), onTap: () => _pick(true)),
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('To'), subtitle: Text(CatClient.instance.listingDate(_to)), onTap: () => _pick(false)),
          ] else if (_by == 'diary') ...[
            TextField(controller: _diary, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diary number')),
            const SizedBox(height: 12),
            _yearField(),
          ] else if (_by == 'case') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _typeId,
              decoration: const InputDecoration(labelText: 'Case type'),
              items: CatClient.caseTypes.map((t) => DropdownMenuItem(value: t.key, child: Text(t.value))).toList(),
              onChanged: (v) => setState(() => _typeId = v ?? _typeId),
            ),
            const SizedBox(height: 12),
            TextField(controller: _caseNo, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Case number')),
            const SizedBox(height: 12),
            _yearField(),
          ] else if (_by == 'member') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _members.any((e) => _memberId(e) == _member) ? _member : null,
              decoration: const InputDecoration(labelText: 'Member'),
              items: _members.map((e) => DropdownMenuItem(value: _memberId(e), child: Text(_memberLabel(e), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _member = v),
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _partyType,
              decoration: const InputDecoration(labelText: 'Party'),
              items: CatClient.partyTypes.map((t) => DropdownMenuItem(value: t.key, child: Text(t.value))).toList(),
              onChanged: (v) => setState(() => _partyType = v ?? _partyType),
            ),
            const SizedBox(height: 12),
            TextField(controller: _party, decoration: const InputDecoration(labelText: 'Party name')),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _searching ? null : _search,
              child: _searching
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search orders'),
            ),
          ),
          const SizedBox(height: 12),
          ..._rows.map((row) {
            final url = CatClient.documentUrl(row);
            final no = '${row['applicantno'] ?? row['caseno'] ?? row['diaryno'] ?? 'Order'}';
            final parties = '${row['applicantName'] ?? row['applicant'] ?? ''} vs ${row['respondentName'] ?? row['respondent'] ?? ''}'.trim();
            return Card(
              color: AppColors.paper,
              child: ListTile(
                title: Text(no, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  [
                    if (parties != 'vs') parties,
                    '${row['dateoforder'] ?? row['upload_date'] ?? ''}',
                  ].where((e) => e.toString().isNotEmpty).join('\n'),
                ),
                isThreeLine: parties != 'vs',
                trailing: url == null ? null : const Icon(Icons.picture_as_pdf_outlined),
                onTap: url == null ? null : () => InAppDocumentScreen.open(context, url, title: no),
              ),
            );
          }),
          const SourceFooter(tribunal: 'CAT', officialUrl: CatClient.site),
        ],
      ),
    );
  }

  Widget _yearField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _year,
      decoration: const InputDecoration(labelText: 'Year'),
      items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
      onChanged: (v) => setState(() => _year = v ?? _year),
    );
  }

  Widget _byChip(String id, String label) {
    return ChoiceChip(label: Text(label), selected: _by == id, onSelected: (_) => setState(() => _by = id));
  }
}
