import 'dart:io';
import 'dart:typed_data';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/case_tracker/search_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:etribunals/core/constants/app_colors.dart';
import 'package:html/parser.dart' as html_parser;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class NgtTrackCaseStatusScreen extends StatefulWidget {
  const NgtTrackCaseStatusScreen({super.key});

  @override
  _NgtTrackCaseStatusScreenState createState() => _NgtTrackCaseStatusScreenState();
}

class _NgtTrackCaseStatusScreenState extends State<NgtTrackCaseStatusScreen> {
  Future<void> _fetchSuggestions({required String searchBy, required String scheema}) async {
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
            setState(() {
              _advocateSuggestions = List<String>.from(decoded.map((e) => e.toString()));
            });
          }
        }
      }
    } catch (e) {
      // Optionally handle error
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
          'advocate_name': _selectedSearchBy == '5' ? _advocateController.text : ''
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );
      final responseBody = response.data.toString().trim();
      if (!mounted) return;
      if (responseBody.isEmpty ||
          responseBody.contains('Invalid Captcha') ||
          responseBody.contains('No Record Found') ||
          responseBody.toLowerCase().contains('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No data found or invalid CAPTCHA. Please try again.'),
          backgroundColor: Colors.orange,
        ));
        _loadCaptcha();
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(responseData: responseBody),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Something went wrong. Please try again later.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
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
  String _selectedCaseYear = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(CookieManager(_cookieJar));
    _loadCaptcha();
  }

 Future<String?> _loadCaptcha() async {
 final url = Uri.parse('https://greentribunal.gov.in/casestatus/diarynumber'); // Replace with your target URL

  // Bypass SSL verification
  final httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  final ioClient = IOClient(httpClient);

  try {
    final response = await ioClient.get(url);
    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final captchaDiv = document.querySelector('#mainCaptcha');
  // debugPrint('Captcha Div: $captchaDiv');
      return captchaDiv?.text.trim();
    } else {
      throw Exception('Failed to load CAPTCHA. Status: ${response.statusCode}');
    }
  } catch (e) {
  // debugPrint('Error fetching CAPTCHA: $e');
    return null;
  } finally {
    ioClient.close();
  }
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Search By Dropdown
          _dropdownContainer(
            child: DropdownButton<String>(
              value: _selectedSearchBy,
              style: TextStyle(color: Colors.white),
              dropdownColor: AppColors.accent,
              items: [
                DropdownMenuItem(value: '1', child: customText('Filing No/Diary No', size: 16)),
                DropdownMenuItem(value: '2', child: customText('Case Type', size: 16)),
                DropdownMenuItem(value: '3', child: customText('Case Number', size: 16)),
                DropdownMenuItem(value: '5', child: customText('By Advocate', size: 16)),
              ],
              onChanged: (value) {
                if (value == '5') {
                  _fetchSuggestions(searchBy: value!, scheema: _selectedLocation);
                }
                setState(() {
                  _selectedSearchBy = value!;
                });
              },
              isExpanded: true,
            ),
          ),
          const SizedBox(height: 16),
          // Conditionally Rendered Widgets
          ...(_selectedSearchBy == '2' || _selectedSearchBy == '3'
              ? <Widget>[
                  _dropdownContainer(
                    child: DropdownButton<String>(
                      value: _selectedCaseType,
                      style: TextStyle(color: Colors.white),
                      dropdownColor: AppColors.accent,
                      items: [
                        DropdownMenuItem(value: '', child: customText('Select Case Type', size: 16)),
                        DropdownMenuItem(value: '32', child: customText('Company Appeal(AT)', size: 16)),
                        DropdownMenuItem(value: '33', child: customText('Company Appeal(AT)(Ins)', size: 16)),
                        DropdownMenuItem(value: '34', child: customText('Competition Appeal(AT)', size: 16)),
                        DropdownMenuItem(value: '35', child: customText('Interlocutory Application', size: 16)),
                        DropdownMenuItem(value: '36', child: customText('Compensation Application', size: 16)),
                        DropdownMenuItem(value: '37', child: customText('Contempt Case(AT)', size: 16)),
                        DropdownMenuItem(value: '38', child: customText('Review Application', size: 16)),
                        DropdownMenuItem(value: '39', child: customText('Restoration Application', size: 16)),
                        DropdownMenuItem(value: '40', child: customText('Transfer Appeal', size: 16)),
                        DropdownMenuItem(value: '61', child: customText('Transfer Original Petition (MRTP-AT)', size: 16)),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCaseType = value!;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(_selectedSearchBy == '2'
                      ? <Widget>[
                          _dropdownContainer(
                            child: DropdownButton<String>(
                              value: _selectedCaseStatus,
                              style: TextStyle(color: Colors.white),
                              dropdownColor: AppColors.accent,
                              items: [
                                DropdownMenuItem(value: '', child: customText('Select Case Status', size: 16)),
                                DropdownMenuItem(value: 'all', child: customText('All', size: 16)),
                                DropdownMenuItem(value: 'P', child: customText('Pending', size: 16)),
                                DropdownMenuItem(value: 'D', child: customText('Dispose', size: 16)),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCaseStatus = value!;
                                });
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ]
                      : []),
                ]
              : []),
          ...(_selectedSearchBy == '3'
              ? <Widget>[
                  _textInput(_caseNumberController, 'Case Number'),
                  const SizedBox(height: 16),
                ]
              : []),
          ...(_selectedSearchBy == '1'
              ? <Widget>[
                  _textInput(_diaryNoController, 'Diary Number'),
                  const SizedBox(height: 16),
                ]
              : []),
          ...(_selectedSearchBy == '5'
              ? <Widget>[
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return _advocateSuggestions.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      _advocateController = controller;
                      return _textInput(controller, 'Advocate Name', focusNode: focusNode, onEditingComplete: onEditingComplete);
                    },
                    onSelected: (String selection) {
                      // debugPrint('Selected: $selection');
                    },
                  ),
                  const SizedBox(height: 16),
                ]
              : []),
          ...(_selectedSearchBy != '1'
              ? <Widget>[
                  _dropdownContainer(
                    child: DropdownButton<String>(
                      value: _selectedCaseYear,
                      style: TextStyle(color: Colors.white),
                      dropdownColor: AppColors.accent,
                      items: [
                        DropdownMenuItem(value: '', child: customText('Select Year', size: 16)),
                        DropdownMenuItem(value: 'All', child: customText('All', size: 16)),
                        ...List.generate(10, (index) {
                          final year = 2025 - index;
                          return DropdownMenuItem(value: '$year', child: customText('$year', size: 16));
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCaseYear = value!;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                ]
              : []),
          // CAPTCHA
          ...(_captchaImageBytes != null
              ? <Widget>[
                  Row(
                    children: [
                      Expanded(child: _textInput(_captchaController, 'Enter CAPTCHA')),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _loadCaptcha,
                        child: Image.memory(_captchaImageBytes!, height: 50),
                      ),
                    ],
                  ),
                ]
              : <Widget>[const Center(child: CircularProgressIndicator())]),
          const SizedBox(height: 20),
          // Submit Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submitForm,
            child: Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 20),
          if (_loading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: child,
    );
  }

  Widget _textInput(TextEditingController controller, String label,
      {FocusNode? focusNode, void Function()? onEditingComplete}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: AppColors.accent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: TextStyle(color: Colors.white),
    );
  }
}
