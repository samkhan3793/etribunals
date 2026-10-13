import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/rct_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_case_details_screen.dart';
import 'package:flutter/material.dart';

class RctTrackCaseStatusScreen extends StatefulWidget {
  const RctTrackCaseStatusScreen({super.key});

  @override
  State<RctTrackCaseStatusScreen> createState() => _RctTrackCaseStatusScreenState();
}

class _RctTrackCaseStatusScreenState extends State<RctTrackCaseStatusScreen> {
  final _filing = TextEditingController();
  final _caseNo = TextEditingController();
  List<RctBench> _benches = [];
  List<RctCaseType> _types = [];
  String? _benchCode;
  String? _caseType;
  late String _year;
  String _mode = 'filing';
  bool _loading = true;
  bool _searching = false;
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
    _filing.dispose();
    _caseNo.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final benches = await RctClient.instance.benches();
      final types = await RctClient.instance.caseTypes();
      String? code;
      for (final b in benches) {
        if (b.code == 'DLI') {
          code = b.code;
          break;
        }
      }
      code ??= benches.isEmpty ? null : benches.first.code;
      if (!mounted) return;
      setState(() {
        _benches = benches;
        _types = types;
        _benchCode = code;
        _caseType = types.any((t) => t.code == '301') ? '301' : (types.isEmpty ? null : types.first.code);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _clean(e);
        _loading = false;
      });
    }
  }

  String _clean(Object e) => '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');

  void _onCaseNoChanged(String raw) {
    final parsed = RctCaseQuery.parse(raw);
    var changed = false;
    if (parsed.benchCode != null && _benches.any((b) => b.code == parsed.benchCode) && parsed.benchCode != _benchCode) {
      _benchCode = parsed.benchCode;
      changed = true;
    }
    if (parsed.year != null && _years.contains(parsed.year) && parsed.year != _year) {
      _year = parsed.year!;
      changed = true;
    }
    if (parsed.typeCode != null && _types.any((t) => t.code == parsed.typeCode) && parsed.typeCode != _caseType) {
      _caseType = parsed.typeCode;
      changed = true;
    }
    if (changed) setState(() {});
  }

  Future<void> _search() async {
    final code = _benchCode;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a bench first.')));
      return;
    }
    setState(() => _searching = true);
    try {
      final json = _mode == 'filing'
          ? await RctClient.instance.caseByFiling(locationCode: code, filingNo: _filing.text)
          : await RctClient.instance.caseByNumber(
              locationCode: code,
              caseNo: RctCaseQuery.parse(_caseNo.text).serial,
              caseType: _caseType ?? '',
              year: _year,
            );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RctCaseDetailsScreen(json: json, benchCode: code)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e))));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('RCT case status')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const CourtBand(
                  title: 'Search public case',
                  subtitle: 'eRCT CIS  ·  filing no. or case no.',
                  color: Color(0xFF8B2E2E),
                  icon: Icons.search,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: AppColors.stampRed)),
                  ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _benches.any((b) => b.code == _benchCode) ? _benchCode : null,
                  decoration: const InputDecoration(labelText: 'Bench'),
                  items: _benches
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.code,
                          child: Text('${b.name} (${b.code})', overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _benchCode = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _modeChip('filing', 'Filing no.')),
                    const SizedBox(width: 8),
                    Expanded(child: _modeChip('case', 'Case no.')),
                  ],
                ),
                const SizedBox(height: 12),
                if (_mode == 'filing')
                  TextField(
                    controller: _filing,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Filing / e-reference no.',
                      hintText: 'e.g. 2026073010780028',
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _types.any((t) => t.code == _caseType) ? _caseType : null,
                    decoration: const InputDecoration(labelText: 'Case type'),
                    items: _types
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.code,
                            child: Text(t.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (context) => _types
                        .map(
                          (t) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _caseType = v),
                  ),
                  const SizedBox(height: 12),
              TextField(
                    controller: _caseNo,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Case serial number',
                      hintText: '689   or paste OA(IIu)/DLI/689/2026',
                    ),
                    onChanged: _onCaseNoChanged,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEE6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x3314384A)),
                    ),
                    child: const Text(
                      'eRCT case number looks like OA(IIu)/DLI/689/2026(DT).\n'
                      'Type only 689 here. Bench = DELHI (DLI), year = 2026, case type = Form II (untoward incident).\n'
                      'A value like 2 only works if that bench really has case serial 2 for the selected type and year.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.ink, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                    onChanged: (v) => setState(() => _year = v ?? _year),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _searching ? null : _search,
                    child: _searching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Search'),
                  ),
                ),
                const SourceFooter(tribunal: 'RCT', officialUrl: 'https://cis.erct.gov.in/#/'),
              ],
            ),
    );
  }

  Widget _modeChip(String value, String label) {
    final selected = _mode == value;
    return Material(
      color: selected ? const Color(0xFF8B2E2E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _mode = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? const Color(0xFF8B2E2E) : AppColors.outline),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
