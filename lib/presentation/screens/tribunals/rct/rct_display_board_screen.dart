import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/rct_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_case_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RctDisplayBoardScreen extends StatefulWidget {
  const RctDisplayBoardScreen({super.key});

  @override
  State<RctDisplayBoardScreen> createState() => _RctDisplayBoardScreenState();
}

class _RctDisplayBoardScreenState extends State<RctDisplayBoardScreen> {
  List<RctBench> _benches = [];
  List<RctCourt> _courts = [];
  int? _benchId;
  int _courtNo = 1;
  List<Map<String, dynamic>> _rows = [];
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
      final rows = await RctClient.instance.displayBoard(benchId: benchId, courtNo: _courtNo);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _rows = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('RCT display board')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CourtBand(
              title: "Today's board",
              subtitle: '$today  ·  live list from eRCT',
              color: const Color(0xFF8B2E2E),
              icon: Icons.tv_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _benches.any((b) => b.id == _benchId) ? _benchId : null,
                  decoration: const InputDecoration(labelText: 'Bench', prefixIcon: Icon(Icons.account_balance_outlined)),
                  items: _benches
                      .map((b) => DropdownMenuItem(value: b.id, child: Text('${b.name} (${b.code})')))
                      .toList(),
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
                  decoration: const InputDecoration(labelText: 'Court', prefixIcon: Icon(Icons.meeting_room_outlined)),
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
                : _error != null && _rows.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink)),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _rows.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _rows.length) {
                              return const SourceFooter(
                                tribunal: 'RCT',
                                officialUrl: 'https://cis.erct.gov.in/#/display-board',
                              );
                            }
                            return _rowCard(_rows[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _rowCard(Map<String, dynamic> row) {
    final caseNo = '${row['case_no'] ?? ''}'.trim();
    final title = '${row['case_title'] ?? ''}'.trim();
    final item = '${row['item_no'] ?? ''}';
    final court = '${row['court_no'] ?? ''}';
    final filing = '${row['filing_no'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x3314384A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: filing.isEmpty
            ? null
            : () async {
                final bench = _benches.where((b) => b.id == _benchId).firstOrNull;
                if (bench == null) return;
                try {
                  final json = await RctClient.instance.caseByFiling(locationCode: bench.code, filingNo: filing);
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RctCaseDetailsScreen(json: json, benchCode: bench.code)),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: const Color(0xFF8B2E2E)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MetaChip(label: 'Item $item', color: const Color(0xFF8B2E2E)),
                          const SizedBox(width: 6),
                          MetaChip(label: 'Court $court', color: AppColors.stampBlue),
                          const Spacer(),
                          Text(
                            '${row['listing_date'] ?? ''}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caseNo.isEmpty ? filing : caseNo,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      if (title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
