import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/drt_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:flutter/material.dart';

class DrtOrdersScreen extends StatefulWidget {
  const DrtOrdersScreen({super.key});

  @override
  State<DrtOrdersScreen> createState() => _DrtOrdersScreenState();
}

class _DrtOrdersScreenState extends State<DrtOrdersScreen> {
  final _diary = TextEditingController();
  final _caseNo = TextEditingController();
  final _ia = TextEditingController();
  final _rc = TextEditingController();
  List<DrtLocation> _all = [];
  List<DrtCaseType> _types = [];
  String _family = 'daily';
  String _by = 'diary';
  String? _schemeId;
  String? _typeId;
  String _orderType = '1';
  late String _year;
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _loading = true;
  bool _searching = false;
  List<Map<String, dynamic>> _rows = [];
  String? _error;

  final _years = List.generate(20, (i) => '${DateTime.now().year - i}');

  @override
  void initState() {
    super.initState();
    _year = _years.first;
    _boot();
  }

  @override
  void dispose() {
    _diary.dispose();
    _caseNo.dispose();
    _ia.dispose();
    _rc.dispose();
    super.dispose();
  }

  List<DrtLocation> get _locs {
    if (_family == 'drat') return _all.where((e) => e.isDrat).toList();
    return _all.where((e) => !e.isDrat).toList();
  }

  Future<void> _boot() async {
    try {
      final all = await DrtClient.instance.locations();
      final first = all.firstWhere((e) => !e.isDrat, orElse: () => all.first);
      if (!mounted) return;
      setState(() {
        _all = all;
        _schemeId = first.id;
        _loading = false;
      });
      await _typesFor(first.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  Future<void> _typesFor(String id) async {
    final types = await DrtClient.instance.caseTypes(id);
    if (!mounted) return;
    setState(() {
      _types = types;
      _typeId = types.isEmpty ? null : types.first.id;
    });
  }

  Future<void> _search() async {
    final id = _schemeId;
    if (id == null) return;
    setState(() => _searching = true);
    try {
      late final String path;
      final body = <String, dynamic>{'schemeNameDrtId': id};
      if (_family == 'daily' && _by == 'diary') {
        path = 'getDrtDailyOrderReportDiaryNo';
        body.addAll({'diaryNo': _diary.text.trim(), 'diaryYear': _year});
      } else if (_family == 'daily' && _by == 'case') {
        path = 'getDrtDailyOrderReportCaseNo';
        body.addAll({'caseType': _typeId, 'caseNo': _caseNo.text.trim(), 'caseYear': _year});
      } else if (_family == 'daily' && _by == 'ia') {
        path = 'getDrtDailyOrderReportIaOrder';
        body.addAll({'iaNo': _ia.text.trim(), 'iaYear': _year});
      } else if (_family == 'final' && _by == 'diary') {
        path = 'getDrtFinalOrderReportDiaryNo';
        body.addAll({'diaryNo': _diary.text.trim(), 'diaryYear': _year});
      } else if (_family == 'final') {
        path = 'getDrtFinalOrderReportCaseNo';
        body.addAll({'caseType': _typeId, 'caseNo': _caseNo.text.trim(), 'caseYear': _year});
      } else if (_family == 'drat' && _by == 'diary') {
        path = 'getDratOrderJudgementReportDiaryNo';
        body.addAll({'diaryNo': _diary.text.trim(), 'diaryYear': _year, 'dratDailyFinalOrderId': _orderType});
      } else if (_family == 'drat' && _by == 'case') {
        path = 'getDratOrderJudgementReportCaseNo';
        body.addAll({'caseType': _typeId, 'caseNo': _caseNo.text.trim(), 'caseYear': _year, 'dratDailyFinalOrderId': _orderType});
      } else if (_family == 'drat') {
        path = 'getDratOrderJudgementReportFromToDate';
        body.addAll({
          'dratDailyFinalOrderId': _orderType,
          'fromDate': DrtClient.instance.listingDate(_from),
          'toDate': DrtClient.instance.listingDate(_to),
        });
      } else {
        path = 'getRcTrcDailyFinalOrderRcNo';
        body.addAll({
          'dailyFinalOrderId': _orderType,
          'caseType': _typeId,
          'dailyFinalRcNo': _rc.text.trim(),
          'dailyFinalRcYear': _year,
        });
      }
      final rows = await DrtClient.instance.report(path, body);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _searching = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rows = [];
        _searching = false;
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  String? _pdf(Map row) {
    for (final e in row.values) {
      final v = e?.toString() ?? '';
      if (v.startsWith('http') && (v.toLowerCase().contains('pdf') || v.contains('order'))) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locs = _locs;
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('DRT orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Orders / judgements',
            subtitle: 'Daily, final, DRAT and RC/TRC reports from drt.gov.in',
            color: Color(0xFF1A4A6B),
            icon: Icons.gavel,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Daily'), selected: _family == 'daily', onSelected: (_) => setState(() { _family = 'daily'; _by = 'diary'; })),
              ChoiceChip(label: const Text('Final'), selected: _family == 'final', onSelected: (_) => setState(() { _family = 'final'; _by = 'diary'; })),
              ChoiceChip(label: const Text('DRAT'), selected: _family == 'drat', onSelected: (_) {
                setState(() {
                  _family = 'drat';
                  _by = 'diary';
                  _schemeId = _locs.isEmpty ? null : _locs.first.id;
                });
                if (_schemeId != null) _typesFor(_schemeId!);
              }),
              ChoiceChip(label: const Text('RC / TRC'), selected: _family == 'rc', onSelected: (_) {
                setState(() {
                  _family = 'rc';
                  _by = 'rc';
                  _schemeId = _all.where((e) => !e.isDrat).isEmpty ? null : _all.firstWhere((e) => !e.isDrat).id;
                });
              }),
            ],
          ),
          const SizedBox(height: 10),
          if (_family == 'daily')
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('Diary'), selected: _by == 'diary', onSelected: (_) => setState(() => _by = 'diary')),
              ChoiceChip(label: const Text('Case no.'), selected: _by == 'case', onSelected: (_) => setState(() => _by = 'case')),
              ChoiceChip(label: const Text('IA'), selected: _by == 'ia', onSelected: (_) => setState(() => _by = 'ia')),
            ]),
          if (_family == 'final')
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('Diary'), selected: _by == 'diary', onSelected: (_) => setState(() => _by = 'diary')),
              ChoiceChip(label: const Text('Case no.'), selected: _by == 'case', onSelected: (_) => setState(() => _by = 'case')),
            ]),
          if (_family == 'drat')
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('Diary'), selected: _by == 'diary', onSelected: (_) => setState(() => _by = 'diary')),
              ChoiceChip(label: const Text('Case no.'), selected: _by == 'case', onSelected: (_) => setState(() => _by = 'case')),
              ChoiceChip(label: const Text('Date range'), selected: _by == 'dates', onSelected: (_) => setState(() => _by = 'dates')),
            ]),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: locs.any((e) => e.id == _schemeId) ? _schemeId : null,
              decoration: const InputDecoration(labelText: 'Tribunal'),
              items: locs.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (id) {
                setState(() => _schemeId = id);
                if (id != null) _typesFor(id);
              },
            ),
            const SizedBox(height: 12),
            if (_family == 'drat' || _family == 'rc')
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _orderType,
                decoration: const InputDecoration(labelText: 'Order type'),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('Daily order')),
                  DropdownMenuItem(value: '2', child: Text('Final order')),
                ],
                onChanged: (v) => setState(() => _orderType = v ?? '1'),
              ),
            if (_by == 'diary') ...[
              const SizedBox(height: 12),
              TextField(controller: _diary, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diary number')),
            ],
            if (_by == 'case' || _family == 'rc') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _types.any((t) => t.id == _typeId) ? _typeId : null,
                decoration: const InputDecoration(labelText: 'Case type'),
                items: _types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _typeId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _family == 'rc' ? _rc : _caseNo,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _family == 'rc' ? 'RC / TRC number' : 'Case number'),
              ),
            ],
            if (_by == 'ia') ...[
              const SizedBox(height: 12),
              TextField(controller: _ia, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'IA number')),
            ],
            if (_by != 'dates') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _year,
                decoration: const InputDecoration(labelText: 'Year'),
                items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (v) => setState(() => _year = v ?? _year),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _from, firstDate: DateTime(2018), lastDate: DateTime.now());
                    if (d != null) setState(() => _from = d);
                  }, child: Text('From ${_from.day}/${_from.month}/${_from.year}'))),
                  Expanded(child: TextButton(onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _to, firstDate: DateTime(2018), lastDate: DateTime.now());
                    if (d != null) setState(() => _to = d);
                  }, child: Text('To ${_to.day}/${_to.month}/${_to.year}'))),
                ],
              ),
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
          ],
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: AppColors.stampRed))),
          const SizedBox(height: 12),
          ..._rows.map((row) {
            final pdf = _pdf(row);
            final title = '${row['caseno'] ?? row['diaryno'] ?? row['orderdate'] ?? row['causelistdate'] ?? 'Order'}';
            return Card(
              color: AppColors.paper,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('$title', maxLines: 2),
                subtitle: Text('${row['petitionerName'] ?? row['partyName'] ?? ''}'),
                trailing: pdf == null ? null : const Icon(Icons.picture_as_pdf_outlined),
                onTap: pdf == null ? null : () => InAppDocumentScreen.open(context, pdf, title: 'Order'),
              ),
            );
          }),
          const SourceFooter(tribunal: 'DRT', officialUrl: 'https://drt.gov.in/#/order'),
        ],
      ),
    );
  }
}
