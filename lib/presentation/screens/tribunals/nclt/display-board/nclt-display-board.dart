import 'package:etribunals/presentation/screens/tribunals/nclat/displayboard/view-details-screen.dart';
import 'package:flutter/material.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/utils/web_scraper.dart';
class NCLTDisplayBoardScreen extends StatefulWidget {
  const NCLTDisplayBoardScreen({super.key});

  @override
  State<NCLTDisplayBoardScreen> createState() => _NCLTDisplayBoardScreenState();
}
class _NCLTDisplayBoardScreenState extends State<NCLTDisplayBoardScreen> {
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedLocation = "1"; // Default: Kolkata

  final List<Map<String, String>> _locations = [
    {"value": "1", "label": "New Delhi"},
    {"value": "3", "label": "Allahabad"},
    {"value": "4", "label": "Ahmedabad"},
    {"value": "5", "label": "Chennai"},
    {"value": "6", "label": "Mumbai"},
    {"value": "7", "label": "Chandigarh"},
    {"value": "8", "label": "Bengaluru"},
    {"value": "9", "label": "Jaipur"},
    {"value": "10", "label": "Hyderabad"},
    {"value": "14", "label": "Guwahati"},
    {"value": "15", "label": "Kochi"},
    {"value": "16", "label": "Kolkata"}, // Default selected
    {"value": "17", "label": "Indore"},
  ];

  @override
  void initState() {
    super.initState();
    _loadDisplayBoard();
  }

  Future<void> _loadDisplayBoard() async {
    setState(() => _isLoading = true);

    try {
      final data = await fetchNCLTDisplayBoardListTable(_selectedLocation!);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("NCLT Display Board List"),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        elevation: 1,
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _loadDisplayBoard();
          }
        },
        child: RefreshIndicator(
          onRefresh: _loadDisplayBoard,
          color: Colors.blue,
          child: Column(
            children: [
              // Location dropdown at the top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  items: _locations.map((location) {
                    return DropdownMenuItem(
                      value: location["value"],
                      child: Text(location["label"]!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                    _loadDisplayBoard();
                  },
                  validator: (value) => value == null ? 'Please select a location' : null,
                  decoration: const InputDecoration(
                    labelText: "Select Location",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                  dropdownColor: Colors.white, // Dropdown styling
                  isExpanded: true,
                ),
              ),

              // Divider for separation
              const Divider(color: Colors.grey, thickness: 1.5),

              // Display board data list
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildViewButton(Map<String, dynamic> valueMap) {
    final label = valueMap['label'] ?? 'View';
    final requestUrl = valueMap['url'];

    if (requestUrl != null) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDetailsScreen(requestUrl: requestUrl),
            ),
          );
        },
        child: Text(
          label,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return const Text("No link available", style: TextStyle(color: Colors.black54));
    }
  }
}
