import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/nclt-order-judgement/nclt_order_judgement_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NCLTOrderJudgementSearcResultsScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const NCLTOrderJudgementSearcResultsScreen(this.data, {super.key});

  @override
  _NCLTOrderJudgementSearchResultsScreenState createState() => _NCLTOrderJudgementSearchResultsScreenState();
}

class _NCLTOrderJudgementSearchResultsScreenState extends State<NCLTOrderJudgementSearcResultsScreen> {
  bool _isLoading = false; // Loading state indicator

  Future<void> _fetchCaseDetails(BuildContext context, String filingNo, String mainCaseFno) async {
    setState(() => _isLoading = true); // Start loading

    final bool flagIA = mainCaseFno == "NA" ? false : true;
    final String url = "https://efiling.nclt.gov.in/caseHistoryalldetails.drt?filing_no=$filingNo&flagIA=$flagIA";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> caseData = jsonDecode(response.body);

        setState(() => _isLoading = false); // Stop loading

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NCLTOrderJudgementScreen(caseData)),
        );
      } else {
        throw Exception("Failed to fetch case details");
      }
    } catch (e) {
      setState(() => _isLoading = false); // Stop loading in case of an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching case details: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseDetails = (widget.data['mainpanellist'] as List?)?.firstOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order/Judgement Search Results"),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      backgroundColor: AppColors.secondary,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: caseDetails.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildCaseDetailsCard(context, caseDetails),
                ],
              )
            : const Center(child: Text("No case details available")),
      ),
    );
  }

  Widget _buildCaseDetailsCard(BuildContext context, Map<String, dynamic> details) {
    final Map<String, String> filteredDetails = {
      "Filing No.": details["filing_no"] ?? "N/A",
      "Case Type": details["case_type_desc_cis"] ?? "N/A",
      "Case No": details["case_no"] ?? "N/A",
      "Case Title": "${details["case_title1"] ?? "N/A"} vs ${details["case_title2"] ?? "N/A"}",
      "Bench Location / Court No.": "${details["bench_location_name"] ?? "N/A"} / ${details["court_no"] ?? "N/A"}",
      "Main Case Filing No": details["main_case_fno"] ?? "N/A",
      "Filing / Registration Date": "${details["date_of_filing"] ?? "N/A"} / ${details["regis_date"] ?? "N/A"}",
      "Next Listing / Dispose Date": "${details["next_list_date"] ?? "N/A"} / ${details["disposal_date"] ?? "N/A"}",
      "Case Status": details["status"] ?? "N/A",
      "All Hearings": details["allhearing"]?.toString() ?? "N/A",
      "Effective Hearings": details["effhearing"]?.toString() ?? "N/A",
    };

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      borderOnForeground: true,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...filteredDetails.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "${entry.key}: ",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _isLoading
                  ? const CircularProgressIndicator() // Show loading indicator
                  : TextButton(
                      onPressed: () => _fetchCaseDetails(context, details["filing_no"] ?? "", details["main_case_fno"] ?? "NA"),
                      child: const Text("View Order/Judgements", style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
