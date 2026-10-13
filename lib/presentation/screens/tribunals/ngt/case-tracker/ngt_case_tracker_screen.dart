import 'dart:typed_data';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/utils/ngt_case_client.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/case-tracker/ngt_search_results_screen.dart';
import 'package:flutter/material.dart';

class NgtTrackCaseStatusScreen extends StatefulWidget {
  const NgtTrackCaseStatusScreen({super.key});

  @override
  State<NgtTrackCaseStatusScreen> createState() => _NgtTrackCaseStatusScreenState();
}

class _NgtTrackCaseStatusScreenState extends State<NgtTrackCaseStatusScreen> {
  final _diaryController = TextEditingController();
  final _caseNumberController = TextEditingController();
  final _captchaController = TextEditingController();

  String _searchType = 'diary';
  String _zoneType = '1';
  String _caseType = '1';
  late String _year;
  Uint8List? _captchaBytes;
  bool _loadingCaptcha = true;
  bool _searching = false;

  final _years = List.generate(20, (i) => '${DateTime.now().year - i}');

  static const _benches = [
    {'value': '1', 'label': 'Principal Bench (Delhi)'},
    {'value': '2', 'label': 'Eastern Zone (Kolkata)'},
    {'value': '3', 'label': 'Central Zone (Bhopal)'},
    {'value': '4', 'label': 'Western Zone (Pune)'},
    {'value': '5', 'label': 'Southern Zone (Chennai)'},
  ];

  static const _caseTypes = [
    {'value': '1', 'label': 'Original Application'},
    {'value': '2', 'label': 'Review Application'},
    {'value': '3', 'label': 'Misc Application in disposed of cases'},
    {'value': '4', 'label': 'Appeal'},
    {'value': '5', 'label': 'Execution Application'},
    {'value': '6', 'label': 'IA'},
    {'value': '7', 'label': 'TA'},
  ];

  @override
  void initState() {
    super.initState();
    _year = _years.first;
    _loadCaptcha();
  }

  @override
  void dispose() {
    _diaryController.dispose();
    _caseNumberController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _loadCaptcha() async {
    setState(() => _loadingCaptcha = true);
    try {
      final bytes = await NgtCaseClient.instance.loadCaptcha(
        sessionUrl: _searchType == 'diary' ? NgtCaseClient.diaryFormUrl : NgtCaseClient.caseFormUrl,
      );
      if (!mounted) return;
      setState(() {
        _captchaBytes = bytes;
        _loadingCaptcha = false;
        _captchaController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCaptcha = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load NGT captcha. Try refresh.')),
      );
    }
  }

  Future<void> _search() async {
    final captcha = _captchaController.text.trim();
    if (captcha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter captcha')));
      return;
    }
    if (_searchType == 'diary' && _diaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter diary number')));
      return;
    }
    if (_searchType == 'casenumber' && _caseNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter case number')));
      return;
    }

    setState(() => _searching = true);
    try {
      final hits = _searchType == 'diary'
          ? await NgtCaseClient.instance.searchByDiary(
              zoneType: _zoneType,
              diaryNo: _diaryController.text,
              year: _year,
              captcha: captcha,
            )
          : await NgtCaseClient.instance.searchByCaseNumber(
              zoneType: _zoneType,
              caseType: _caseType,
              caseNumber: _caseNumberController.text,
              year: _year,
              captcha: captcha,
            );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NgtSearchResultsScreen(hits)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() => _searching = false);
        _loadCaptcha();
      }
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NGT case status')),
      backgroundColor: AppColors.secondary,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Search uses the official NGT form at greentribunal.gov.in. Results open in the app, not the full website.',
            style: TextStyle(color: AppColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _searchType,
            decoration: _decoration('Search type'),
            dropdownColor: Colors.white,
            style: const TextStyle(color: AppColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'diary', child: Text('Diary number')),
              DropdownMenuItem(value: 'casenumber', child: Text('Case number')),
            ],
            onChanged: (v) {
              setState(() => _searchType = v ?? 'diary');
              _loadCaptcha();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _zoneType,
            decoration: _decoration('Zonal bench'),
            dropdownColor: Colors.white,
            style: const TextStyle(color: AppColors.textPrimary),
            items: _benches
                .map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!)))
                .toList(),
            onChanged: (v) => setState(() => _zoneType = v ?? '1'),
          ),
          const SizedBox(height: 12),
          if (_searchType == 'diary')
            TextField(
              controller: _diaryController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Diary number').copyWith(hintText: '330511800569'),
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _caseType,
              decoration: _decoration('Case type'),
              dropdownColor: Colors.white,
              style: const TextStyle(color: AppColors.textPrimary),
              items: _caseTypes
                  .map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!)))
                  .toList(),
              onChanged: (v) => setState(() => _caseType = v ?? '1'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caseNumberController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Case number'),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _year,
            decoration: _decoration(_searchType == 'diary' ? 'Diary year' : 'Case year'),
            dropdownColor: Colors.white,
            style: const TextStyle(color: AppColors.textPrimary),
            items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
            onChanged: (v) => setState(() => _year = v ?? _years.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _loadingCaptcha
                    ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                    : _captchaBytes == null
                        ? const Text('Captcha unavailable')
                        : Image.memory(_captchaBytes!, height: 48, fit: BoxFit.contain),
              ),
              IconButton(
                tooltip: 'Refresh captcha',
                onPressed: _loadingCaptcha ? null : _loadCaptcha,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _captchaController,
            decoration: _decoration('Enter captcha'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _searching ? null : _search,
              icon: _searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_searching ? 'Searching…' : 'Search case status'),
            ),
          ),
          SourceFooter(
            tribunal: 'NGT',
            officialUrl: _searchType == 'diary' ? TribunalSources.ngtDiaryStatus : TribunalSources.ngtCaseNumberStatus,
          ),
        ],
      ),
    );
  }
}
