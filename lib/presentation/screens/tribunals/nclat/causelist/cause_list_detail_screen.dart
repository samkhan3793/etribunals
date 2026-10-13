import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class CauseListDetailScreen extends StatelessWidget {
  final String title;
  final String headerText;
  final String footerText;
  final String pdfUrl;
  final List<String> rawCases;

  const CauseListDetailScreen({
    super.key, 
    required this.title, 
    required this.headerText,
    required this.footerText,
    required this.pdfUrl,
    required this.rawCases
  });

  Map<String, String> _intelligentParser(String raw) {
    // Clean up text: remove extra newlines and collapse multiple spaces
    String clean = raw.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // 1. Extract Item Number
    final itemMatch = RegExp(r'^(\d+)\.').firstMatch(clean);
    String itemNo = itemMatch?.group(1) ?? "";
    clean = clean.replaceFirst(RegExp(r'^\d+\.\s*'), '');

    // 2. Detect Category (Fresh Cases, For Orders, etc.) - These act as headings
    final categoryKeywords = ['For Withdrawal', 'For Admission', 'Defective Cases', 'For Orders', 'For Hearing', 'Fresh Cases'];
    String category = "";
    for (var keyword in categoryKeywords) {
      if (clean.contains(RegExp(keyword, caseSensitive: false))) {
        category = keyword;
        break;
      }
    }
    if (category.isNotEmpty) clean = clean.replaceFirst(RegExp(category, caseSensitive: false), '').trim();

    // 3. Extract Case Number
    final caseMatch = RegExp(r'([A-Za-z\s\(\)]+No\.\s\d+[\/\-]\d{4})').firstMatch(clean);
    String caseNo = caseMatch?.group(0) ?? "Pending Analysis";
    
    // 4. Extract Parties (Everything between Case No and Counsel/R1/names)
    String partyCounselSection = clean.replaceFirst(caseNo, '').trim();
    final vsMatch = RegExp(r'(.*?)\sV[s\/]\s(.*?)(?=\s(Mr\.|Ms\.|Adv\.|Counsel|R\d+|$))').firstMatch(partyCounselSection);
    String parties = vsMatch?.group(0) ?? "Parties not parsed";
    
    // 5. Extract Counsels (Split based on typical Respondent numbering R1, R2 or Appellant/Respondent keywords)
    String counselSection = partyCounselSection.replaceFirst(parties, '').trim();
    List<String> counselParts = counselSection.split(RegExp(r'\s(?=R\d+|Mr\.|Ms\.|Adv\.)'));
    String appellantCounsel = counselParts.isNotEmpty ? counselParts[0].trim() : "Not Mentioned";
    String respondentCounsel = counselParts.length > 1 ? counselParts.sublist(1).join(', ').trim() : "Not Mentioned";
    
    return {
      "item": itemNo,
      "case": caseNo,
      "category": category,
      "parties": parties,
      "appellantCounsel": appellantCounsel,
      "respondentCounsel": respondentCounsel,
      "isSection": (category.isNotEmpty).toString(),
    };
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(pdfUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $pdfUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.heroStart, AppColors.heroMid],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 140.0,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: customText("Extracted Case List", size: 18, weight: FontWeight.bold, color: Colors.white),
                background: Container(
                  padding: const EdgeInsets.only(bottom: 24),
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: 0.5,
                    child: customText(title, size: 11, color: Colors.white, weight: FontWeight.w400),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 60),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = _intelligentParser(rawCases[index]);
                    return _buildStructuredCaseCard(data);
                  },
                  childCount: rawCases.length,
                ),
              ),
            ),
            if (footerText.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildInstructionFooter(),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 10),
              customText("Registry Information", size: 16, color: Colors.cyanAccent, weight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: 16),
          customText(headerText.trim(), size: 13, color: Colors.white70, align: TextAlign.left),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white10)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchURL,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: customText("View Original Source PDF", color: Colors.white, weight: FontWeight.bold, size: 14),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionFooter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 10),
              customText("VC Instructions", size: 14, color: Colors.amberAccent, weight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: 12),
          customText(footerText.trim(), size: 12, color: Colors.white60, align: TextAlign.left),
        ],
      ),
    );
  }

  Widget _buildStructuredCaseCard(Map<String, String> data) {
    final bool hasCategory = (data['category'] ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCategory) ...[
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: customText(data['category']!.toUpperCase(), size: 12, weight: FontWeight.w900, color: Colors.cyanAccent),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.white.withOpacity(0.05),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                          child: customText("ITEM ${data['item'] ?? '-'}", size: 11, weight: FontWeight.bold, color: Colors.white),
                        ),
                        const Spacer(),
                        const Icon(Icons.gavel_rounded, color: Colors.white24, size: 18),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelValue("CASE NO", data['case'] ?? '', Colors.cyanAccent, isBold: true),
                        const SizedBox(height: 16),
                        _labelValue("NAME OF THE PARTIES", data['parties'] ?? '', Colors.white),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, thickness: 1)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _labelValue("APPELLANT COUNSEL", data['appellantCounsel'] ?? '', Colors.white70, size: 12)),
                            const SizedBox(width: 16),
                            Expanded(child: _labelValue("RESPONDENT COUNSEL", data['respondentCounsel'] ?? '', Colors.white70, size: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value, Color valueColor, {bool isBold = false, double size = 14}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customText(label, size: 9, weight: FontWeight.bold, color: Colors.white38),
        const SizedBox(height: 6),
        SelectionArea(
          child: customText(
            value.isEmpty ? "Information Not Found" : value,
            size: size,
            weight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
            align: TextAlign.left,
          ),
        ),
      ],
    );
  }
}