class CaseRouteHint {
  final String tribunal;
  final String route;
  final String label;
  const CaseRouteHint({required this.tribunal, required this.route, required this.label});
}

List<CaseRouteHint> caseRouteHints(String raw) {
  final q = raw.trim().toUpperCase();
  if (q.length < 3) return const [];
  final out = <CaseRouteHint>[];
  void add(String t, String route, String label) {
    if (out.any((e) => e.tribunal == t)) return;
    out.add(CaseRouteHint(tribunal: t, route: route, label: label));
  }

  final looksNumber = RegExp(r'\d').hasMatch(q) && (q.contains('/') || q.contains('-') || q.contains(' '));
  if (q.startsWith('NC/') || q.contains('NCDRC')) {
    add('NCDRC', '/ncdrc/case-status', 'Search NCDRC case status');
  }
  if (q.contains('PMLA') || q.contains('FPA-PMLA') || q.contains('FPA-FE') || q.contains('SAFEMA') || q.contains('FPA/ND')) {
    add('ATFP', '/atfp/orders', 'Search ATFP orders');
  }
  if (q.startsWith('CGIT') || q.contains('EPFA') || q.contains('EPF APPEAL')) {
    add('CGIT', '/cgit/cause-list', 'Search CGIT cause list');
  }
  if (q.contains('AFT') || q.contains('OA/') || q.contains('TA/')) {
    add('AFT', '/aft/case-status', 'Search AFT case status');
  }
  if (q.contains('SAT') || q.contains('SEBI')) {
    add('SAT', '/sat/case-status', 'Search SAT case status');
  }
  if (q.contains('TDSAT') || q.contains('BROADCAST')) {
    add('TDSAT', '/tdsat/case-status', 'Search TDSAT case status');
  }
  if (q.contains('APTEL')) {
    add('APTEL', '/aptel/case-status', 'Search APTEL case status');
  }
  if (q.contains('CESTAT')) {
    add('CESTAT', '/cestat/case-details', 'Search CESTAT case');
  }
  if (q.contains('ITAT') || q.contains('ITA')) {
    add('ITAT', '/itat/case-status', 'Search ITAT case status');
  }
  if (q.contains('CAT') || q.contains('OA NO')) {
    add('CAT', '/cat/case-status', 'Search CAT case status');
  }
  if (q.contains('DRT') || q.contains('OA NO')) {
    add('DRT', '/drt/case-details', 'Search DRT case');
  }
  if (q.contains('NGT') || q.contains('OA')) {
    add('NGT', '/ngt/track-case-status', 'Search NGT case');
  }
  if (q.contains('NCLAT') || q.contains('COMPANY APPEAL')) {
    add('NCLAT', '/nclat/track-case-status', 'Search NCLAT case');
  }
  if (q.contains('NCLT') || q.contains('CP/') || q.contains('IB')) {
    add('NCLT', '/nclt/track-case-status', 'Search NCLT case');
  }
  if (q.contains('UPREAT')) {
    add('UPREAT', '/upreat/track-case-status', 'Search UPREAT case');
  }
  if (q.contains('RCT')) {
    add('RCT', '/rct/track-case-status', 'Search RCT case');
  }
  if (out.isEmpty && looksNumber) {
    add('NCDRC', '/ncdrc/case-status', 'Try NCDRC if this is NC/…');
    add('ATFP', '/atfp/orders', 'Try ATFP if this is FPA-…');
    add('CGIT', '/cgit/cause-list', 'Try CGIT if this is CGIT/…');
  }
  return out.take(3).toList();
}
