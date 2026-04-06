import 'package:etribunals/presentation/screens/tribunals/nclat/displayboard/view-details-screen.dart';
import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/utils/web_scraper.dart';
class DisplayBoardScreen extends StatefulWidget {
  const DisplayBoardScreen({super.key});

  @override
  State<DisplayBoardScreen> createState() => _DisplayBoardScreenState();
}

class _DisplayBoardScreenState extends State<DisplayBoardScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDisplayBoard();
  }

  Future<void> _loadDisplayBoard() async {
    setState(() => _isLoading = true);

    try {
      final data = await fetchDisplayBoardListTable();
      setState(() {
        _tableData = data;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'No Data Found. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: customText("Display Board List", size: 20, color: AppColors.white),
        backgroundColor: AppColors.primary,
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) { // Left swipe detected
            _loadDisplayBoard();
          }
        },
        child: RefreshIndicator(
          onRefresh: _loadDisplayBoard,
          color: AppColors.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: customText(_error!, size: 16, color: Colors.red))
                  : _tableData.isEmpty
                      ? Center(child: customText("No data found."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _tableData.length,
                          itemBuilder: (context, index) {
                            final row = _tableData[index];
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: row.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${entry.key}: ",
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: entry.value is Map<String, dynamic> && entry.value.containsKey('url')
                                                ? _buildViewButton(entry.value) // Updated function call
                                                : Text(
                                                    entry.value.toString(),
                                                    style: const TextStyle(color: Colors.black87),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }

  /// Updated function to navigate to `ViewDetailsScreen`
  Widget _buildViewButton(Map<String, dynamic> valueMap) {
    final label = valueMap['label'] ?? 'View';
    final requestUrl = valueMap['url'];

    if (requestUrl != null) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDetailsScreen(requestUrl: requestUrl), // Pass URL
            ),
          );
        },
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return const Text("No link available", style: TextStyle(color: Colors.black54));
    }
  }
}
