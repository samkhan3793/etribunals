import 'package:etribunals/presentation/screens/tribunals/nclat/displayboard/view-details-screen.dart';
import 'package:flutter/material.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/case_summary_card.dart';
import 'package:etribunals/core/widgets/court_band.dart';
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
      appBar: AppBar(title: const Text('NCLAT display board')),
      body: RefreshIndicator(
        onRefresh: _loadDisplayBoard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center))])
                : _tableData.isEmpty
                    ? ListView(children: const [Padding(padding: EdgeInsets.all(24), child: Text('No sitting listed', textAlign: TextAlign.center))])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tableData.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const CourtBand(
                              title: 'Todayâ€™s board',
                              subtitle: 'Official nclat.nic.in  Â·  pull to refresh',
                              icon: Icons.tv_outlined,
                            );
                          }
                          final row = _tableData[index - 1];
                          String textOf(String key) {
                            final v = row[key];
                            if (v == null) return '';
                            if (v is Map) return (v['label'] ?? v['text'] ?? '').toString();
                            return v.toString();
                          }

                          Map<String, dynamic>? action;
                          for (final v in row.values) {
                            if (v is Map && v.containsKey('url')) {
                              action = Map<String, dynamic>.from(v);
                              break;
                            }
                          }

                          return CaseSummaryCard(
                            fields: {
                              'Case no.': textOf('Case No.'),
                              'Party': textOf('Cause Title'),
                              'Status': textOf('Item No.'),
                              'Court': textOf('Court Name').isEmpty ? textOf('Court') : textOf('Court Name'),
                            },
                            actionLabel: action == null ? 'No list' : (action['label']?.toString() ?? 'View'),
                            loading: false,
                            onAction: () {
                              final url = action?['url']?.toString();
                              if (url == null || url.isEmpty) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ViewDetailsScreen(requestUrl: url)),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
