import 'package:etribunals/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class CauseListDetailScreen extends StatefulWidget {
  final String causeType;
  final String nextListDate;
  final String lisDate;
  final String benchNo;

  const CauseListDetailScreen({
    super.key,
    required this.causeType,
    required this.nextListDate,
    required this.lisDate,
    required this.benchNo,
  });

  @override
  State<CauseListDetailScreen> createState() => _CauseListDetailScreenState();
}

class _CauseListDetailScreenState extends State<CauseListDetailScreen> {
  List<Map<String, dynamic>> _causeListDetails = [];
  Map<String, dynamic>? _tribunalInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCauseListDetails();
  }

  /// Fetch cause list details
  Future<void> _fetchCauseListDetails() async {
    try {
      final response = await http.post(
        Uri.parse('https://efilingreat.up.gov.in/upreat/mis/cause_list_final.php'),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'cause_type': widget.causeType,
          'next_list_date': widget.nextListDate,
          'lis_date': widget.lisDate,
          'bench_no': widget.benchNo,
        },
      );

      if (response.statusCode == 200) {
        _processHtmlResponse(response.body);
      } else {
        throw Exception("Failed to fetch details.");
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching cause list details.";
        _isLoading = false;
      });
    }
  }

  /// Parses HTML response
  void _processHtmlResponse(String responseBody) {
    final document = html_parser.parse(responseBody);
    final tribunalCard = document.querySelectorAll("td[colspan='6'] div");

    if (tribunalCard.isEmpty) {
      throw Exception("Tribunal info not found.");
    }

    // Extract Tribunal Details
    _tribunalInfo = {
      "Tribunal Name": tribunalCard[2].text.trim(),
      "Bench": tribunalCard[3].text.trim(),
      "Cause List": tribunalCard[4].text.trim(),
      "Date & Time": tribunalCard[5].text.trim(),
      "CORAM": tribunalCard[6].text.trim(),
    };

    // Extract Case Details Table
    final headers = document.querySelectorAll('tr.thead td').map((e) => e.text.trim()).toList();
    final rows = document.querySelectorAll('tbody tr');

    final List<Map<String, dynamic>> parsedData = [];

    for (var row in rows.skip(1)) { // Skip first row (heading)
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;

      final Map<String, dynamic> rowData = {};
      for (int i = 0; i < headers.length && i < cells.length; i++) {
        final header = headers[i];
        final cell = cells[i];

        rowData[header] = cell.text.trim();
      }
      parsedData.add(rowData);
    }

    setState(() {
      _tribunalInfo = _tribunalInfo;
      _causeListDetails = parsedData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cause List Details"),backgroundColor: AppColors.primary,
        centerTitle: true,),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  /// Builds Tribunal Info Card & Case List
  Widget _buildContent() {
  return ListView(
    padding: const EdgeInsets.all(8.0),
    children: [
      if (_tribunalInfo != null) _buildTribunalInfoCard(),
      const SizedBox(height: 16),
      ..._causeListDetails.where((row) => _isValidSerialNumber(row)).map((row) => _buildDetailCard(row)),
    ],
  );
}

/// **Checks if `S.No.` contains a valid number**
bool _isValidSerialNumber(Map<String, dynamic> rowData) {
  final sno = rowData["S.No."];
  return sno != null && sno.isNotEmpty && int.tryParse(sno) != null;
}


  /// Tribunal Information Card
  Widget _buildTribunalInfoCard() {
    return Card(
      color: AppColors.white,
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _tribunalInfo!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(
                children: [
                  Text("${entry.key}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(entry.value.toString().replaceAll('CORAM', ''),style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), overflow: TextOverflow.clip),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Builds a Card for each cause list detail entry
  Widget _buildDetailCard(Map<String, dynamic> rowData) {
    return Card(
      color: AppColors.white,
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowData.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(
                children: [
                  Text("${entry.key}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(entry.value.toString(),style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black54), overflow: TextOverflow.clip),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
