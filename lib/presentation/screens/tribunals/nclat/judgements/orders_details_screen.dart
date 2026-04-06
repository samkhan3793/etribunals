import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/tables_extracter.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

class OrdersDetailsScreen extends StatelessWidget {
  final String filingNo;
  final String responseData;

  const OrdersDetailsScreen({
    super.key,
    required this.filingNo,
    required this.responseData,
  });

  @override
  Widget build(BuildContext context) {
    final document = html_parser.parse(responseData);
    final cards = document.querySelectorAll('.card');

    final Map<String, dynamic> caseJson = {};

    try {
      caseJson['Order History'] = extractTableList(cards[7]);
    } catch (e) {
      caseJson['error'] = 'Error parsing HTML: $e';
  // debugPrint('Error: $e');
    }

    return Scaffold(
      appBar: AppBar(
        title: customText('Orders Details - $filingNo'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.secondary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: caseJson.entries.map((entry) {
            return Card(
              color: AppColors.accent,
              margin: const EdgeInsets.symmetric(vertical: 5),
              elevation: 4,
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.accent,

                children: [
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: entry.value is Map<String, String>
                            ? buildKeyValueDataTable(entry.value)
                            : entry.value is List
                                ? buildDataTable(entry.value)
                                : const Text(
                                    "No data available.",
                                    style: TextStyle(color: Colors.black),
                                  ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  

  

  Widget buildKeyValueDataTable(Map<String, String> data) {
    if (data.isEmpty) {
      return const Text(
        "No data available.",
        style: TextStyle(color: Colors.black),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final key = (entry.key.trim().isEmpty) ? 'NA' : entry.key.trim();
        final value = (entry.value.trim().isEmpty) ? 'NA' : entry.value.trim();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  key,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildDataTable(List<Map<String, dynamic>> tableData) {
    if (tableData.isEmpty) {
      return const Text(
        "No data available.",
        style: TextStyle(color: Colors.black),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: tableData.first.keys.map((k) {
          return DataColumn(
            label: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
        rows: tableData.map((row) {
          return DataRow(
            cells: row.entries.map((entry) {
              final value = entry.value;

              if (value is Map && value.containsKey('url')) {
                final text = value['text'] ?? 'Download';
                // ignore: prefer_interpolation_to_compose_strings
                final url = "https://efiling.nclat.gov.in/nclat/"+value['url'];

                return DataCell(
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(url);
                     await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return DataCell(
                  Text(
                    value.toString(),
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
