import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/drt_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:flutter/material.dart';

class DrtTransferScreen extends StatefulWidget {
  const DrtTransferScreen({super.key});

  @override
  State<DrtTransferScreen> createState() => _DrtTransferScreenState();
}

class _DrtTransferScreenState extends State<DrtTransferScreen> {
  final _caseNo = TextEditingController();
  List<DrtLocation> _drts = [];
  List<DrtCaseType> _types = [];
  String _mode = 'status';
  String? _schemeId;
  String? _typeId;
  late String _year;
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
    _caseNo.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final all = await DrtClient.instance.locations();
      final drts = all.where((e) => !e.isDrat).toList();
      final first = drts.isEmpty ? null : drts.first;
      if (!mounted) return;
      setState(() {
        _drts = drts;
        _schemeId = first?.id;
        _loading = false;
      });
      if (first != null) {
        final types = await DrtClient.instance.caseTypes(first.id);
        if (!mounted) return;
        setState(() {
          _types = types;
          _typeId = types.isEmpty ? null : types.first.id;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  Future<void> _search() async {
    final id = _schemeId;
    if (id == null) return;
    setState(() => _searching = true);
    try {
      final path = _mode == 'status' ? 'getRcTrcCaseStatusReport' : 'getRcTrcNewCreate';
      final body = _mode == 'status'
          ? {
              'schemeNameDrtId': id,
              'caseTypeId': _typeId,
              'caseNo': _caseNo.text.trim(),
              'caseYear': _year,
            }
          : {
              'schemeNameDrtId': id,
              'caseType': _typeId,
              'dailyFinalRcNo': _caseNo.text.trim(),
              'dailyFinalRcYear': _year,
            };
      final rows = await DrtClient.instance.report(path, body, empty: 'No RC / TRC record found.');
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
      if (v.startsWith('http')) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('DRT case transfer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'RC / TRC transfer',
            subtitle: 'Case status report and new RC/TRC from drt.gov.in',
            color: Color(0xFF1A4A6B),
            icon: Icons.swap_horiz,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('RC/TRC status'), selected: _mode == 'status', onSelected: (_) => setState(() => _mode = 'status')),
              ChoiceChip(label: const Text('New RC/TRC'), selected: _mode == 'new', onSelected: (_) => setState(() => _mode = 'new')),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _drts.any((e) => e.id == _schemeId) ? _schemeId : null,
              decoration: const InputDecoration(labelText: 'DRT'),
              items: _drts.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (id) async {
                setState(() => _schemeId = id);
                if (id == null) return;
                final types = await DrtClient.instance.caseTypes(id);
                if (!mounted) return;
                setState(() {
                  _types = types;
                  _typeId = types.isEmpty ? null : types.first.id;
                });
              },
            ),
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
              controller: _caseNo,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _mode == 'new' ? 'RC / TRC number' : 'Case number'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _year,
              decoration: const InputDecoration(labelText: 'Year'),
              items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (v) => setState(() => _year = v ?? _year),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _searching ? null : _search,
                child: _searching
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Search'),
              ),
            ),
          ],
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: AppColors.stampRed))),
          const SizedBox(height: 12),
          ..._rows.map((row) {
            final pdf = _pdf(row);
            return Card(
              color: AppColors.paper,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${row['caseno'] ?? row['dailyFinalRcNo'] ?? row['rcno'] ?? 'RC / TRC'}', maxLines: 2),
                subtitle: Text('${row['petitionerName'] ?? row['casestatus'] ?? ''}'),
                trailing: pdf == null ? null : const Icon(Icons.picture_as_pdf_outlined),
                onTap: pdf == null ? null : () => InAppDocumentScreen.open(context, pdf, title: 'RC / TRC'),
              ),
            );
          }),
          const SourceFooter(tribunal: 'DRT', officialUrl: 'https://drt.gov.in/#/caseTransfer'),
        ],
      ),
    );
  }
}
