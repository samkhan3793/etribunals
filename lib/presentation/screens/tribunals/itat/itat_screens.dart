import 'dart:typed_data';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/itat_client.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/itat/itat_case_details_screen.dart';
import 'package:flutter/material.dart';

class ItatCaseStatusScreen extends StatefulWidget {
  const ItatCaseStatusScreen({super.key});

  @override
  State<ItatCaseStatusScreen> createState() => _ItatCaseStatusScreenState();
}

class _ItatCaseStatusScreenState extends State<ItatCaseStatusScreen> {
  final _appeal = TextEditingController();
  final _assessee = TextEditingController();
  final _ack = TextEditingController();
  final _captcha = TextEditingController();
  String _mode = 'appeal';
  String _bench = '201';
  String _type = 'ITA';
  late String _year;
  DateTime _filed = DateTime.now();
  Uint8List? _captchaBytes;
  bool _loadingCaptcha = true;
  bool _searching = false;

  final _years = List.generate(80, (i) => '${DateTime.now().year - i}');

  @override
  void initState() {
    super.initState();
    _year = _years.first;
    _refreshCaptcha();
  }

  @override
  void dispose() {
    _appeal.dispose();
    _assessee.dispose();
    _ack.dispose();
    _captcha.dispose();
    super.dispose();
  }

  Future<void> _refreshCaptcha() async {
    setState(() => _loadingCaptcha = true);
    try {
      final bytes = await ItatClient.instance.loadCaptcha();
      if (!mounted) return;
      setState(() {
        _captchaBytes = bytes;
        _loadingCaptcha = false;
        _captcha.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCaptcha = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    }
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    try {
      final rows = await ItatClient.instance.searchCaseStatus(
        mode: _mode,
        benchId: _bench,
        appealType: _type,
        captcha: _captcha.text,
        appealNo: _appeal.text,
        year: _year,
        filingDate: ItatClient.instance.dateLabel(_filed),
        assessee: _assessee.text,
        ack: _ack.text,
      );
      if (!mounted) return;
      await _openItatResults(context, rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    } finally {
      if (mounted) {
        setState(() => _searching = false);
        _refreshCaptcha();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('ITAT case status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Search public case',
            subtitle: 'itat.gov.in  ·  captcha required  ·  appeal, filing date, assessee or ack no.',
            color: Color(0xFF1A4A3A),
            icon: Icons.search,
          ),
          const SizedBox(height: 14),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Bench'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _bench,
                items: ItatClient.benches.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _bench = v ?? _bench),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Appeal type'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _type,
                items: ItatClient.appealTypes.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _chip('appeal', 'Appeal no.'),
              _chip('date', 'Date of filing'),
              _chip('assessee', 'Assessee'),
              _chip('ack', 'Ack. no.'),
            ],
          ),
          const SizedBox(height: 12),
          if (_mode == 'appeal') ...[
            TextField(controller: _appeal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Appeal number (serial only)')),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Filing year (must match official site)'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _year,
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _year = v ?? _year),
                ),
              ),
            ),
          ] else if (_mode == 'date')
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date of filing'),
              subtitle: Text(ItatClient.instance.dateLabel(_filed)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final next = await showDatePicker(context: context, initialDate: _filed, firstDate: DateTime(1990), lastDate: DateTime.now());
                if (next != null) setState(() => _filed = next);
              },
            )
          else if (_mode == 'assessee')
            TextField(controller: _assessee, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Assessee name'))
          else
            TextField(controller: _ack, decoration: const InputDecoration(labelText: 'Acknowledgement number')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _captcha,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Captcha',
                    hintText: '6 characters from image',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _refreshCaptcha,
                child: SizedBox(
                  height: 48,
                  width: 120,
                  child: _loadingCaptcha
                      ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                      : _captchaBytes == null
                          ? const Icon(Icons.refresh)
                          : Image.memory(_captchaBytes!, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
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
          const SourceFooter(tribunal: 'ITAT', officialUrl: ItatClient.caseStatusUrl, showOfficialLink: false),
        ],
      ),
    );
  }

  Widget _chip(String id, String label) {
    return ChoiceChip(label: Text(label), selected: _mode == id, onSelected: (_) => setState(() => _mode = id));
  }
}

Future<void> _openItatResults(BuildContext context, List<ItatCaseRecord> rows) async {
  if (rows.length == 1) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ItatCaseDetailsScreen(record: rows.first)));
    return;
  }
  await Navigator.push(context, MaterialPageRoute(builder: (_) => _ItatHitsScreen(rows: rows)));
}

class _ItatHitsScreen extends StatelessWidget {
  final List<ItatCaseRecord> rows;
  const _ItatHitsScreen({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${rows.length} results')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final r = rows[i];
          return Card(
            color: AppColors.paper,
            child: ListTile(
              title: Text(r.appealNo, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                [
                  if (r.title != r.appealNo) r.title,
                  if (r.status.isNotEmpty) r.status,
                  if (r.nextDate.isNotEmpty) 'Next: ${r.nextDate}',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItatCaseDetailsScreen(record: r))),
            ),
          );
        },
      ),
    );
  }
}

class ItatOrdersScreen extends StatefulWidget {
  const ItatOrdersScreen({super.key});

  @override
  State<ItatOrdersScreen> createState() => _ItatOrdersScreenState();
}

class _ItatOrdersScreenState extends State<ItatOrdersScreen> {
  final _appeal = TextEditingController();
  final _member = TextEditingController();
  final _captcha = TextEditingController();
  String _mode = 'appeal';
  String _bench = '201';
  String _type = 'ITA';
  late String _year;
  DateTime _date = DateTime.now();
  Uint8List? _captchaBytes;
  bool _loadingCaptcha = true;
  bool _searching = false;
  final _years = List.generate(80, (i) => '${DateTime.now().year - i}');

  @override
  void initState() {
    super.initState();
    _year = _years.first;
    _refreshCaptcha();
  }

  @override
  void dispose() {
    _appeal.dispose();
    _member.dispose();
    _captcha.dispose();
    super.dispose();
  }

  Future<void> _refreshCaptcha() async {
    setState(() => _loadingCaptcha = true);
    try {
      final bytes = await ItatClient.instance.loadCaptcha();
      if (!mounted) return;
      setState(() {
        _captchaBytes = bytes;
        _loadingCaptcha = false;
        _captcha.clear();
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCaptcha = false);
    }
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    try {
      final rows = await ItatClient.instance.searchTribunalOrders(
        mode: _mode,
        benchId: _bench,
        appealType: _type,
        captcha: _captcha.text,
        appealNo: _appeal.text,
        year: _year,
        orderDate: ItatClient.instance.dateLabel(_date),
        member: _member.text,
      );
      if (!mounted) return;
      await _openItatResults(context, rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''))));
    } finally {
      if (mounted) {
        setState(() => _searching = false);
        _refreshCaptcha();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('ITAT tribunal orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Tribunal orders',
            subtitle: 'itat.gov.in  ·  captcha required  ·  appeal, order date or member',
            color: Color(0xFF1A4A3A),
            icon: Icons.gavel,
          ),
          const SizedBox(height: 14),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Bench'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _bench,
                items: ItatClient.benches.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _bench = v ?? _bench),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Appeal type'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _type,
                items: ItatClient.appealTypes.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Appeal no.'), selected: _mode == 'appeal', onSelected: (_) => setState(() => _mode = 'appeal')),
              ChoiceChip(label: const Text('Order date'), selected: _mode == 'date', onSelected: (_) => setState(() => _mode = 'date')),
              ChoiceChip(label: const Text('Member'), selected: _mode == 'member', onSelected: (_) => setState(() => _mode = 'member')),
            ],
          ),
          const SizedBox(height: 12),
          if (_mode == 'appeal') ...[
            TextField(controller: _appeal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Appeal number')),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Year'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _year,
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _year = v ?? _year),
                ),
              ),
            ),
          ] else if (_mode == 'date')
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Order / pronouncement date'),
              subtitle: Text(ItatClient.instance.dateLabel(_date)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final next = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1990), lastDate: DateTime.now());
                if (next != null) setState(() => _date = next);
              },
            )
          else
            TextField(controller: _member, decoration: const InputDecoration(labelText: 'Member name')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _captcha,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Captcha',
                    hintText: '6 characters from image',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _refreshCaptcha,
                child: SizedBox(
                  height: 48,
                  width: 120,
                  child: _loadingCaptcha
                      ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                      : _captchaBytes == null
                          ? const Icon(Icons.refresh)
                          : Image.memory(_captchaBytes!, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _searching ? null : _search,
              child: _searching
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search orders'),
            ),
          ),
          const SourceFooter(tribunal: 'ITAT', officialUrl: ItatClient.ordersUrl, showOfficialLink: false),
        ],
      ),
    );
  }
}

class ItatListingScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String officialUrl;
  final Future<List<ItatDoc>> Function() loader;

  const ItatListingScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.officialUrl,
    required this.loader,
  });

  @override
  State<ItatListingScreen> createState() => _ItatListingScreenState();
}

class _ItatListingScreenState extends State<ItatListingScreen> {
  final _q = TextEditingController();
  List<ItatDoc> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.loader();
      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final rows = q.isEmpty ? _all : _all.where((e) => '${e.title} ${e.extra} ${e.date}'.toLowerCase().contains(q)).toList();
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CourtBand(title: widget.title, subtitle: widget.subtitle, color: const Color(0xFF1A4A3A), icon: Icons.campaign_outlined),
            const SizedBox(height: 12),
            TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filter by bench or title'),
            ),
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 24), child: Text(_error!, style: const TextStyle(color: AppColors.stampRed)))
            else
              ...rows.map(
                (doc) => Card(
                  color: AppColors.paper,
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accent),
                    title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([if (doc.extra.isNotEmpty) doc.extra, doc.date].where((e) => e.isNotEmpty).join(' · ')),
                    onTap: () => InAppDocumentScreen.open(context, doc.url, title: widget.title),
                  ),
                ),
              ),
            SourceFooter(tribunal: 'ITAT', officialUrl: widget.officialUrl, showOfficialLink: false),
          ],
        ),
      ),
    );
  }
}
