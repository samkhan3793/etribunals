import 'dart:typed_data';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/utils/ngt_case_client.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/judgements/ngt_judgement_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NgtJudgementSearchScreen extends StatefulWidget {
  const NgtJudgementSearchScreen({super.key});

  @override
  State<NgtJudgementSearchScreen> createState() => _NgtJudgementSearchScreenState();
}

class _NgtJudgementSearchScreenState extends State<NgtJudgementSearchScreen> {
  final _captchaController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fmt = DateFormat('dd/MM/yyyy');

  String _zoneType = '1';
  String _orderBy = '1';
  Uint8List? _captchaBytes;
  bool _loadingCaptcha = true;
  bool _searching = false;

  static const _benches = [
    {'value': '1', 'label': 'Principal Bench (Delhi)'},
    {'value': '2', 'label': 'Eastern Zone (Kolkata)'},
    {'value': '3', 'label': 'Central Zone (Bhopal)'},
    {'value': '4', 'label': 'Western Zone (Pune)'},
    {'value': '5', 'label': 'Southern Zone (Chennai)'},
  ];

  static const _orderByItems = [
    {'value': '1', 'label': 'Order date'},
    {'value': '2', 'label': 'Uploading date'},
    {'value': '3', 'label': 'Both'},
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toController.text = _fmt.format(now);
    _fromController.text = _fmt.format(now.subtract(const Duration(days: 7)));
    _loadCaptcha();
  }

  @override
  void dispose() {
    _captchaController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _loadCaptcha() async {
    setState(() => _loadingCaptcha = true);
    try {
      final bytes = await NgtCaseClient.instance.loadCaptcha(sessionUrl: NgtCaseClient.judgementFormUrl);
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

  Future<void> _pickDate(TextEditingController controller) async {
    final parsed = _fmt.parseLoose(controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) controller.text = _fmt.format(picked);
  }

  Future<void> _search() async {
    final captcha = _captchaController.text.trim();
    if (captcha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter captcha')));
      return;
    }
    setState(() => _searching = true);
    try {
      final page = await NgtCaseClient.instance.searchJudgements(
        zoneType: _zoneType,
        fromDate: _fromController.text,
        toDate: _toController.text,
        orderBy: _orderBy,
        captcha: captcha,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NgtJudgementResultsScreen(
            rows: page.rows,
            hasMore: page.hasMore,
            zoneType: _zoneType,
            fromDate: _fromController.text,
            toDate: _toController.text,
            orderBy: _orderBy,
            captcha: captcha,
          ),
        ),
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
      appBar: AppBar(title: const Text('NGT judgements')),
      backgroundColor: AppColors.secondary,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Search uses the official NGT zonal-bench judgements form. Results open in the app, not the full website.',
            style: TextStyle(color: AppColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromController,
                  readOnly: true,
                  decoration: _decoration('From date'),
                  onTap: () => _pickDate(_fromController),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _toController,
                  readOnly: true,
                  decoration: _decoration('To date'),
                  onTap: () => _pickDate(_toController),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _orderBy,
            decoration: _decoration('Search by'),
            dropdownColor: Colors.white,
            style: const TextStyle(color: AppColors.textPrimary),
            items: _orderByItems
                .map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!)))
                .toList(),
            onChanged: (v) => setState(() => _orderBy = v ?? '1'),
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
          TextField(controller: _captchaController, decoration: _decoration('Enter captcha')),
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
              label: Text(_searching ? 'Searching…' : 'Search judgements'),
            ),
          ),
          SourceFooter(tribunal: 'NGT', officialUrl: TribunalSources.ngtJudgements),
        ],
      ),
    );
  }
}
