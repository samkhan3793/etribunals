class BookmarkedCase {
  final String id;
  final String tribunal;
  final String filingNo;
  final String caseNo;
  final String title;
  final String? nextHearing;
  final int savedAt;
  final String? payloadKind;
  final String? payload;
  final String? sourceUrl;
  final String? previousNextHearing;
  final bool listingChanged;
  final int? lastCheckedAt;

  const BookmarkedCase({
    required this.id,
    required this.tribunal,
    required this.filingNo,
    required this.caseNo,
    required this.title,
    this.nextHearing,
    required this.savedAt,
    this.payloadKind,
    this.payload,
    this.sourceUrl,
    this.previousNextHearing,
    this.listingChanged = false,
    this.lastCheckedAt,
  });

  String get searchRoute {
    switch (tribunal.toUpperCase()) {
      case 'NCLT':
        return '/nclt/track-case-status';
      case 'UPREAT':
        return '/upreat/track-case-status';
      case 'NGT':
        return '/ngt/track-case-status';
      case 'RCT':
        return '/rct/track-case-status';
      case 'DRT':
        return '/drt/case-details';
      case 'CAT':
        return '/cat/case-status';
      case 'ITAT':
        return '/itat/case-status';
      case 'CESTAT':
        return '/cestat/case-details';
      case 'TDSAT':
        return '/tdsat/case-status';
      case 'APTEL':
        return '/aptel/case-status';
      case 'SAT':
        return '/sat/case-status';
      case 'AFT':
        return '/aft/case-status';
      case 'NCDRC':
        return '/ncdrc/case-status';
      case 'ATFP':
        return '/atfp/orders';
      case 'CGIT':
        return '/cgit/cause-list';
      default:
        return '/nclat/track-case-status';
    }
  }

  String get tribunalRoute => '/tribunal/${tribunal.toLowerCase()}';

  bool get hasSnapshot => payload != null && payload!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tribunal': tribunal,
        'filingNo': filingNo,
        'caseNo': caseNo,
        'title': title,
        'nextHearing': nextHearing,
        'savedAt': savedAt,
        'payloadKind': payloadKind,
        'payload': payload,
        'sourceUrl': sourceUrl,
        'previousNextHearing': previousNextHearing,
        'listingChanged': listingChanged,
        'lastCheckedAt': lastCheckedAt,
      };

  factory BookmarkedCase.fromJson(Map<String, dynamic> json) {
    return BookmarkedCase(
      id: json['id'] as String? ?? '',
      tribunal: json['tribunal'] as String? ?? '',
      filingNo: json['filingNo'] as String? ?? '',
      caseNo: json['caseNo'] as String? ?? '',
      title: json['title'] as String? ?? '',
      nextHearing: json['nextHearing'] as String?,
      savedAt: json['savedAt'] as int? ?? 0,
      payloadKind: json['payloadKind'] as String?,
      payload: json['payload'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      previousNextHearing: json['previousNextHearing'] as String?,
      listingChanged: json['listingChanged'] as bool? ?? false,
      lastCheckedAt: json['lastCheckedAt'] as int?,
    );
  }

  static String makeId(String tribunal, String filingNo) {
    return '${tribunal.toUpperCase()}::${filingNo.trim()}';
  }

  BookmarkedCase copyWith({
    int? savedAt,
    String? nextHearing,
    String? payloadKind,
    String? payload,
    String? sourceUrl,
    String? title,
    String? caseNo,
    String? previousNextHearing,
    bool? listingChanged,
    int? lastCheckedAt,
  }) {
    return BookmarkedCase(
      id: id,
      tribunal: tribunal,
      filingNo: filingNo,
      caseNo: caseNo ?? this.caseNo,
      title: title ?? this.title,
      nextHearing: nextHearing ?? this.nextHearing,
      savedAt: savedAt ?? this.savedAt,
      payloadKind: payloadKind ?? this.payloadKind,
      payload: payload ?? this.payload,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      previousNextHearing: previousNextHearing ?? this.previousNextHearing,
      listingChanged: listingChanged ?? this.listingChanged,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }
}
