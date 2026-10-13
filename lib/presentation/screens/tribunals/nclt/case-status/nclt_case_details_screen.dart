import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class CaseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> caseDetails;

  const CaseDetailsScreen(this.caseDetails, {super.key});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> isRegistered = caseDetails["isregistered"] ?? [];
    final List<dynamic> allproceedingdtls = caseDetails["allproceedingdtls"] ?? [];
    final Map<String, dynamic> caseData = isRegistered.isNotEmpty ? isRegistered.first : {};
    final Map<String, dynamic> allproceedingdtlsData = allproceedingdtls.isNotEmpty ? allproceedingdtls.first : {};
    final List<dynamic> allfinalstatuslist = caseDetails["allfinalstatuslist"] ?? [];
    final Map<String, dynamic> finalStatusData = allfinalstatuslist.isNotEmpty ? allfinalstatuslist.first : {};
    final List<dynamic> partyList = caseDetails["partydetailslist"] ?? [];
    final List <dynamic> applicationList = caseDetails["mainFilnowithIaNoList"] ?? [];
    final List<dynamic> caseProceedingList = caseDetails["allproceedingdtls"] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Case Details"),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('NCLT', caseData["filing_no"]?.toString() ?? ''),
              tribunal: 'NCLT',
              filingNo: caseData["filing_no"]?.toString() ?? '',
              caseNo: caseData["case_no"]?.toString() ?? '',
              title: "${caseData["case_title1"] ?? ""} vs ${caseData["case_title2"] ?? ""}".trim(),
              nextHearing: caseData["next_list_date"]?.toString(),
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'nclt_json',
              payload: jsonEncode(caseDetails),
              sourceUrl: TribunalSources.officialHome('NCLT'),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.secondary,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CourtBand(
                title: (caseData['case_no'] ?? caseData['filing_no'] ?? 'NCLT case').toString(),
                subtitle: '${caseData["case_title1"] ?? ""} vs ${caseData["case_title2"] ?? ""}'.trim(),
                icon: Icons.folder_open,
              ),
              const SizedBox(height: 12),
              _buildAccordionContainer(_buildMainCaseAccordion(caseData,allproceedingdtlsData)),
              const SizedBox(height: 15),
             _buildAccordionContainer( _buildCurrentCaseDetailsAccordion(finalStatusData, allproceedingdtlsData)),
              const SizedBox(height: 15),
              _buildAccordionContainer(_buildPartyDetailsAccordion(caseData, partyList)),
              const SizedBox(height: 15),
              _buildAccordionContainer(_buildApplicationDetailsAccordion(caseData, applicationList)),
              const SizedBox(height: 15),
              _buildAccordionContainer(_buildCaseProceedingDetailsAccordion(caseData, caseProceedingList)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCaseAccordion(Map<String, dynamic> caseData, Map<String, dynamic> allproceedingdtlsData ) {
    return ExpansionTile(
      initiallyExpanded: true, // Open by default
      title: const Text("Case Details", style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      children: [
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildDetailRow("Filing No.", caseData["filing_no"] ?? "N/A"),
                _buildDetailRow(
                    "Party Name",
                    "${caseData["case_title1"] ?? "N/A"} vs ${caseData["case_title2"] ?? "N/A"}"
                ),
                _buildDetailRow("Registration No.", caseData["case_no"] ?? "N/A"),
                _buildDetailRow("Filing / Registration Date",
                    "${caseData["date_of_filing"] ?? "N/A"} / ${caseData["regis_date"] ?? "N/A"}"),
                _buildDetailRow("All Hearings", allproceedingdtlsData["allhearing"]?.toString() ?? "N/A"),
                _buildDetailRow("Effective Hearings", allproceedingdtlsData["effhearing"]?.toString() ?? "N/A"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentCaseDetailsAccordion(Map<String, dynamic> finalStatusData, Map<String, dynamic> allproceedingdtlsData ) {
    return ExpansionTile(
      // This accordion is initially expanded to show the current case details
      initiallyExpanded: false, // Open by default
      title: const Text("Current Case Details", style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      children: [
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildDetailRow("Filing Date.", finalStatusData["date_of_filing"] ?? "N/A"),
                _buildDetailRow("Case Type", finalStatusData["case_type"] ?? "N/A"),
                _buildDetailRow("Case Filed By", finalStatusData["case_filed_by"] ?? "N/A"),
                _buildStatusRow("Defect Issued", 
                  (finalStatusData["defective_date"] == null || finalStatusData["defective_date"].toString().trim().isEmpty) 
                      ? "NO" 
                      : finalStatusData["defective_date"]
                ),
                _buildStatusRow("Refiled Date",
                  (finalStatusData["refiled_date"] == null || finalStatusData["refiled_date"].toString().trim().isEmpty) 
                      ? "NO" 
                      : finalStatusData["refiled_date"] 
                ),
                _buildStatusRow(
                      "Defect Free Date",
                      (finalStatusData["defect_free"] == null || finalStatusData["defect_free"].toString().trim().isEmpty)
                          ? "NO"
                          : finalStatusData["defect_free"]
                    ),
                _buildDetailRow("Registration Date", finalStatusData["regis_date"] ?? "N/A"),
                _buildDetailRow("Court No", finalStatusData["court_no"] ?? "N/A"),
                _buildDetailRow("Bench Natire", finalStatusData["bench_nature_descr"] ?? "N/A"),
                _buildDetailRow("First Listing Date", finalStatusData["listing_date"] ?? "N/A"),
                _buildDetailRow("Case Stage", finalStatusData["current_status"] ?? "N/A"),


              ],
            ),
          ),
        ),
      ],
    );
  }

Widget _buildPartyDetailsAccordion(Map<String, dynamic> caseData, List<dynamic> partyList) {
  return ExpansionTile(
    initiallyExpanded: false,
    title: const Text("Party Details", style: TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: AppColors.tile,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    children: partyList.asMap().entries.map((entry) {
      int index = entry.key + 1; // Start numbering from 1
      Map<String, dynamic> party = entry.value;

      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildDetailRow("Sr. No.", index.toString()),
              _buildDetailRow("Party Name", party["party_name"] ?? "N/A"),
              _buildDetailRow("Party Type", party["party_type"] ?? "N/A"),
              _buildDetailRow("Party Email", party["party_email"] ?? "N/A"),
              _buildDetailRow("Party Mobile", party["party_mobile"] ?? "N/A"),
              _buildDetailRow("Advocate Name", party["party_lawer_name"] ?? "N/A"),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

Widget _buildApplicationDetailsAccordion(Map<String, dynamic> caseData, List<dynamic> applicationList) {
  return ExpansionTile(
    initiallyExpanded: false,
    title: const Text("Application Details", style: TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: AppColors.tile,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    children: applicationList.asMap().entries.map((entry) {
      int index = entry.key + 1; // Start numbering from 1
      Map<String, dynamic> party = entry.value;

      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildDetailRow("Sr. No.", index.toString()),
              _buildDetailRow("Filing No", party["filing_no"] ?? "N/A"),
              _buildDetailRow("Case Type", party["case_type_desc_cis"] ?? "N/A"),
                            _buildDetailRow(
                  "Case Title",
                  party["case_title1"] != null && party["case_title2"] != null
                      ? "${party["case_title1"]} Vs ${party["case_title2"]}"
                      : "N/A",
                ),
              _buildDetailRow("Bench Location / Court No.",
                "${party["bench_location_name"] ?? "N/A"} / ${party["court_no"] ?? "N/A"}"
                ),
                _buildDetailRow("Application No", party["case_no"] ?? "N/A"),
              _buildDetailRow("Filing / Registration Date",
                "${party["date_of_filing"] ?? "N/A"} / ${party["regis_date"] ?? "N/A"}"
              ),
              _buildDetailRow("Next Listing / Dispose Date",
                "${party["next_list_date"] ?? "N/A"} / ${party["disposal_date"] ?? "N/A"}"
              ),
              _buildDetailRow("Case Status", party["status"] ?? "N/A"),
              _buildDetailRow("All Hearings", party["allhearing"]?.toString() ?? "N/A"),
              _buildDetailRow("Effective Hearings", party["effhearing"]?.toString() ?? "N/A"),
              _buildDetailRow("Main Case Filing No", party["main_case_fno"] ?? "N/A"),
            ],
          ),
        ),
      );
    }).toList(),
  );
}


Widget _buildCaseProceedingDetailsAccordion(Map<String, dynamic> caseData, List<dynamic> caseProceedingList) {
  return ExpansionTile(
    initiallyExpanded: false,
    title: const Text("Case Proceeding Details", style: TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: AppColors.tile,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    children: caseProceedingList.asMap().entries.map((entry) {
      int index = entry.key + 1; // Start numbering from 1
      Map<String, dynamic> party = entry.value;

      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildDetailRow("Sr. No.", index.toString()),
              _buildDetailRow("Bench Location / Court No.",
                "${party["bench_location_name"] ?? "N/A"} / ${party["court_no"] ?? "N/A"}"
                ),
              _buildDetailRow("Listing Date", party["listing_date"] ?? "N/A"),
              _buildDetailRow("Listing Purpose", party["purpose"] ?? "N/A"),
              _buildDetailRow("Action Taken", party["today_action"] ?? "N/A"),
              _buildDetailRow("Next Listing/Dispose Date", party["next_list_date"] ?? "N/A"),
              _buildDetailRow("Next Listing Purpose", party["next_listing_purpose"] ?? "N/A"),
              _buildDetailRow("Order Upload Date", party["order_upload_date"] ?? "N/A"),
              _buildDetailRow("Status", party["case_status"] ?? "N/A"),
              _buildDetailRow("Order Type", party["path_descr"] ?? "N/A"),
              _buildOrderDownloadRow("View/Download", party["encPath"] ?? "N/A"),
            ],
          ),
        ),
      );
    }).toList(),
  );
}


  Widget _buildDetailRow(String title, String value) {
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: Colors.black87)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusRow(String title, String? value) {
  bool isYes = value != 'NO'; // Determines if status is YES or NO

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Icon(
                isYes ? Icons.check_circle : Icons.cancel,
                color: isYes ? Colors.green : Colors.red, // Green for YES, Red for NO
              ),
              const SizedBox(width: 8), // Spacing between icon and text
              Text(isYes ? value! : "NO", overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isYes ? AppColors.ink : Colors.red, // Match text color with icon
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildOrderDownloadRow(String title, String? path) {
  final String pdfUrl = path != null && path.isNotEmpty
      ? TribunalSources.ncltOrderPdf(path)
      : "";

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: path != null && path.isNotEmpty
              ? Builder(
                  builder: (context) => ElevatedButton.icon(
                    onPressed: () => InAppDocumentScreen.open(context, pdfUrl, title: 'Order'),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: const Text("View Order"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                )
              : const Text("N/A"), // Display N/A if no path is available
        ),
      ],
    ),
  );
}
Widget _buildAccordionContainer(Widget child) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey, width: 1.5), // Border styling
      borderRadius: BorderRadius.circular(12.0), // Rounded corners
    ),
    child: child,
  );
}

}
