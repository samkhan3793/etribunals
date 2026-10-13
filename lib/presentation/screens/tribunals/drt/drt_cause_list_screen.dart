import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/drt_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DrtCauseListScreen extends StatefulWidget {
  const DrtCauseListScreen({super.key});

  @override
  State<DrtCauseListScreen> createState() => _DrtCauseListScreenState();
}

class _DrtCauseListScreenState extends State<DrtCauseListScreen> {
  List<DrtLocation> _all = [];
  List<Map<String, dynamic>> _names = [];
  List<Map<String, dynamic>> _nos = [];
  String _kind = 'drt';
  String? _schemeId;
  String? _courtNameId;
  String? _courtNo;
  DateTime _date = DateTime.now();
  Map<String, dynamic>? _links;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  List<DrtLocation> get _locs {
    if (_kind == 'drat') return _all.where((e) => e.isDrat).toList();
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
      await _loadCourts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  String _idOf(Map row, List<String> keys) {
    for (final k in keys) {
      final v = row[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  String _labelOf(Map row) {
    return _idOf(row, ['courtName', 'court_name', 'benchNature', 'courtNo', 'court_no', 'label']);
  }

  Future<void> _loadCourts() async {
    final id = _schemeId;
    if (id == null) return;
    setState(() {
      _error = null;
      _links = null;
    });
    try {
      final names = await DrtClient.instance.courtNames(schemeId: id, date: _date);
      final nameId = names.isEmpty ? null : _idOf(names.first, ['courtNameId', 'id', 'benchNature', 'courtName']);
      var nos = <Map<String, dynamic>>[];
      if (nameId != null && nameId.isNotEmpty) {
        nos = await DrtClient.instance.courtNos(schemeId: id, date: _date, courtNameId: nameId);
      }
      if (!mounted) return;
      setState(() {
        _names = names;
        _courtNameId = nameId;
        _nos = nos;
        _courtNo = nos.isEmpty ? null : _idOf(nos.first, ['courtNo', 'court_no', 'id']);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _names = [];
        _nos = [];
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  Future<void> _search() async {
    final id = _schemeId;
    final nameId = _courtNameId;
    final no = _courtNo;
    if (id == null || nameId == null || no == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select DRT, court name and court no.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final links = await DrtClient.instance.causeList(
        schemeId: id,
        date: _date,
        courtNameId: nameId,
        courtNo: no,
        kind: _kind,
      );
      if (!mounted) return;
      setState(() {
        _links = links;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _links = null;
        _loading = false;
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _loadCourts();
  }

  @override
  Widget build(BuildContext context) {
    final locs = _locs;
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('DRT cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: 'Daily cause list',
            subtitle: '${DateFormat('dd MMM yyyy').format(_date)}  ·  official PDF from drt.gov.in',
            color: const Color(0xFF1A4A6B),
            icon: Icons.list_alt,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('DRT'), selected: _kind == 'drt', onSelected: (_) {
                setState(() {
                  _kind = 'drt';
                  _schemeId = _locs.isEmpty ? null : _locs.first.id;
                });
                _loadCourts();
              }),
              ChoiceChip(label: const Text('DRAT'), selected: _kind == 'drat', onSelected: (_) {
                setState(() {
                  _kind = 'drat';
                  _schemeId = _locs.isEmpty ? null : _locs.first.id;
                });
                _loadCourts();
              }),
              ChoiceChip(label: const Text('RC / TRC'), selected: _kind == 'rc', onSelected: (_) {
                setState(() {
                  _kind = 'rc';
                  _schemeId = _all.where((e) => !e.isDrat).isEmpty ? null : _all.firstWhere((e) => !e.isDrat).id;
                });
                _loadCourts();
              }),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Listing date', prefixIcon: Icon(Icons.event)),
              child: Text(DateFormat('dd-MM-yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: locs.any((e) => e.id == _schemeId) ? _schemeId : null,
            decoration: const InputDecoration(labelText: 'Tribunal'),
            items: locs.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (id) {
              setState(() => _schemeId = id);
              _loadCourts();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _names.any((e) => _idOf(e, ['courtNameId', 'id', 'benchNature', 'courtName']) == _courtNameId) ? _courtNameId : null,
            decoration: const InputDecoration(labelText: 'Court name'),
            items: _names
                .map((e) => DropdownMenuItem(value: _idOf(e, ['courtNameId', 'id', 'benchNature', 'courtName']), child: Text(_labelOf(e))))
                .toList(),
            onChanged: (id) async {
              setState(() => _courtNameId = id);
              if (id != null && _schemeId != null) {
                final nos = await DrtClient.instance.courtNos(schemeId: _schemeId!, date: _date, courtNameId: id);
                if (!mounted) return;
                setState(() {
                  _nos = nos;
                  _courtNo = nos.isEmpty ? null : _idOf(nos.first, ['courtNo', 'court_no', 'id']);
                });
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _nos.any((e) => _idOf(e, ['courtNo', 'court_no', 'id']) == _courtNo) ? _courtNo : null,
            decoration: const InputDecoration(labelText: 'Court no.'),
            items: _nos
                .map((e) => DropdownMenuItem(value: _idOf(e, ['courtNo', 'court_no', 'id']), child: Text(_idOf(e, ['courtNo', 'court_no', 'id']))))
                .toList(),
            onChanged: (v) => setState(() => _courtNo = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(onPressed: _loading ? null : _search, child: const Text('Open cause list')),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: AppColors.stampRed)),
            ),
          if (_links != null) ...[
            const SizedBox(height: 16),
            if ('${_links!['dailyCauseListLink'] ?? ''}'.isNotEmpty)
              FilledButton.icon(
                onPressed: () => InAppDocumentScreen.open(context, '${_links!['dailyCauseListLink']}', title: 'Daily cause list'),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Daily cause list PDF'),
              ),
            if ('${_links!['supplementaryCauseListLink'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => InAppDocumentScreen.open(context, '${_links!['supplementaryCauseListLink']}', title: 'Supplementary list'),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Supplementary cause list'),
              ),
            ],
          ],
          const SourceFooter(tribunal: 'DRT', officialUrl: 'https://drt.gov.in/#/causelist'),
        ],
      ),
    );
  }
}
