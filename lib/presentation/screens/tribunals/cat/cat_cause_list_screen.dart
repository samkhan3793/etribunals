import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/cat_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:flutter/material.dart';

class CatCauseListScreen extends StatefulWidget {
  const CatCauseListScreen({super.key});

  @override
  State<CatCauseListScreen> createState() => _CatCauseListScreenState();
}

class _CatCauseListScreenState extends State<CatCauseListScreen> {
  String? _schemaId;
  DateTime _date = DateTime.now();
  String _kind = 'daily';
  String _courtName = '1';
  String _courtNo = '1';
  bool _searching = false;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _schemaId = CatSession.instance.bench?.id ?? '100';
  }

  CatBench get _bench {
    final id = _schemaId ?? '100';
    return CatClient.benches.firstWhere((e) => e.id == id, orElse: () => CatClient.benches.first);
  }

  Future<void> _pickDate() async {
    final next = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1985), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (next != null) setState(() => _date = next);
  }

  Future<void> _search() async {
    final id = _schemaId;
    if (id == null) return;
    CatSession.instance.bench = _bench;
    setState(() => _searching = true);
    try {
      if (_kind == 'daily') {
        final rows = CatClient.instance.asRows(
          await CatClient.instance.post('getcatCauselist', {
            'catschemaId': id,
            'catCauseListDate': CatClient.instance.listingDate(_date),
          }),
          empty: 'No cause list PDF for this date.',
        );
        if (!mounted) return;
        setState(() => _rows = rows);
      } else {
        final rows = CatClient.instance.asRows(
          await CatClient.instance.post('getTentativeCauselist', {
            'catschemaId': id,
            'causeListDate': CatClient.instance.listingDate(_date),
            'courtNameId': _courtName,
            'courtNo': _courtNo,
          }),
          empty: 'No tentative cause list for this sitting.',
        );
        if (!mounted) return;
        setState(() => _rows = rows);
      }
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
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('CAT cause list')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: _bench.name,
            subtitle: 'Daily cause list PDF  ·  or tentative list by court',
            color: const Color(0xFF3D4A6B),
            icon: Icons.list_alt,
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
              ChoiceChip(label: const Text('Daily'), selected: _kind == 'daily', onSelected: (_) => setState(() => _kind = 'daily')),
              ChoiceChip(label: const Text('Tentative'), selected: _kind == 'tentative', onSelected: (_) => setState(() => _kind = 'tentative')),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Listing date'),
            subtitle: Text(CatClient.instance.listingDate(_date)),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDate,
          ),
          if (_kind == 'tentative') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _courtName,
              decoration: const InputDecoration(labelText: 'Court name'),
              items: CatClient.courtNames.map((t) => DropdownMenuItem(value: t.key, child: Text(t.value))).toList(),
              onChanged: (v) => setState(() => _courtName = v ?? _courtName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _courtNo,
              decoration: const InputDecoration(labelText: 'Court no.'),
              items: List.generate(12, (i) => '${i + 1}').map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
              onChanged: (v) => setState(() => _courtNo = v ?? _courtNo),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _searching ? null : _search,
              child: _searching
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('View cause list'),
            ),
          ),
          const SizedBox(height: 16),
          ..._rows.map((row) {
            final url = CatClient.documentUrl(row);
            final label = '${row['path'] != null ? 'Cause list PDF' : row['caseno'] ?? row['applicantno'] ?? row['diaryno'] ?? 'Record'}';
            return Card(
              color: AppColors.paper,
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accent),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_bench.name),
                onTap: url == null ? null : () => InAppDocumentScreen.open(context, url, title: 'CAT cause list'),
              ),
            );
          }),
          const SourceFooter(tribunal: 'CAT', officialUrl: CatClient.site),
        ],
      ),
    );
  }
}
