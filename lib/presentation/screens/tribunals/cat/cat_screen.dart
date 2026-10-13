import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/cat_client.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/feature_grid.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:flutter/material.dart';

class CATScreen extends StatefulWidget {
  const CATScreen({super.key});

  @override
  State<CATScreen> createState() => _CATScreenState();
}

class _CATScreenState extends State<CATScreen> {
  String? _id;

  @override
  void initState() {
    super.initState();
    _id = CatSession.instance.bench?.id ?? '100';
    _apply(_id!);
  }

  void _apply(String id) {
    final bench = CatClient.benches.firstWhere((e) => e.id == id, orElse: () => CatClient.benches.first);
    CatSession.instance.bench = bench;
    setState(() => _id = bench.id);
  }

  @override
  Widget build(BuildContext context) {
    final bench = CatSession.instance.bench;
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: customText('CAT', size: 20, weight: FontWeight.w700, color: Colors.white)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: CourtBand(
              title: bench?.name ?? 'Select bench',
              subtitle: 'cgat.gov.in  ·  case management after bench is selected',
              color: const Color(0xFF3D4A6B),
              icon: Icons.badge_rounded,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _id,
              decoration: const InputDecoration(labelText: 'Select bench'),
              items: CatClient.benches
                  .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _apply(v);
              },
            ),
          ),
          Expanded(
            child: FeatureGrid(
              heading: 'Case management',
              subtitle: 'Official public tools for ${bench?.name ?? 'the selected bench'}',
              items: const [
                {'title': 'Case status', 'route': '/cat/case-status', 'icon': Icons.search},
                {'title': 'Cause list', 'route': '/cat/cause-list', 'icon': Icons.list_alt},
                {'title': 'Daily order', 'route': '/cat/daily-orders', 'icon': Icons.description_outlined},
                {'title': 'Oral and final order', 'route': '/cat/final-orders', 'icon': Icons.gavel},
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SourceFooter(tribunal: 'CAT', officialUrl: CatClient.site),
          ),
        ],
      ),
    );
  }
}
