import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:flutter/material.dart';

class UpreatOrderJudgementScreen extends StatelessWidget {
  final Map<String, dynamic> caseDetails;

  const UpreatOrderJudgementScreen(this.caseDetails, {super.key});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> isRegistered = caseDetails["isregistered"] ?? [];
    final Map<String, dynamic> caseData = isRegistered.isNotEmpty ? isRegistered.first : {};
    final List<dynamic> caseProceedingList = caseDetails["allproceedingdtls"] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Order/Judgement of Case"),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
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
  title: const Text("Case Proceeding Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
  backgroundColor: Colors.white,
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
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildOrderDownloadRow(String title, String? path) {
  final String pdfUrl = path != null && path.isNotEmpty
      ? TribunalSources.upreatOrderPdf(path)
      : "";

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        Expanded(
          flex: 3,
          child: path != null && path.isNotEmpty
              ? Builder(
                  builder: (context) => ElevatedButton.icon(
                    onPressed: () => InAppDocumentScreen.open(context, pdfUrl, title: 'Order'),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    label: const Text("View Order", style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                )
              : const Text("N/A", style: TextStyle(color: Colors.black54)),
        ),
      ],
    ),
  );
}
Widget _buildAccordionContainer(Widget child) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300, width: 1.5),
      borderRadius: BorderRadius.circular(12.0),
      color: Colors.white,
    ),
    child: child,
  );
}

}
