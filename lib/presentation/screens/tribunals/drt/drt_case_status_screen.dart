import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/drt_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/drt/drt_case_details_screen.dart';
import 'package:flutter/material.dart';

class DrtCaseStatusScreen extends StatefulWidget {
  const DrtCaseStatusScreen({super.key});

  @override
  State<DrtCaseStatusScreen> createState() => _DrtCaseStatusScreenState();
}

class _DrtCaseStatusScreenState extends State<DrtCaseStatusScreen> {
  final _diary = TextEditingController();
  final _caseNo = TextEditingController();
  final _party = TextEditingController();
  List<DrtLocation> _all = [];
  List<DrtCaseType> _types = [];
  String _forum = 'drt';
  String _mode = 'diary';
  String? _schemeId;
  String? _typeId;
  late String _year;
  bool _loading = true;
  bool _searching = false;
  String? _error;

  final _years = List.generate(25, (i) => '${DateTime.now().year - i}');

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
    _party.dispose();
    super.dispose();
  }

  List<DrtLocation> get _locs => _all.where((e) => _forum == 'drat' ? e.isDrat : !e.isDrat).toList();

  Future<void> _boot() async {
    try {
      final all = await DrtClient.instance.locations();
      final locs = all.where((e) => !e.isDrat).toList();
      final first = locs.isEmpty ? null : locs.first;
      if (!mounted) return;
      setState(() {
        _all = all;
        _schemeId = first?.id;
        _loading = false;
      });
      if (first != null) await _loadTypes(first.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  Future<void> _loadTypes(String id) async {
    final types = await DrtClient.instance.caseTypes(id);
    if (!mounted) return;
    setState(() {
      _types = types;
      _typeId = types.isEmpty ? null : types.first.id;
    });
  }

  String get _name {
    for (final loc in _all) {
      if (loc.id == _schemeId) return loc.name;
    }
    return 'DRT';
  }

  Future<void> _search() async {
    final id = _schemeId;
    if (id == null) return;
    setState(() => _searching = true);
    try {
      final drat = _forum == 'drat';
      if (_mode == 'party') {
        final rows = await DrtClient.instance.partyWise(schemeId: id, party: _party.text, drat: drat);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _DrtPartyHitsScreen(rows: rows, locationName: _name, schemeId: id, drat: drat),
          ),
        );
      } else if (_mode == 'diary') {
        final rec = await DrtClient.instance.diaryWise(schemeId: id, diaryNo: _diary.text, year: _year, drat: drat);
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => DrtCaseDetailsScreen(record: rec, locationName: _name)));
      } else {
        final rec = await DrtClient.instance.caseNoWise(
          schemeId: id,
          caseType: _typeId ?? '',
          caseNo: _caseNo.text,
          year: _year,
          drat: drat,
        );
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => DrtCaseDetailsScreen(record: rec, locationName: _name)));
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
    final locs = _locs;
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('DRT case details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const CourtBand(
                  title: 'Search public case',
                  subtitle: 'drt.gov.in  ·  diary, case no. or party  ·  DRT and DRAT',
                  color: Color(0xFF1A4A6B),
                  icon: Icons.search,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: AppColors.stampRed)),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _chip('drt', 'DRT')),
                    const SizedBox(width: 8),
                    Expanded(child: _chip('drat', 'DRAT')),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: locs.any((e) => e.id == _schemeId) ? _schemeId : null,
                  decoration: InputDecoration(labelText: _forum == 'drat' ? 'DRAT' : 'DRT'),
                  items: locs.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    setState(() => _schemeId = id);
                    _loadTypes(id);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _modeChip('diary', 'Diary no.'),
                    _modeChip('case', 'Case no.'),
                    _modeChip('party', 'Party name'),
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
                    initialValue: _types.any((t) => t.id == _typeId) ? _typeId : null,
                    decoration: const InputDecoration(labelText: 'Case type'),
                    items: _types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setState(() => _typeId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _caseNo, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Case number (serial only)')),
                  const SizedBox(height: 12),
                  _yearField(),
                ] else
                  TextField(controller: _party, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Party name')),
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
                const SourceFooter(tribunal: 'DRT', officialUrl: DrtClient.site),
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

  Widget _chip(String id, String label) {
    final on = _forum == id;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) {
        setState(() {
          _forum = id;
          final locs = _locs;
          _schemeId = locs.isEmpty ? null : locs.first.id;
        });
        if (_schemeId != null) _loadTypes(_schemeId!);
      },
    );
  }

  Widget _modeChip(String id, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _mode == id,
      onSelected: (_) => setState(() => _mode = id),
    );
  }
}

class _DrtPartyHitsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final String locationName;
  final String schemeId;
  final bool drat;

  const _DrtPartyHitsScreen({required this.rows, required this.locationName, required this.schemeId, required this.drat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('Party matches')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final row = rows[i];
          final diary = '${row['diaryno'] ?? row['diaryNo'] ?? ''}'.trim();
          final year = '${row['diaryyear'] ?? row['diaryYear'] ?? row['caseyear'] ?? ''}'.trim();
          final party = '${row['petitionerName'] ?? row['partyName'] ?? row['caseno'] ?? 'Case'}';
          return Card(
            color: AppColors.paper,
            child: ListTile(
              title: Text(party, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('Diary $diary / $year'),
              onTap: () async {
                try {
                  final rec = diary.isEmpty
                      ? row
                      : await DrtClient.instance.diaryWise(schemeId: schemeId, diaryNo: diary, year: year.isEmpty ? '${DateTime.now().year}' : year, drat: drat);
                  if (!context.mounted) return;
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => DrtCaseDetailsScreen(record: rec, locationName: locationName)));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
            ),
          );
        },
      ),
    );
  }
}
