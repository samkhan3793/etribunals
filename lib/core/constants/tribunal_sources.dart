class TribunalSources {
  static String officialHome(String tribunal) {
    switch (tribunal.toUpperCase()) {
      case 'NCLT':
        return 'https://nclt.gov.in';
      case 'UPREAT':
        return 'https://upreat.up.gov.in';
      case 'NGT':
        return 'https://greentribunal.gov.in';
      case 'RCT':
        return 'https://cis.erct.gov.in/#/';
      case 'DRT':
        return 'https://drt.gov.in';
      case 'CAT':
        return 'https://cgat.gov.in';
      case 'ITAT':
        return 'https://itat.gov.in';
      case 'CESTAT':
        return 'https://cestat.gov.in';
      case 'TDSAT':
        return 'https://www.tdsat.gov.in/Delhi/Delhi.php';
      case 'APTEL':
        return 'https://aptel.gov.in';
      case 'SAT':
        return 'https://satweb.sat.gov.in';
      case 'AFT':
        return 'https://aft.gov.in';
      case 'NCDRC':
        return 'https://e-jagriti.gov.in';
      case 'ATFP':
        return 'https://atfp.gov.in';
      case 'CGIT':
        return 'https://apps.labour.gov.in/cgit';
      default:
        return 'https://nclat.nic.in';
    }
  }

  static String ncltOrderPdf(String path) =>
      'https://efiling.nclt.gov.in/ordersview.drt?path=$path';

  static String upreatOrderPdf(String path) =>
      'https://efilingreat.up.gov.in/ordersview.in?path=$path';

  static String ngtCaseDetails({required String bench, required String filingNo}) {
    final clean = filingNo.replaceAll('/', '').replaceAll(' ', '');
    final slug = bench.toUpperCase() == 'PRINCIPAL' ? 'DELHI' : bench.toUpperCase();
    return 'https://www.greentribunal.gov.in/caseDetails/$slug/$clean';
  }

  static const ncltNotifications = 'https://nclt.gov.in/notifcationss';
  static const ncltCirculars = 'https://nclt.gov.in/circulars';
  static const ncltCauseList = 'https://nclt.gov.in/all-cause-list';
  static const ngtJudgements = 'https://www.greentribunal.gov.in/judgementOrder/zonalbenchwise';
  static const ngtDiaryStatus = 'https://www.greentribunal.gov.in/casestatus/diarynumber';
  static const ngtCaseNumberStatus = 'https://www.greentribunal.gov.in/casestatus/casenumber';
}
