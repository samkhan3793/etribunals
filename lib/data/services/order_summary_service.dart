import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:etribunals/core/constants/app_ai.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';

class GeminiQuotaException implements Exception {
  final Duration wait;
  GeminiQuotaException(this.wait);

  String get userMessage {
    final pretty = formatWait(wait);
    return 'AI tokens are used up for now. You can use AI Summarize again in $pretty.';
  }

  static String formatWait(Duration wait) {
    final d = wait < Duration.zero ? Duration.zero : wait;
    if (d.inSeconds < 45) return 'less than a minute';
    if (d.inMinutes < 2) return 'about 1 minute';
    if (d.inMinutes < 90) return '${d.inMinutes} minutes';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h < 36) {
      if (m < 5) return h == 1 ? '1 hour' : '$h hours';
      return h == 1 ? '1 hour $m minutes' : '$h hours $m minutes';
    }
    return '${(h / 24).ceil()} days';
  }

  @override
  String toString() => 'quota:${wait.inSeconds}';
}

class PdfSummary {
  final String headline;
  final String kind;
  final List<MapEntry<String, String>> facts;
  final List<String> highlights;
  final List<PdfSummarySection> sections;
  final String raw;
  final int pages;
  final int wordLimit;

  const PdfSummary({
    required this.headline,
    required this.kind,
    required this.facts,
    required this.highlights,
    required this.sections,
    required this.raw,
    this.pages = 0,
    this.wordLimit = 1000,
  });

  String get shareText {
    final buf = StringBuffer();
    if (headline.isNotEmpty) buf.writeln(headline);
    if (kind.isNotEmpty) buf.writeln(kind);
    buf.writeln();
    for (final h in highlights) {
      buf.writeln('• $h');
    }
    for (final s in sections) {
      buf.writeln();
      buf.writeln(s.title);
      for (final b in s.bullets) {
        buf.writeln('• $b');
      }
    }
    buf.writeln();
    buf.writeln('AI draft. Verify on the official PDF. Shared from eTribunals.');
    return buf.toString().trim();
  }
}

class PdfSummarySection {
  final String title;
  final List<String> bullets;
  const PdfSummarySection({required this.title, required this.bullets});
}

class OrderSummaryService {
  static const _models = ['gemini-3.5-flash', 'gemini-3.6-flash'];
  static const _maxPdfBytes = 15 * 1024 * 1024;

  static Future<PdfSummary> summarise({
    required Uint8List pdfBytes,
    required String title,
  }) async {
    final key = AppAi.geminiKey;
    await _throwIfQuotaWait();
    if (pdfBytes.length > _maxPdfBytes) {
      throw StateError('pdf_too_big');
    }
    final pages = await _pageTexts(pdfBytes);
    final pageCount = pages.isEmpty ? 1 : pages.length;
    final wordLimit = _autoLimit(pageCount);
    final tokens = math.min(8192, math.max(1800, wordLimit * 2));
    final joined = pages.join('\n\n');
    String raw;
    if (pageCount > 6 && joined.replaceAll(RegExp(r'\s+'), '').length > 800) {
      raw = await _summariseByChunks(key, title, pages, wordLimit, tokens);
    } else {
      raw = await _ask(
        key,
        _finalPrompt(title, pageCount, wordLimit),
        pdfBytes: pdfBytes,
        tokens: tokens,
      );
    }
    return capWords(
      parse(raw, pages: pageCount, wordLimit: wordLimit),
      wordLimit,
    );
  }

  static int _autoLimit(int pages) => (pages * 220).clamp(900, 4500).toInt();

  static Future<GeminiQuotaException?> quotaBlock() async {
    try {
      await _throwIfQuotaWait();
      return null;
    } on GeminiQuotaException catch (e) {
      return e;
    }
  }

  static String _finalPrompt(String title, int pages, int wordLimit) {
    return '''You are reading an Indian tribunal / appellate PDF (NCLAT, NCLT, DRT, CAT, ITAT, CESTAT, NCDRC, etc.).
The reader already searched the case. They already know the case number and case title. Do NOT spend bullets on repeating case no., diary no., or the full cause title.

Think like someone trained on Indian tribunal practice. Extract what a lawyer or party actually needs from THIS order/judgement/list:

Read the FULL PDF. Do not skip later pages, numbered paragraphs, operative portion, or annexure directions.

Return JSON only:
{
  "headline": "the legal outcome in one line (allowed / dismissed / remanded / listed / stayed — not the case name)",
  "kind": "Order | Judgement | Cause list | Notice | Circular | Document",
  "facts": [{"label": "Result", "value": "dismissed / allowed / remanded / …"}],
  "highlights": ["operative or holding point"],
  "sections": [{"title": "Held", "bullets": ["point"]}]
}

facts — only order-specific fields, max 6, omit if absent. Allowed labels: Result, Coram, Order date, Next listing, Costs, Relief, IA / MA. Never Case no., Title, Parties, Tribunal, Bench name.

highlights — 6–14 bullets of substance, in this priority:
1. Operative directions (what the tribunal ordered)
2. Held / findings on issues
3. Issues framed if they drove the result
4. Relief granted or refused
5. Interim vs final; stay; deposit; limitation / condonation
6. Costs; liberty to restore / revive; time to comply
7. Next listing / stage only if it is a listing order
Do not highlight case number or case title.

sections — use headings a tribunal reader expects, only if content exists: Issues, Held, Operative portion, Directions to parties, Costs & liberty, Listing. All remaining important points as bullets. Exact dates, amounts, and names of directions. No invented law.

No filler, no legal advice, no predicting appeal chances, no repeating the caption.
Combined words of headline + highlights + bullets ≤ $wordLimit.
Pages: $pages. File name (not a caption to repeat): $title
JSON only.''';
  }

  static String _chunkPrompt(String title, int from, int to, int pages) {
    return '''Indian tribunal PDF "$title", pages $from–$to of $pages.
The reader already knows the case number and title. Do not list case no. or cause title.

Extract EVERY legally material point from THIS RANGE as JSON:
{"points":["operative/held/direction/amount/date/issue — exact from the PDF"]}
Skip captions, appearances unless they affect the result, and repeating the case name.
Do not invent. JSON only.''';
  }

  static Future<String> _summariseByChunks(
    String key,
    String title,
    List<String> pages,
    int wordLimit,
    int tokens,
  ) async {
    const size = 4;
    final allPoints = <String>[];
    for (var i = 0; i < pages.length; i += size) {
      final end = math.min(i + size, pages.length);
      final chunk = pages.sublist(i, end).join('\n\n');
      if (chunk.trim().length < 30) continue;
      final raw = await _ask(
        key,
        '${_chunkPrompt(title, i + 1, end, pages.length)}\n\n$chunk',
        tokens: math.min(4096, tokens),
      );
      allPoints.addAll(_pointsFrom(raw));
    }
    if (allPoints.isEmpty) {
      return _ask(key, _finalPrompt(title, pages.length, wordLimit), tokens: tokens);
    }
    final unique = <String>[];
    final seen = <String>{};
    for (final p in allPoints) {
      final k = p.toLowerCase();
      if (seen.contains(k)) continue;
      seen.add(k);
      unique.add(p);
    }
    return _ask(
      key,
      '''${_finalPrompt(title, pages.length, wordLimit)}

These points were extracted page-by-page. Keep ALL of them (merge duplicates only). Organise into highlights + sections. Do not drop later-page points.

${unique.map((e) => '• $e').join('\n')}''',
      tokens: tokens,
    );
  }

  static List<String> _pointsFrom(String raw) {
    try {
      final map = jsonDecode(_jsonObject(raw)) as Map<String, dynamic>;
      return (map['points'] as List<dynamic>? ?? const []).map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      return raw.split('\n').map((e) => e.replaceFirst(RegExp(r'^[\s•\-\d.]+'), '').trim()).where((e) => e.length > 8).toList();
    }
  }

  static String _jsonObject(String raw) {
    var text = raw.trim().replaceAll(RegExp(r'^```(?:json)?', multiLine: true), '').replaceAll(RegExp(r'```$'), '');
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) return text.substring(start, end + 1);
    return text;
  }

  static PdfSummary parse(String raw, {int pages = 0, int wordLimit = 1000}) {
    try {
      final map = jsonDecode(_jsonObject(raw)) as Map<String, dynamic>;
      final facts = <MapEntry<String, String>>[];
      for (final item in map['facts'] as List<dynamic>? ?? const []) {
        if (item is! Map) continue;
        final label = '${item['label'] ?? ''}'.trim();
        final value = '${item['value'] ?? ''}'.trim();
        if (label.isEmpty || value.isEmpty) continue;
        if (_isCaptionField(label)) continue;
        facts.add(MapEntry(label, value));
      }
      final highlights = (map['highlights'] as List<dynamic>? ?? const [])
          .map((e) => '$e'.trim())
          .where((e) => e.isNotEmpty && !_isCaptionBullet(e))
          .toList();
      final sections = <PdfSummarySection>[];
      for (final item in map['sections'] as List<dynamic>? ?? const []) {
        if (item is! Map) continue;
        final title = '${item['title'] ?? ''}'.trim();
        final bullets = _readBullets(item).where((e) => !_isCaptionBullet(e)).toList();
        if (bullets.isEmpty) continue;
        if (_isCaptionField(title)) continue;
        sections.add(PdfSummarySection(title: title.isEmpty ? 'Points' : title, bullets: bullets));
      }
      return PdfSummary(
        headline: '${map['headline'] ?? ''}'.trim(),
        kind: '${map['kind'] ?? ''}'.trim(),
        facts: facts.take(6).toList(),
        highlights: highlights,
        sections: sections.isEmpty
            ? [PdfSummarySection(title: 'Points', bullets: highlights.isEmpty ? [raw] : highlights)]
            : sections,
        raw: raw,
        pages: pages,
        wordLimit: wordLimit,
      );
    } catch (_) {
      return PdfSummary(
        headline: '',
        kind: 'Document',
        facts: const [],
        highlights: const [],
        sections: [PdfSummarySection(title: 'Points', bullets: [raw])],
        raw: raw,
        pages: pages,
        wordLimit: wordLimit,
      );
    }
  }

  static bool _isCaptionField(String label) {
    final t = label.toLowerCase();
    return t.contains('case no') ||
        t.contains('case number') ||
        t.contains('diary') ||
        t.contains('filing no') ||
        t == 'title' ||
        t.contains('cause title') ||
        t.contains('case title') ||
        t.contains('parties') ||
        t.contains('appellant') ||
        t.contains('respondent') ||
        t.contains('tribunal') ||
        t.contains('forum') ||
        (t.contains('bench') && !t.contains('coram'));
  }

  static bool _isCaptionBullet(String text) {
    final t = text.toLowerCase();
    if (t.contains('case no') || t.contains('diary no') || t.contains('titled as') || t.contains('cause title')) {
      return true;
    }
    if (RegExp(r'^(case|appeal|oa|cp|ia|company appeal)[\s:].{0,80}$', caseSensitive: false).hasMatch(text.trim()) &&
        !t.contains('dismiss') &&
        !t.contains('allow') &&
        !t.contains('remand') &&
        !t.contains('stay') &&
        !t.contains('list')) {
      return true;
    }
    return false;
  }

  static List<String> _readBullets(Map item) {
    final fromList = (item['bullets'] as List<dynamic>? ?? const []).map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
    if (fromList.isNotEmpty) return fromList;
    final body = '${item['body'] ?? ''}'.trim();
    if (body.isEmpty) return const [];
    return body
        .split(RegExp(r'\n+'))
        .map((e) => e.replaceFirst(RegExp(r'^[\s•\-]+'), '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static PdfSummary capWords(PdfSummary summary, int max) {
    var used = _wordCount(summary.headline);
    final highlights = <String>[];
    for (final item in summary.highlights) {
      final w = _wordCount(item);
      if (used + w > max) break;
      highlights.add(item);
      used += w;
    }
    final sections = <PdfSummarySection>[];
    for (final section in summary.sections) {
      final kept = <String>[];
      var titleCounted = false;
      for (final bullet in section.bullets) {
        final extra = _wordCount(bullet) + (titleCounted ? 0 : _wordCount(section.title));
        if (used + extra > max) {
          if (kept.isEmpty && !titleCounted) {
            final remain = max - used - _wordCount(section.title);
            if (remain >= 8) {
              kept.add(_firstWords(bullet, remain));
              used = max;
            }
          }
          break;
        }
        if (!titleCounted) {
          used += _wordCount(section.title);
          titleCounted = true;
        }
        kept.add(bullet);
        used += _wordCount(bullet);
      }
      if (kept.isNotEmpty) {
        sections.add(PdfSummarySection(title: section.title, bullets: kept));
      }
      if (used >= max) break;
    }
    return PdfSummary(
      headline: summary.headline,
      kind: summary.kind,
      facts: summary.facts,
      highlights: highlights,
      sections: sections,
      raw: summary.raw,
      pages: summary.pages,
      wordLimit: max,
    );
  }

  static int _wordCount(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  static String _firstWords(String text, int n) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= n) return text.trim();
    return '${words.take(n).join(' ')}…';
  }

  static Future<List<String>> _pageTexts(Uint8List bytes) async {
    try {
      final doc = await PdfDocument.openData(bytes, sourceName: 'doc.pdf', useProgressiveLoading: false);
      try {
        final out = <String>[];
        for (final page in doc.pages) {
          final text = (await page.loadText()).fullText.trim();
          out.add(text.isEmpty ? '' : '--- page ${page.pageNumber} ---\n$text');
        }
        return out;
      } finally {
        await doc.dispose();
      }
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _throwIfQuotaWait() async {
    final until = await LocalStorageService.aiRetryUntil();
    if (until == null) return;
    final left = until.difference(DateTime.now());
    if (left.inSeconds <= 0) {
      await LocalStorageService.clearAiRetry();
      return;
    }
    throw GeminiQuotaException(left);
  }

  static Duration _waitFromQuota(http.Response res) {
    final header = res.headers['retry-after'] ?? res.headers['Retry-After'];
    final fromHeader = _parseRetryAfter(header);
    if (fromHeader != null) return fromHeader;
    try {
      final map = jsonDecode(res.body);
      if (map is Map) {
        final err = map['error'];
        if (err is Map) {
          final details = err['details'];
          if (details is List) {
            for (final item in details) {
              if (item is! Map) continue;
              final delay = item['retryDelay']?.toString();
              final parsed = _parseRetryDelay(delay);
              if (parsed != null) return parsed;
            }
          }
          final msg = '${err['message'] ?? ''}'.toLowerCase();
          if (msg.contains('per day') || msg.contains('daily') || msg.contains('quota metric')) {
            return const Duration(hours: 24);
          }
        }
      }
    } catch (_) {}
    final body = res.body.toLowerCase();
    if (body.contains('perday') || body.contains('per_day') || body.contains('rpd')) {
      return const Duration(hours: 24);
    }
    return const Duration(minutes: 1);
  }

  static Duration? _parseRetryAfter(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final secs = int.tryParse(raw.trim());
    if (secs != null && secs > 0) return Duration(seconds: secs);
    try {
      final when = DateTime.parse(raw).toLocal();
      final left = when.difference(DateTime.now());
      if (left.inSeconds > 0) return left;
    } catch (_) {}
    return null;
  }

  static Duration? _parseRetryDelay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim().toLowerCase();
    final match = RegExp(r'^(\d+(?:\.\d+)?)(s|m|h|ms)?$').firstMatch(t);
    if (match == null) return _parseRetryAfter(raw);
    final n = double.tryParse(match.group(1)!) ?? 0;
    if (n <= 0) return null;
    switch (match.group(2)) {
      case 'h':
        return Duration(milliseconds: (n * 3600000).round());
      case 'm':
        return Duration(milliseconds: (n * 60000).round());
      case 'ms':
        return Duration(milliseconds: n.round());
      default:
        return Duration(milliseconds: (n * 1000).round());
    }
  }

  static Future<String> _ask(
    String key,
    String prompt, {
    Uint8List? pdfBytes,
    required int tokens,
    bool json = true,
  }) async {
    Object? last;
    for (final model in _models) {
      final body = pdfBytes == null
          ? _textBody(prompt, tokens, json: json)
          : _pdfBody(prompt, pdfBytes, tokens);
      final hit = await _post(key, model, body);
      if (hit.isOk) return hit.text;
      if (hit.fatal != null) throw StateError(hit.fatal!);
      last = hit.last;
    }
    if (pdfBytes != null) {
      return _ask(key, prompt, tokens: tokens, json: json);
    }
    throw StateError(last == 'busy' ? 'busy' : 'gemini_failed:$last');
  }

  static Future<({bool isOk, String text, String? fatal, String last})> _post(
    String key,
    String model,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
        {'key': key},
      );
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 55));
      if (res.statusCode == 429) {
        final wait = _waitFromQuota(res);
        final until = DateTime.now().add(wait);
        await LocalStorageService.setAiRetryUntil(until);
        throw GeminiQuotaException(wait);
      }
      if (res.statusCode == 403 || (res.statusCode == 400 && res.body.toUpperCase().contains('API_KEY'))) {
        return (isOk: false, text: '', fatal: 'bad_key', last: 'bad_key');
      }
      if (res.statusCode == 503) {
        return (isOk: false, text: '', fatal: null, last: 'busy');
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return (isOk: false, text: '', fatal: null, last: 'http_${res.statusCode}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = map['candidates'] as List<dynamic>? ?? const [];
      if (candidates.isEmpty) {
        return (isOk: false, text: '', fatal: null, last: 'empty');
      }
      final content = candidates.first as Map<String, dynamic>;
      final parts = (content['content'] as Map<String, dynamic>?)?['parts'] as List<dynamic>? ?? const [];
      final text = parts.map((e) => e is Map ? '${e['text'] ?? ''}' : '').join().trim();
      if (text.isEmpty) {
        return (isOk: false, text: '', fatal: null, last: 'blank');
      }
      return (isOk: true, text: text, fatal: null, last: 'ok');
    } on TimeoutException {
      return (isOk: false, text: '', fatal: null, last: 'timeout');
    } catch (e) {
      return (isOk: false, text: '', fatal: null, last: '$e');
    }
  }

  static Map<String, dynamic> _pdfBody(String prompt, Uint8List pdfBytes, int tokens) {
    return {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'application/pdf',
                'data': base64Encode(pdfBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': _config(tokens),
    };
  }

  static Future<String> askFollowUp({
    required String question,
    required String briefing,
  }) async {
    final key = AppAi.geminiKey;
    await _throwIfQuotaWait();
    final q = question.trim();
    if (q.isEmpty) {
      throw StateError('empty_question');
    }
    final brief = briefing.trim();
    final cut = brief.length > 7000 ? brief.substring(0, 7000) : brief;
    return _ask(
      key,
      '''You are trained on Indian tribunal practice (NCLAT, NCLT, DRT, CAT, ITAT, CESTAT, NCDRC, etc.).
The reader already has this order/judgement. Answer their question from THIS briefing only.

BRIEFING:
$cut

QUESTION:
$q

Rules:
- Held, operative directions, listing, costs, relief — only if in the briefing.
- If it is not in the briefing, say: This summary does not say.
- No legal advice, no predicting appeal, no invented case law.
- 2 to 8 short sentences. Plain text only.''',
      tokens: 900,
      json: false,
    );
  }

  static Map<String, dynamic> _textBody(String prompt, int tokens, {bool json = true}) {
    return {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': _config(tokens, json: json),
    };
  }

  static Map<String, dynamic> _config(int tokens, {bool json = true}) => {
        'temperature': 0.1,
        'maxOutputTokens': tokens,
        'thinkingConfig': {'thinkingBudget': 0},
        if (json) 'responseMimeType': 'application/json',
      };
}
