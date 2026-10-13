import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:etribunals/data/services/order_summary_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> _showAiAlert(BuildContext context, Object e, {String? fallback}) {
  final msg = e is GeminiQuotaException ? e.userMessage : (fallback ?? 'Could not complete this.');
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.paper,
      title: Text(
        e is GeminiQuotaException ? 'AI limit reached' : 'AI Summarize',
        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
      ),
      content: Text(
        msg,
        style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ),
  );
}

class InAppDocumentScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool showOfficialLink;
  final Uint8List? pdfBytes;
  final String? htmlBody;

  const InAppDocumentScreen({
    super.key,
    required this.url,
    this.title = 'Document',
    this.showOfficialLink = true,
    this.pdfBytes,
    this.htmlBody,
  });

  static Future<void> open(
    BuildContext context,
    String url, {
    String title = 'Document',
    bool showOfficialLink = true,
    Uint8List? pdfBytes,
    String? htmlBody,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppDocumentScreen(
          url: url,
          title: title,
          showOfficialLink: showOfficialLink,
          pdfBytes: pdfBytes,
          htmlBody: htmlBody,
        ),
      ),
    );
  }

  @override
  State<InAppDocumentScreen> createState() => _InAppDocumentScreenState();
}

class _InAppDocumentScreenState extends State<InAppDocumentScreen> {
  WebViewController? _webController;
  Uint8List? _pdfBytes;
  String? _textBody;
  var _loading = true;
  String? _error;

  String get _barTitle {
    final t = widget.title.trim();
    final n = t.toLowerCase().replaceAll(RegExp(r'[\s_/]+'), ' ').trim();
    if (n.isEmpty ||
        n == 'download' ||
        n == 'view' ||
        n == 'view download' ||
        n == 'download details' ||
        n == 'click here') {
      return 'Document';
    }
    return t;
  }

  bool get _shouldFetchBytes {
    final url = widget.url.toLowerCase();
    return url.contains('.pdf') ||
        url.contains('/pdf') ||
        url.contains('pdf1.php') ||
        url.contains('pdfia.php') ||
        url.contains('gen_pdf') ||
        url.contains('order_view') ||
        url.contains('ordersview') ||
        url.contains('/openfilec/') ||
        url.contains('daily_causelist') ||
        url.contains('/order_files/') ||
        url.contains('/evidence_files/') ||
        url.contains('tdsat.gov.in') && url.contains('.pdf') ||
        url.contains('cis.aptel.gov.in') ||
        url.contains('aptel.gov.in') && url.contains('.pdf') ||
        url.contains('view-order/') ||
        url.contains('view-causelist/') ||
        url.contains('daily-cause-pdf') ||
        url.contains('upload_document') ||
        url.contains('103.154.2.123') ||
        url.contains('aft.gov.in') && url.contains('.pdf') ||
        url.contains('cis.drt.gov.in') ||
        url.contains('cis.cgat.gov.in') ||
        url.contains('itat.gov.in/public/files/upload') ||
        url.contains('cestat.gov.in') && url.contains('.pdf') ||
        url.contains('pdf.php') ||
        url.contains('view_daily_order') ||
        url.contains('filepath=') ||
        url.contains('path=') ||
        url.contains('file=');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.pdfBytes != null && widget.pdfBytes!.isNotEmpty) {
      setState(() {
        _pdfBytes = widget.pdfBytes;
        _loading = false;
      });
      return;
    }
    if (widget.htmlBody != null && widget.htmlBody!.trim().isNotEmpty) {
      _openHtml(widget.htmlBody!);
      return;
    }
    if (_shouldFetchBytes) {
      await _loadFetched();
      return;
    }
    _openWeb(widget.url);
  }

  Future<void> _loadFetched() async {
    setState(() {
      _loading = true;
      _error = null;
      _pdfBytes = null;
      _textBody = null;
      _webController = null;
    });
    try {
      final dio = Dio(
        BaseOptions(
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (code) => code != null && code < 500,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36',
            'Accept': 'application/pdf,text/plain,text/html,*/*',
            'Referer': widget.url.contains('cgat')
                ? 'https://cgat.gov.in/'
                : widget.url.contains('itat.gov.in')
                    ? 'https://itat.gov.in/'
                    : widget.url.contains('cestat.gov.in')
                        ? 'https://cestat.gov.in/'
                        : widget.url.contains('tdsat.gov.in')
                            ? 'https://www.tdsat.gov.in/'
                            : widget.url.contains('aptel.gov.in')
                                ? 'http://aptel.gov.in/'
                                : widget.url.contains('sat.gov.in')
                                    ? 'https://satweb.sat.gov.in/'
                                    : widget.url.contains('aft.gov.in')
                                        ? 'https://aft.gov.in/'
                                        : widget.url.contains('atfp.gov.in')
                                            ? 'https://atfp.gov.in/'
                                            : widget.url.contains('labour.gov.in')
                                                ? 'https://apps.labour.gov.in/cgit/'
                                                : 'https://drt.gov.in/',
          },
        ),
      );
      OfficialHttp.attachDio(dio);
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
      final response = await dio.get<List<int>>(
        _aftDocUrl(widget.url),
        options: Options(responseType: ResponseType.bytes),
      );
      var bytes = Uint8List.fromList(response.data ?? const []);
      var type = (response.headers.value('content-type') ?? '').toLowerCase();
      var currentUrl = response.realUri.toString();
      if (!mounted) return;

      if (response.statusCode != null && response.statusCode! >= 400) {
        setState(() {
          _loading = false;
          _error = 'Official site did not return this document (${response.statusCode}).';
        });
        return;
      }

      for (var hop = 0; hop < 3; hop++) {
        if (_isPdf(bytes) || (type.contains('application/pdf') && _isPdf(bytes))) {
          setState(() {
            _pdfBytes = bytes;
            _loading = false;
          });
          return;
        }
        final html = _asText(bytes);
        final nested = html == null ? null : _embeddedPdfUrl(html, currentUrl);
        if (nested == null) break;
        final next = await dio.get<List<int>>(
          nested,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Referer': currentUrl},
          ),
        );
        bytes = Uint8List.fromList(next.data ?? const []);
        type = (next.headers.value('content-type') ?? '').toLowerCase();
        currentUrl = next.realUri.toString();
      }

      if (_isPdf(bytes)) {
        setState(() {
          _pdfBytes = bytes;
          _loading = false;
        });
        return;
      }

      final text = _asText(bytes);

      if (text != null && _looksLikeHtml(text)) {
        if (text.toLowerCase().contains('internal server error') ||
            text.toLowerCase().contains('not found')) {
          setState(() {
            _loading = false;
            _error = 'Official site could not generate this file. Use Open official site, or try another date/court.';
          });
          return;
        }
        if (text.contains('secure-pdf-serve.php') || text.contains('qrpdfview.php') || text.contains('processPDF')) {
          setState(() {
            _loading = false;
            _error = 'Could not open this CAT PDF in-app. Use Open official site.';
          });
          return;
        }
        _openHtml(text);
        return;
      }

      if (text != null && text.trim().isNotEmpty) {
        setState(() {
          _textBody = text.trim();
          _loading = false;
        });
        return;
      }

      setState(() {
        _loading = false;
        _error = 'This link is not a readable document. Open it on the official site.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = OfficialHttp.friendly(e);
      });
    }
  }

  String _aftDocUrl(String url) {
    final file = RegExp(r'upload_document/(\d+\.pdf)', caseSensitive: false).firstMatch(url);
    if (file != null) return 'https://aft.gov.in/public/upload_document/${file.group(1)}';
    return url;
  }

  bool _isPdf(Uint8List bytes) {
    if (bytes.length < 5) return false;
    var i = 0;
    while (i < bytes.length && (bytes[i] == 0x20 || bytes[i] == 0x0A || bytes[i] == 0x0D || bytes[i] == 0x09)) {
      i++;
    }
    if (i + 4 > bytes.length) return false;
    return bytes[i] == 0x25 && bytes[i + 1] == 0x50 && bytes[i + 2] == 0x44 && bytes[i + 3] == 0x46;
  }

  String? _asText(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    try {
      final decoded = utf8.decode(bytes, allowMalformed: true);
      if (decoded.contains('\u0000')) return null;
      return decoded;
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  bool _looksLikeHtml(String text) {
    final head = text.trimLeft().toLowerCase();
    return head.startsWith('<!doctype') || head.startsWith('<html') || head.contains('<body');
  }

  String? _embeddedPdfUrl(String html, String pageUrl) {
    final match = RegExp("pdfUrl\\s*=\\s*['\"]([^'\"]+)['\"]").firstMatch(html);
    final raw = match?.group(1)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return Uri.parse(pageUrl).resolve(raw).toString();
  }

  void _openHtml(String html) {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadHtmlString(html, baseUrl: widget.url);
    setState(() => _loading = false);
  }

  void _openWeb(String url) {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
    setState(() => _loading = true);
  }

  Future<void> _openOfficial() {
    return launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
  }

  Future<void> _savePdf() async {
    final bytes = _pdfBytes;
    if (bytes == null) return;
    try {
      final downloads = await getDownloadsDirectory();
      final dir = downloads ?? await getApplicationDocumentsDirectory();
      final safe = widget.title.replaceAll(RegExp(r'[^\w.-]+'), '_').replaceAll(RegExp(r'_+'), '_');
      final file = File('${dir.path}/${safe.isEmpty ? 'document' : safe}.pdf');
      await file.writeAsBytes(bytes);
      await LocalStorageService.addOpenedFile(title: widget.title, path: file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this PDF.')));
    }
  }

  Future<void> _summarise() async {
    final bytes = _pdfBytes;
    if (bytes == null) return;
    if (!mounted) return;
    final blocked = await OrderSummaryService.quotaBlock();
    if (!mounted) return;
    if (blocked != null) {
      await _showAiAlert(context, blocked);
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppColors.paper,
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Summarising the PDF… longer files take a bit more time.',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
    try {
      final summary = await OrderSummaryService.summarise(pdfBytes: bytes, title: widget.title);
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _PdfSummaryPage(summary: summary),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _showAiAlert(context, e, fallback: _summaryError(e));
    }
  }

  String _summaryError(Object e) {
    final text = '$e';
    if (text.contains('missing_key') || text.contains('bad_key')) {
      return 'AI Summarize is temporarily unavailable. Try again later.';
    }
    if (text.contains('no_text')) {
      return 'This PDF has no selectable text (often a scan). Open the official file to read it.';
    }
    if (text.contains('timeout')) return 'AI took too long. Try a shorter PDF, or tap AI Summarize again.';
    if (text.contains('pdf_too_big')) return 'This PDF is too large to summarise.';
    if (text.contains('quota')) return 'AI tokens are used up for now. Try again in a little while.';
    if (text.contains('busy')) return 'AI is busy. Wait a minute and tap AI Summarize again.';
    if (text.contains('http_')) return 'Could not read this file. Try another PDF.';
    return 'Could not summarise this PDF. Check internet and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(_barTitle),
        actions: [
          if (_pdfBytes != null)
            TextButton.icon(
              onPressed: _summarise,
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              label: const Text(
                'AI Summarize',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          if (_pdfBytes != null)
            IconButton(
              tooltip: 'Save PDF',
              icon: const Icon(Icons.download_outlined),
              onPressed: _savePdf,
            ),
          if (widget.showOfficialLink)
            IconButton(
              tooltip: 'Open official site',
              icon: const Icon(Icons.open_in_new),
              onPressed: _openOfficial,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_pdfBytes != null)
            PdfViewer.data(_pdfBytes!, sourceName: widget.url)
          else if (_textBody != null)
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x3314384A)),
                  ),
                  child: SelectableText(
                    _textBody!,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else if (_webController != null)
            WebViewWidget(controller: _webController!)
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (widget.showOfficialLink)
                    ElevatedButton(onPressed: _openOfficial, child: const Text('Open official site')),
                ],
              ),
            )
          else
            const SizedBox.expand(),
          if (_loading) const LinearProgressIndicator(color: AppColors.accent),
        ],
      ),
    );
  }
}

class _PdfSummaryPage extends StatefulWidget {
  final PdfSummary summary;
  const _PdfSummaryPage({required this.summary});

  @override
  State<_PdfSummaryPage> createState() => _PdfSummaryPageState();
}

class _QaTurn {
  final String question;
  final String? answer;
  const _QaTurn({required this.question, this.answer});
}

class _PdfSummaryPageState extends State<_PdfSummaryPage> {
  final _ask = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_QaTurn>[];
  var _asking = false;

  PdfSummary get summary => widget.summary;

  @override
  void dispose() {
    _ask.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final q = (preset ?? _ask.text).trim();
    if (q.isEmpty || _asking) return;
    final blocked = await OrderSummaryService.quotaBlock();
    if (!mounted) return;
    if (blocked != null) {
      await _showAiAlert(context, blocked);
      return;
    }
    setState(() {
      _asking = true;
      _turns.add(_QaTurn(question: q));
      _ask.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
    try {
      final answer = await OrderSummaryService.askFollowUp(question: q, briefing: summary.shareText);
      if (!mounted) return;
      setState(() {
        _turns[_turns.length - 1] = _QaTurn(question: q, answer: answer);
        _asking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _asking = false);
      if (e is GeminiQuotaException) {
        setState(() => _turns.removeLast());
        await _showAiAlert(context, e);
        return;
      }
      setState(() {
        _turns[_turns.length - 1] = _QaTurn(
          question: q,
          answer: 'Could not answer. Try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('AI Summarize'),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () => Share.share(summary.shareText),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              children: [
                _summaryCard(),
                const SizedBox(height: 14),
                const Text(
                  'Ask about this order',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: AppColors.stampBlue),
                ),
                const SizedBox(height: 8),
                if (_turns.isEmpty)
                  const Text(
                    'Held, next listing, relief, costs — only from this PDF.',
                    style: TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                for (final turn in _turns) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(turn.question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.35)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x3314384A)),
                      ),
                      child: turn.answer == null
                          ? const Text('Looking in this order…', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted))
                          : SelectableText(
                              turn.answer!,
                              style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: AppColors.paper,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_turns.isEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final chip in const ['What was held?', 'Next listing?', 'Relief / costs?'])
                            ActionChip(
                              label: Text(chip, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: _asking ? null : () => _send(chip),
                              backgroundColor: AppColors.tile,
                              side: BorderSide.none,
                            ),
                        ],
                      ),
                    if (_turns.isEmpty) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ask,
                            enabled: !_asking,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText: 'Ask about this case…',
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.secondary,
                              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ask',
                          onPressed: _asking ? null : () => _send(),
                          icon: Icon(_asking ? Icons.hourglass_top : Icons.send, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x3314384A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary.kind.isEmpty ? 'Document' : summary.kind,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: AppColors.accent),
                ),
              ),
              Text(
                summary.pages > 0 ? '${summary.pages} page${summary.pages == 1 ? '' : 's'}' : 'PDF',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
          if (summary.headline.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(
              summary.headline,
              style: const TextStyle(fontSize: 17, height: 1.35, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ],
          if (summary.facts.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel('This order'),
            const SizedBox(height: 10),
            for (final fact in summary.facts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 108,
                      child: Text(
                        fact.key,
                        style: const TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        fact.value,
                        style: const TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (summary.highlights.isNotEmpty) ...[
            const SizedBox(height: 8),
            _sectionLabel('What matters'),
            const SizedBox(height: 10),
            for (final point in summary.highlights) _bullet(point, accent: true),
          ],
          for (final section in summary.sections) ...[
            const SizedBox(height: 10),
            _sectionLabel(section.title),
            const SizedBox(height: 10),
            for (final point in section.bullets) _bullet(point),
          ],
          const SizedBox(height: 16),
          const Text(
            'AI draft · not legal advice · verify on the official PDF',
            style: TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.stampBlue),
    );
  }

  Widget _bullet(String text, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6, color: accent ? AppColors.accent : AppColors.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
