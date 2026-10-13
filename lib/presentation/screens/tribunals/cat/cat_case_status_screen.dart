import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/cat_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/cat/cat_case_details_screen.dart';
import 'package:flutter/material.dart';

class CatCaseStatusScreen extends StatefulWidget {
  const CatCaseStatusScreen({super.key});

  @override
  State<CatCaseStatusScreen> createState() => _CatCaseStatusScreenState();
}

class _CatCaseStatusScreenState extends State<CatCaseStatusScreen> {
  final _diary = TextEditingController();
  final _caseNo = TextEditingController();
  final _party = TextEditingController();
  final _adv = TextEditingController();
  String _mode = 'diary';
  String? _schemaId;
  String _typeId = '1';
  String _partyType = '3';
  String _advType = '3';
  late String _year;
  bool _searching = false;

  final _years = List.generate(40, (i) => '${DateTime.now().year - i}');

  @override
  void initState() {
    super.initState();
    _year = _years.first;
    _schemaId = CatSession.instance.bench?.id ?? '100';
  }

  @override
  void dispose() {
    _diary.dispose();
    _caseNo.dispose();
    _party.dispose();
    _adv.dispose();
    super.dispose();
  }

  CatBench get _bench {
    final id = _schemaId ?? '100';
    return CatClient.benches.firstWhere((e) => e.id == id, orElse: () => CatClient.benches.first);
  }

  Future<void> _search() async {
    final id = _schemaId;
    if (id == null) return;
    CatSession.instance.bench = _bench;
    setState(() => _searching = true);
    try {
      if (_mode == 'diary') {
        final rec = CatClient.instance.asRows(
          await CatClient.instance.post('casedetail_individual_dairy_no_wise', {
            'catschemaId': id,
            'dairyNo': _diary.text.trim(),
            'caseYear': _year,
          }),
          empty: 'No CAT case for this diary number.',
        ).first;
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CatCaseDetailsScreen(record: rec, benchName: _bench.name)));
      } else if (_mode == 'case') {
        final rec = CatClient.instance.asRows(
          await CatClient.instance.post('casedetail_individual_case_no_wise', {
            'casetypeId': _typeId,
            'catschemaId': id,
            'caseNo': _caseNo.text.trim(),
            'caseYear': _year,
          }),
          empty: 'No CAT case for this case number.',
        ).first;
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CatCaseDetailsScreen(record: rec, benchName: _bench.name)));
      } else if (_mode == 'party') {
        final rows = CatClient.instance.asRows(
          await CatClient.instance.post('casedetail_party_name_wise', {
            'catschemaId': id,
            'partyType': _partyType,
            'partyName': _party.text.trim().toLowerCase(),
          }),
          empty: 'No cases for this party name.',
        );
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => _CatHitsScreen(rows: rows, benchName: _bench.name)));
      } else {
        final rows = CatClient.instance.asRows(
          await CatClient.instance.post('casedetail_adv_name_wise', {
            'catschemaId': id,
            'advType': _advType,
            'advName': _adv.text.trim().toLowerCase(),
          }),
          empty: 'No cases for this advocate.',
        );
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => _CatHitsScreen(rows: rows, benchName: _bench.name)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('CAT case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: 'Search public case',
            subtitle: '${_bench.name}  ·  diary, case no., party or advocate',
            color: const Color(0xFF3D4A6B),
            icon: Icons.search,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _schemaId,
            decoration: const InputDecoration(labelText: 'Bench'),
            items: CatClient.benches.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
            onChanged: (v) => setState(() => _schemaId = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _modeChip('diary', 'Diary no.'),
              _modeChip('case', 'Case no.'),
              _modeChip('party', 'Party name'),
              _modeChip('adv', 'Advocate'),
            ],
          ),
          const SizedBox(height: 12),
          if (_mode == 'diary') ...[
            TextField(controller: _diary, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diary number')),
            const SizedBox(height: 12),
            _yearField(),
          ] else if (_mode == 'case') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _typeId,
              decoration: const InputDecoration(labelText: 'Case type'),
              items: CatClient.caseTypes.map((t) => DropdownMenuItem(value: t.key, child: Text(t.value))).toList(),
              onChanged: (v) => setState(() => _typeId = v ?? _typeId),
            ),
            const SizedBox(height: 12),
            TextField(controller: _caseNo, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Case number (serial only)')),
            const SizedBox(height: 12),
            _yearField(),
          ] else if (_mode == 'party') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _partyType,
              decoration: const InputDecoration(labelText: 'Party'),
              items: CatClient.partyTypes.map((t) => DropdownMenuItem(value: t.key, child: Text(t.value))).toList(),
              onChanged: (v) => setState(() => _partyType = v ?? _partyType),
            ),
            const SizedBox(height: 12),
            TextField(controller: _party, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Party name')),
          ] else ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _advType,
              decoration: const InputDecoration(labelText: 'Advocate'),
              items: CatClient.partyTypes.map((t) => DropdownMenuItem(value: t.key, child: Text(t.value))).toList(),
              onChanged: (v) => setState(() => _advType = v ?? _advType),
            ),
            const SizedBox(height: 12),
            TextField(controller: _adv, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Advocate name')),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _searching ? null : _search,
              child: _searching
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search'),
            ),
          ),
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

  Widget _modeChip(String id, String label) {
    final on = _mode == id;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(() => _mode = id),
    );
  }
}

class _CatHitsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final String benchName;

  const _CatHitsScreen({required this.rows, required this.benchName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${rows.length} cases')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final r = rows[i];
          final title = '${r['caseno'] ?? r['applicantno'] ?? r['diaryno'] ?? 'Case'}';
          final party = '${r['applicant'] ?? r['applicantName'] ?? ''} vs ${r['respondent'] ?? r['respondentName'] ?? ''}'.trim();
          return Card(
            color: AppColors.paper,
            child: ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(party == 'vs' ? benchName : party),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CatCaseDetailsScreen(record: r, benchName: benchName)),
              ),
            ),
          );
        },
      ),
    );
  }
}
