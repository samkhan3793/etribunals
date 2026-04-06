import 'package:etribunals/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NCLTOrderJudgementScreen extends StatelessWidget {
  final Map<String, dynamic> caseDetails;

  const NCLTOrderJudgementScreen(this.caseDetails, {super.key});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> isRegistered = caseDetails["isregistered"] ?? [];
    final Map<String, dynamic> caseData = isRegistered.isNotEmpty ? isRegistered.first : {};
    final List<dynamic> caseProceedingList = caseDetails["allproceedingdtls"] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Full Order/Judgement of Case"),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      backgroundColor: AppColors.secondary,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccordionContainer(_buildCaseProceedingDetailsAccordion(caseData, caseProceedingList)),
            ],
          ),
        ),
      ),
    );
  }






Widget _buildCaseProceedingDetailsAccordion(Map<String, dynamic> caseData, List<dynamic> caseProceedingList) {
  return ExpansionTile(
    initiallyExpanded: true,
    title: const Text("Case Proceeding Details", style: TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: AppColors.accent,
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
              style: const TextStyle(fontSize: 16, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildOrderDownloadRow(String title, String? path) {
  final String pdfUrl = path != null && path.isNotEmpty
      ? "https://efiling.nclt.gov.in/ordersview.drt?path=$path"
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
              ? ElevatedButton.icon(
                  onPressed: () async {
                      await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text("View Order"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Customize button color
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
