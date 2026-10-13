import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/rct_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_case_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RctCauseListScreen extends StatefulWidget {
  final bool judgements;

  const RctCauseListScreen({super.key, this.judgements = false});

  @override
  State<RctCauseListScreen> createState() => _RctCauseListScreenState();
}

class _RctCauseListScreenState extends State<RctCauseListScreen> {
  List<RctBench> _benches = [];
  List<RctCourt> _courts = [];
  int? _benchId;
  int _courtNo = 1;
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _benchesRows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final benches = await RctClient.instance.benches();
      RctBench? preferred;
      for (final bench in benches) {
        if (bench.code == 'DLI') {
          preferred = bench;
          break;
        }
      }
      preferred ??= benches.isEmpty ? null : benches.first;
      if (!mounted) return;
      setState(() {
        _benches = benches;
        _benchId = preferred?.id;
      });
      if (_benchId != null) await _load(resetCourts: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _load({bool resetCourts = false}) async {
    final benchId = _benchId;
    if (benchId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (resetCourts) {
        final courts = await RctClient.instance.courts(benchId);
        _courts = courts;
        _courtNo = courts.isNotEmpty ? courts.first.no : 1;
      }
      final json = await RctClient.instance.causeList(date: _date, benchId: benchId, courtNo: _courtNo);
      final data = json['data'];
      final rows = <Map<String, dynamic>>[];
      if (data is List) {
        for (final item in data.whereType<Map>()) {
          rows.add(Map<String, dynamic>.from(item));
        }
      }
      if (!mounted) return;
      setState(() {
        _benchesRows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _benchesRows = [];
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _load();
  }

  List<Map<String, dynamic>> get _cases {
    final out = <Map<String, dynamic>>[];
    for (final bench in _benchesRows) {
      final cases = bench['case_details_array'];
      if (cases is! List) continue;
      for (final item in cases.whereType<Map>()) {
        final row = Map<String, dynamic>.from(item);
        row['_court'] = '${bench['court_no'] ?? ''}';
        row['_judges'] = '${bench['judge_name'] ?? ''}';
        row['_bench'] = '${bench['bench_name'] ?? ''}';
        out.add(row);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cases = _cases;
    final label = widget.judgements ? 'RCT judgements' : 'RCT cause list';
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(label)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CourtBand(
              title: widget.judgements ? 'Orders / judgements' : 'Daily cause list',
              subtitle: '${DateFormat('dd MMM yyyy').format(_date)}  ·  defaults to today',
              color: const Color(0xFF8B2E2E),
              icon: widget.judgements ? Icons.gavel : Icons.list_alt,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Listing date', prefixIcon: Icon(Icons.event)),
                    child: Text(DateFormat('dd-MM-yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _benches.any((b) => b.id == _benchId) ? _benchId : null,
                  decoration: const InputDecoration(labelText: 'Bench'),
                  items: _benches.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.name} (${b.code})'))).toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    setState(() => _benchId = id);
                    _load(resetCourts: true);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _courts.any((c) => c.no == _courtNo) ? _courtNo : null,
                  decoration: const InputDecoration(labelText: 'Court'),
                  items: _courts.map((c) => DropdownMenuItem(value: c.no, child: Text(c.label))).toList(),
                  onChanged: (no) {
                    if (no == null) return;
                    setState(() => _courtNo = no);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && cases.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: cases.length + 1,
                          itemBuilder: (context, index) {
                            if (index == cases.length) {
                              return SourceFooter(
                                tribunal: 'RCT',
                                officialUrl: widget.judgements
                                    ? 'https://cis.erct.gov.in/#/public_judgement'
                                    : 'https://cis.erct.gov.in/#/public_causelist',
                              );
                            }
                            return _caseCard(cases[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _caseCard(Map<String, dynamic> row) {
    final caseNo = '${row['case_no'] ?? ''}'.trim();
    final title = '${row['main_party'] ?? row['case_title'] ?? ''}'.trim();
    final filing = '${row['filing_no'] ?? ''}'.trim();
    final hash = RctClient.hashPdf(row['hash_filename']);
    final fileName = '${row['file_name'] ?? row['order_file'] ?? ''}'.trim();
    final pdf = hash ?? (fileName.isEmpty ? null : RctClient.orderPdfUrl(filing, fileName));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x3314384A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MetaChip(label: 'Court ${row['_court'] ?? ''}', color: const Color(0xFF8B2E2E)),
                const Spacer(),
                if ('${row['accidentTypeName'] ?? ''}'.isNotEmpty)
                  Text('${row['accidentTypeName']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 6),
            Text(caseNo.isEmpty ? filing : caseNo, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: filing.isEmpty
                        ? null
                        : () async {
                            final bench = _benches.where((b) => b.id == _benchId);
                            if (bench.isEmpty) return;
                            try {
                              final json = await RctClient.instance.caseByFiling(locationCode: bench.first.code, filingNo: filing);
                              if (!mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RctCaseDetailsScreen(json: json, benchCode: bench.first.code)),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                    child: const Text('Record'),
                  ),
                ),
                if (widget.judgements || pdf != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: pdf == null
                          ? null
                          : () => InAppDocumentScreen.open(context, pdf, title: caseNo.isEmpty ? 'Order' : caseNo),
                      child: Text(pdf == null ? 'No PDF' : 'PDF', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
