import 'dart:typed_data';
import 'package:etribunals/core/constants/tribunal_sources.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/judgements/order_search_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ViewJudgementOrdersScreen extends StatefulWidget {
  const ViewJudgementOrdersScreen({super.key});

  @override
  _ViewJudgementOrdersScreenState createState() =>
      _ViewJudgementOrdersScreenState();
}

class _ViewJudgementOrdersScreenState extends State<ViewJudgementOrdersScreen> {
  final Dio _dio = Dio();
  final CookieJar _cookieJar = CookieJar();

  final _diaryNoController = TextEditingController();
  final _captchaController = TextEditingController();
  final _caseNumberController = TextEditingController();
  Uint8List? _captchaImageBytes;
  List<String> _advocateSuggestions = [];
  TextEditingController _advocateController = TextEditingController();

  String _selectedLocation = 'delhi';
  String _selectedSearchBy = '1';
  String _selectedCaseType = '';
  String _selectedCaseStatus = '';
  String _selectedCaseYear = '${DateTime.now().year}';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(CookieManager(_cookieJar));
    _loadCaptcha();
  }

  Future<void> _loadCaptcha() async {
    try {
      final response = await _dio.get(
        'https://efiling.nclat.gov.in/nclat/captcha.php',
        options: Options(responseType: ResponseType.bytes),
      );
      setState(() {
        _captchaImageBytes = Uint8List.fromList(response.data);
      });
    } catch (e) {
  // debugPrint('Error loading CAPTCHA: $e');
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await _dio.post(
        'https://efiling.nclat.gov.in/nclat/ajax/ajax.php',
        data: {
          'action': 'case_status_search',
          'search_by': _selectedSearchBy,
          'case_type': _selectedCaseType,
          'case_status': _selectedCaseStatus,
          'case_number': _caseNumberController.text,
          'case_year': _selectedCaseYear,
          'diary_no': _diaryNoController.text,
          'answer': _captchaController.text,
          'schema_name': _selectedLocation,
          'advocate_name':
              _selectedSearchBy == '5' ? _advocateController.text : '',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'X-Requested-With': 'XMLHttpRequest'},
        ),
      );

      final responseBody = response.data.toString().trim();

      if (responseBody.isEmpty ||
          responseBody.contains('Invalid Captcha') ||
          responseBody.contains('No Record Found') ||
          responseBody.toLowerCase().contains('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No data found or invalid CAPTCHA. Please try again.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        _loadCaptcha();
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => OrderSearchResultScreen(responseData: responseBody),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchSuggestions({
    required String searchBy,
    required String scheema,
  }) async {
    const url = 'https://efiling.nclat.gov.in/nclat/ajax/ajax.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'select_case_status',
          'search_by': searchBy,
          'schema_name': scheema,
        },
      );

      if (response.statusCode == 200) {
        final body = response.body;
        final regex = RegExp(r'source:\s*(\[[^\]]+\])');
        final match = regex.firstMatch(body);
        if (match != null) {
          final jsonArrayString = match.group(1);
          final decoded = json.decode(jsonArrayString!);
          if (decoded is List) {
            final List<String> results = List<String>.from(
              decoded.map((e) => e.toString()),
            );
            _advocateSuggestions = results;
          }
        }
      }
    } catch (e) {
  // debugPrint('Error fetching suggestions: $e');
    }
  }

  @override
  void dispose() {
    _diaryNoController.dispose();
    _captchaController.dispose();
    _caseNumberController.dispose();
    _advocateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NCLAT judgements / orders')),
      backgroundColor: AppColors.secondary,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Search official orders',
            subtitle: 'Same eFiling form as case status  Â·  use numeric case types',
            icon: Icons.gavel,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedLocation,
            decoration: const InputDecoration(labelText: 'Bench'),
            items: const [
              DropdownMenuItem(value: 'delhi', child: Text('New Delhi')),
              DropdownMenuItem(value: 'chennai', child: Text('Chennai')),
            ],
            onChanged: (value) => setState(() => _selectedLocation = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedSearchBy,
            decoration: const InputDecoration(labelText: 'Search by'),
            items: const [
              DropdownMenuItem(value: '1', child: Text('Filing / diary no.')),
              DropdownMenuItem(value: '2', child: Text('Case type')),
              DropdownMenuItem(value: '3', child: Text('Case number')),
              DropdownMenuItem(value: '5', child: Text('Advocate')),
            ],
            onChanged: (value) {
              if (value == '5') {
                _fetchSuggestions(searchBy: value!, scheema: _selectedLocation);
              }
              setState(() => _selectedSearchBy = value!);
            },
          ),
          const SizedBox(height: 12),
          if (_selectedSearchBy == '2' || _selectedSearchBy == '3') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedCaseType,
              decoration: const InputDecoration(labelText: 'Case type'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Select case type')),
                DropdownMenuItem(value: '32', child: Text('Company Appeal (AT)')),
                DropdownMenuItem(value: '33', child: Text('Company Appeal (AT)(Ins)')),
                DropdownMenuItem(value: '34', child: Text('Competition Appeal (AT)')),
                DropdownMenuItem(value: '35', child: Text('Interlocutory Application')),
                DropdownMenuItem(value: '36', child: Text('Compensation Application')),
                DropdownMenuItem(value: '37', child: Text('Contempt Case (AT)')),
                DropdownMenuItem(value: '38', child: Text('Review Application')),
                DropdownMenuItem(value: '39', child: Text('Restoration Application')),
                DropdownMenuItem(value: '40', child: Text('Transfer Appeal')),
                DropdownMenuItem(value: '61', child: Text('Transfer Original Petition (MRTP-AT)')),
              ],
              onChanged: (value) => setState(() => _selectedCaseType = value!),
            ),
            const SizedBox(height: 12),
            if (_selectedSearchBy == '2') ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedCaseStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Select status')),
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'P', child: Text('Pending')),
                  DropdownMenuItem(value: 'D', child: Text('Disposed')),
                ],
                onChanged: (value) => setState(() => _selectedCaseStatus = value!),
              ),
              const SizedBox(height: 12),
            ],
          ],
          if (_selectedSearchBy == '3') ...[
            _textInput(_caseNumberController, 'Case number (serial only)'),
            const SizedBox(height: 12),
          ],
          if (_selectedSearchBy == '1') ...[
            _textInput(_diaryNoController, 'Filing / diary number'),
            const SizedBox(height: 12),
          ],
          if (_selectedSearchBy == '5') ...[
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return _advocateSuggestions.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                _advocateController = controller;
                return _textInput(controller, 'Advocate name', focusNode: focusNode, onEditingComplete: onEditingComplete);
              },
              onSelected: (_) {},
            ),
            const SizedBox(height: 12),
          ],
          if (_selectedSearchBy != '1') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedCaseYear,
              decoration: const InputDecoration(labelText: 'Year'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Select year')),
                const DropdownMenuItem(value: 'All', child: Text('All')),
                ...List.generate(15, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(value: '$year', child: Text('$year'));
                }),
              ],
              onChanged: (value) => setState(() => _selectedCaseYear = value!),
            ),
            const SizedBox(height: 12),
          ],
          if (_captchaImageBytes != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _textInput(_captchaController, 'Captcha')),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _loadCaptcha,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Image.memory(_captchaImageBytes!, height: 44),
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submitForm,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search'),
            ),
          ),
          SourceFooter(tribunal: 'NCLAT', officialUrl: TribunalSources.officialHome('NCLAT')),
        ],
      ),
    );
  }

  Widget _textInput(
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
    void Function()? onEditingComplete,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label),
    );
  }
}
