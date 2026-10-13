class AppHelp {
  static const tribunals =
      'NCLAT, NCLT, UPREAT, NGT, RCT, DRT, CAT, ITAT, CESTAT, TDSAT, APTEL, SAT, AFT, NCDRC, ATFP and CGIT';

  static const disclaimer = '''
eTribunals is an independent companion app. It is not a government website, not a court, and not legal advice.

Cause lists, case status, orders and PDFs are copied from public tribunal sites. Those sites can change, go down, or show a different result than this app.

Always open the official site and verify the record before you file, pay a fee, or rely on a date.

Hearing reminders on this phone are a convenience only. They are not a court notice. Tap an alert to open the saved matter.''';

  static const privacy = '''
No account is created. Bookmarks, recent cases and saved PDFs stay on this device.

The app reads public pages from tribunal websites over the internet. It does not sync your followed cases to our server.

If you uninstall the app, local bookmarks and saved files on this phone may be removed.

AI Summarize sends the open PDF (or its extracted text) to Google Gemini so the app can list held points and answer a follow-up. No Gemini key is collected from you.''';

  static const sources =
      'Live in-app records: $tribunals. Always verify on the source before filing.';

  static const shareApp =
      'eTribunals helps you follow public tribunal records on your phone. Independent companion — not a government app. Always verify on the official site before filing.';

  static const playUrl = 'https://play.google.com/store/apps/details?id=com.zrh.etribunals.etribunals';

  static const privacyUrl = 'https://samkhan3793.github.io/etribunals/privacy.html';

  static const whatsNew = '''
• AI Summarize on order/judgement PDFs — held points, directions, then a short follow-up box.
• Share or copy a followed case (parties + next listing).
• “Date changed” on Today / My Cases after you pull to refresh (NCDRC and CGIT).
• Save a PDF from the viewer; recent files show on More.
• Help, disclaimer, privacy and report-a-problem on More.''';

  static const faqs = [
    (
      'What is AI Summarize?',
      'Open an order, judgement or other PDF in the app and tap AI Summarize. The app lists the result, held points and operative directions. You can then ask a short question about that same document.',
    ),
    (
      'Do I need an API key for AI?',
      'No. AI Summarize is built into eTribunals. You do not paste a Gemini key.',
    ),
    (
      'Is the AI summary legal advice?',
      'No. It is a draft reading of the PDF. Always open the official file before you file, pay a fee, or rely on a date.',
    ),
    (
      'What can I ask after a summary?',
      'Use the box under the summary — for example what was held, next listing, relief or costs. Answers stay limited to that PDF. If the order does not say, the app will say so.',
    ),
    (
      'How do I follow a case?',
      'Search a tribunal, open the matter, then bookmark it. It stays on My Cases on this phone. Share from the case card if you need to send parties and the next listing.',
    ),
    (
      'What is on the Today tab?',
      'Hearings for cases you follow, plus cause lists and display boards the court publishes that day.',
    ),
    (
      'Where are bookmarks saved?',
      'On this phone only. There is no login and no cloud copy. Uninstalling the app can delete them.',
    ),
    (
      'Why is there no sign-in?',
      'Guest mode is enough to search public records and follow a case on one device. An account is not required.',
    ),
    (
      'When do listing dates refresh?',
      'Pull down on My Cases or Today. eTribunals can refresh next dates for NCDRC and CGIT bookmarks. Other courts keep the date you saved until you open the case again.',
    ),
    (
      'Where do saved PDFs go?',
      'Use the download icon on a PDF. Files are stored on this phone. Recent saves appear on the More tab.',
    ),
    (
      'Why is a search incomplete or asking for captcha?',
      'Some official sites require a captcha or a layout this app cannot read. Use Open official site for that court.',
    ),
    (
      'When should I open the official site?',
      'Before filing, if a page looks empty, if a PDF fails, or if the listing date looks wrong. The court website is the source of truth.',
    ),
    (
      'Does this work without internet?',
      'Followed cases and saved PDFs stay on the phone. Live lists and new searches need a connection to the official site.',
    ),
    (
      'How do hearing reminders work?',
      'If reminders are on (More tab), this phone can notify you at 7:00 pm the evening before and 8:00 am Asia/Kolkata on a saved listing date. That is not a court notice. Use Send a test alert if nothing appears.',
    ),
  ];
}
