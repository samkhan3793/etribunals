import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'dart:async';

import 'package:http/io_client.dart';

// Cache last successful response

/// Fetches and parses the cause list table from the NCLAT website.
/// Accepts start and end dates for the cause list filter.
Future<List<Map<String, dynamic>>> fetchCauseListTable(
  String courtId,
  String startDate,
  String endDate,
) async {
  final url = Uri.parse(
    'https://nclat.nic.in/daily-cause-list?title=&field_court_name_target_id=$courtId&field_final_date_value=$startDate&field_final_date_value_1=$endDate',
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);

      final table = document.querySelector('table');
      if (table == null) {
        throw Exception('No table found on the page.');
      }

      final headers =
          table
              .querySelectorAll('thead tr th')
              .map((e) => e.text.trim())
              .toList();
      final rows = table.querySelectorAll('tbody tr');

      final List<Map<String, dynamic>> data = [];

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue;

        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];

          // Check if this is the View/Download column with an <a> tag
          final anchor = cell.querySelector('a');
          if (anchor != null && anchor.attributes.containsKey('href')) {
            final href = anchor.attributes['href']!;
            final label = anchor.text.trim();
            rowData[header] = {'label': label, 'url': href};
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        data.add(rowData);
      }

      return data;
    } else {
      throw Exception('Failed to load page: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching or parsing cause list: $e');
    rethrow;
  }
}

String decodeHtmlUnicode(String input) {
  final unescape = HtmlUnescape();
  return unescape.convert(input);
}

Future<List<Map<String, dynamic>>> fetchJudgementOrderPriorMay2021ListTable(
  String courtName,
  String startDate,
  String endDate,
) async {
  final url = Uri.parse(
    'https://nclat.nic.in/views/ajax?_wrapper_format=drupal_ajax',
  );
  if (courtName == 'All') {
    courtName = ''; // Default value for all courts
  }
  final body = {
    'field_final_court_value':
        courtName, // Dynamically use the selected courtName
    'field_final_date_value[min]': startDate, // Dynamically use the startDate
    'field_final_date_value[max]': endDate, // Dynamically use the endDate
    'view_name': 'judgement_data',
    'view_display_id': 'block_3',
    'view_path': '/node/162',
    '_drupal_ajax': '1',
  };

  try {
    final response = await http.post(url, body: body);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);

      final rawHtml =
          jsonResponse.firstWhere(
                (item) =>
                    item is Map &&
                    item.containsKey('data') &&
                    (item['data'] as String).contains('<table'),
                orElse: () => null,
              )?['data']
              as String?;

      if (rawHtml == null) throw Exception('HTML table not found.');

      final decodedHtml = decodeHtmlUnicode(rawHtml);

      final document = html_parser.parse(decodedHtml);
      final table = document.querySelector('table');
      if (table == null) throw Exception('No table found.');

      final headers =
          table
              .querySelectorAll('thead tr th')
              .map((e) => e.text.trim())
              .toList();
      final rows = table.querySelectorAll('tbody tr');

      final List<Map<String, dynamic>> data = [];

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue;

        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];

          final anchor = cell.querySelector('a');
          if (anchor != null && anchor.attributes.containsKey('href')) {
            final href = anchor.attributes['href']!;
            final fullUrl =
                href.startsWith('.')
                    ? 'https://nclat.nic.in${href.substring(1)}'
                    : href;
            rowData[header] = {'label': anchor.text.trim(), 'url': fullUrl};
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        data.add(rowData);
      }

      return data;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> fetchDailyOrderPriorMay2021ListTable(
  String courtName,
  String startDate,
  String endDate,
) async {
  final url = Uri.parse(
    'https://nclat.nic.in/views/ajax?_wrapper_format=drupal_ajax',
  );
  if (courtName == 'All') {
    courtName = ''; // Default value for all courts
  }
  final body = {
    'field_final_court_value':
        courtName, // Dynamically use the selected courtName
    'field_final_date_value[min]': startDate, // Dynamically use the startDate
    'field_final_date_value[max]': endDate, // Dynamically use the endDate
    'view_name': 'daily_orders_data',
    'view_display_id': 'block_4',
    'view_path': '/node/163',
    '_drupal_ajax': '1',
  };

  try {
    final response = await http.post(url, body: body);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);

      final rawHtml =
          jsonResponse.firstWhere(
                (item) =>
                    item is Map &&
                    item.containsKey('data') &&
                    (item['data'] as String).contains('<table'),
                orElse: () => null,
              )?['data']
              as String?;

      if (rawHtml == null) throw Exception('HTML table not found.');

      final decodedHtml = decodeHtmlUnicode(rawHtml);

      final document = html_parser.parse(decodedHtml);
      final table = document.querySelector('table');
      if (table == null) throw Exception('No table found.');

      final headers =
          table
              .querySelectorAll('thead tr th')
              .map((e) => e.text.trim())
              .toList();
      final rows = table.querySelectorAll('tbody tr');

      final List<Map<String, dynamic>> data = [];

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue;

        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];

          final anchor = cell.querySelector('a');
          if (anchor != null && anchor.attributes.containsKey('href')) {
            final href = anchor.attributes['href']!;
            final fullUrl =
                href.startsWith('.')
                    ? 'https://nclat.nic.in${href.substring(1)}'
                    : href;
            rowData[header] = {'label': anchor.text.trim(), 'url': fullUrl};
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        data.add(rowData);
      }

      return data;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>>
fetchRegistrarDailyOrderPriorMay2021ListTable(
  String courtName,
  String startDate,
  String endDate,
) async {
  final url = Uri.parse(
    'https://nclat.nic.in/views/ajax?_wrapper_format=drupal_ajax',
  );
  final body = {
    'field_final_court_value':
        'Registrar Court', // Dynamically use the selected courtName
    'field_final_date_value': startDate, // Dynamically use the startDate
    'field_final_date_value_1': endDate, // Dynamically use the endDate
    'view_name': 'daily_orders_registrar_court',
    'view_display_id': 'block_3',
    'view_path': '/quicktabs/ajax/daily_orders_registrar_court/2',
    '_drupal_ajax': '1',
  };

  try {
    final response = await http.post(url, body: body);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);

      final rawHtml =
          jsonResponse.firstWhere(
                (item) =>
                    item is Map &&
                    item.containsKey('data') &&
                    (item['data'] as String).contains('<table'),
                orElse: () => null,
              )?['data']
              as String?;

      if (rawHtml == null) throw Exception('HTML table not found.');

      final decodedHtml = decodeHtmlUnicode(rawHtml);

      final document = html_parser.parse(decodedHtml);
      final table = document.querySelector('table');
      if (table == null) throw Exception('No table found.');

      final headers =
          table
              .querySelectorAll('thead tr th')
              .map((e) => e.text.trim())
              .toList();
      final rows = table.querySelectorAll('tbody tr');

      final List<Map<String, dynamic>> data = [];

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue;

        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];

          final anchor = cell.querySelector('a');
          if (anchor != null && anchor.attributes.containsKey('href')) {
            final href = anchor.attributes['href']!;
            final fullUrl =
                href.startsWith('.')
                    ? 'https://nclat.nic.in${href.substring(1)}'
                    : href;
            rowData[header] = {'label': anchor.text.trim(), 'url': fullUrl};
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        data.add(rowData);
      }

      return data;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> fetchNoticeListTable(
  String courtName,
  String startDate,
  String endDate,
) async {
  final url = Uri.parse(
    'https://nclat.nic.in/views/ajax?_wrapper_format=drupal_ajax',
  );
  final body = {
    'title': '', // Dynamically use the selected courtName
    'field_final_date_value': startDate, // Dynamically use the startDate
    'field_final_date_value_1': endDate, // Dynamically use the endDate
    'view_name': 'nc_notice_data',
    'view_display_id': 'page_1',
    'view_path': '/nclat-notice',
    'view_base_path': '/nclat-notice',
    '_drupal_ajax': '1',
  };

  try {
    final response = await http.post(url, body: body);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);

      final rawHtml =
          jsonResponse.firstWhere(
                (item) =>
                    item is Map &&
                    item.containsKey('data') &&
                    (item['data'] as String).contains('<table'),
                orElse: () => null,
              )?['data']
              as String?;

      if (rawHtml == null) throw Exception('HTML table not found.');

      final decodedHtml = decodeHtmlUnicode(rawHtml);

      final document = html_parser.parse(decodedHtml);
      final table = document.querySelector('table');
      if (table == null) throw Exception('No table found.');

      final headers =
          table
              .querySelectorAll('thead tr th')
              .map((e) => e.text.trim())
              .toList();
      final rows = table.querySelectorAll('tbody tr');

      final List<Map<String, dynamic>> data = [];

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue;

        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];

          final anchor = cell.querySelector('a');
          if (anchor != null && anchor.attributes.containsKey('href')) {
            final href = anchor.attributes['href']!;
            final fullUrl =
                href.startsWith('.')
                    ? 'https://nclat.nic.in${href.substring(1)}'
                    : href;
            rowData[header] = {'label': anchor.text.trim(), 'url': fullUrl};
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        data.add(rowData);
      }

      return data;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred: $e');
    rethrow;
  }
}

// Dropdown value for circular order
Future<List<Map<String, dynamic>>> fetchCircularOrderNoticeListTable(
  String dropdownValue,
  String startDate,
  String title,
) async {
  final url = Uri.parse(
    'https://nclat.nic.in/circulars-orders?title=&field_circular_category_target_id=$dropdownValue&field_date_value=$startDate&page=0',
  );
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);

      final table = document.querySelector('table');
      if (table == null) {
        throw Exception('No table found on the page.');
      }

      final headers =
          table
              .querySelectorAll('thead tr th')
              .map((e) => e.text.trim())
              .toList();
      final rows = table.querySelectorAll('tbody tr');

      final List<Map<String, dynamic>> data = [];

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue;

        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];

          // Check if this is the View/Download column with an <a> tag
          final anchor = cell.querySelector('a');
          if (anchor != null && anchor.attributes.containsKey('href')) {
            final href = anchor.attributes['href']!;
            final label = anchor.text.trim();
            rowData[header] = {'label': label, 'url': href};
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        data.add(rowData);
      }

      return data;
    } else {
      throw Exception('No Data Found: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching or parsing Circulat/Order/Notification list: $e');
    rethrow;
  }
}

// Dropdown value for Act and Rules
Future<List<Map<String, dynamic>>> fetchActsAndRulesListTable(
  String dropdownValue,
  String startDate,
  String title,
) async {
  final url = Uri.parse(
    'https://nclat.nic.in/act-rules?field_acts_rules_category_t_target_id=$dropdownValue',
  );
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);

      final table = document.querySelector('table');
      if (table == null) {
        throw Exception('No table found on the page.');
      }

      final headers =
          table
              .querySelectorAll('thead tr th')
              .map((e) => e.text.trim())
              .toList();
      final rows = table.querySelectorAll('tbody tr');

      final List<Map<String, dynamic>> data = [];

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue;

        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];

          // Check if this is the View/Download column with an <a> tag
          final anchor = cell.querySelector('a');
          if (anchor != null && anchor.attributes.containsKey('href')) {
            final href = anchor.attributes['href']!;
            final label = anchor.text.trim();
            rowData[header] = {'label': label, 'url': href};
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        data.add(rowData);
      }

      return data;
    } else {
      throw Exception('No Data Found: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching or parsing Acts and Rules Data list: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> fetchDisplayBoardListTable() async {
  final url = Uri.parse('https://nclat.nic.in/display-board/');

  try {
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }

    final document = html_parser.parse(response.body);

    // Select the specific table using its class
    final table = document.querySelector('table.table-bordered.internet_exp');

    if (table == null) {
      throw Exception('No matching table found on the page.');
    }

    // Extract headers
    final headers =
        table
            .querySelectorAll('thead tr th')
            .map((e) => e.text.trim())
            .toList();

    // Extract table rows
    final rows = table.querySelectorAll('tbody tr');

    final List<Map<String, dynamic>> tableData = [];

    for (var row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;

      final Map<String, dynamic> rowData = {};
      for (int i = 0; i < cells.length && i < headers.length; i++) {
        final header = headers[i];
        final cell = cells[i];

        // Extract links inside the "Action" column
        final anchor = cell.querySelector('a');
        if (anchor != null && anchor.attributes.containsKey('href')) {
          final href = anchor.attributes['href']!;
          final label = anchor.text.trim();
          rowData[header] = {'label': label, 'url': href};
        } else {
          // If Item No., Case No., or Cause Title are missing, set them to "Not In Session"
          if (['Item No.', 'Case No.', 'Cause Title'].contains(header)) {
            rowData[header] =
                cell.text.trim().isEmpty ? 'Not In Session' : cell.text.trim();
          } else {
            rowData[header] = cell.text.trim();
          }
        }
      }
      tableData.add(rowData);
    }

    return tableData;
  } catch (e) {
    print('Error fetching or parsing Display Board Table: $e');
    rethrow;
  }
}



Future<List<Map<String, dynamic>>> fetchCauseList(
  String selectedBench,
  String startDate,
  String endDate,
  String captchaSid,
  String captchaToken,
  String captchaResponse,
) async {
  final queryParams = {
    'field_nclt_benches_list_target_id': selectedBench,
    'field_cause_date_value': startDate,
    'field_cause_date_value_1': endDate,
    'captcha_sid': captchaSid,
    'captcha_token': captchaToken,
    'captcha_response': captchaResponse,
  };

  final uri = Uri.https('nclt.gov.in', '/all-couse-list', queryParams);
  
  try {
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }

    final document = html_parser.parse(response.body);
    final table = document.querySelector('table');

    if (table == null) {
      throw Exception('No table found on the page.');
    }

    final headers = table.querySelectorAll('thead tr th').map((e) => e.text.trim()).toList();
    final rows = table.querySelectorAll('tbody tr');

    final List<Map<String, dynamic>> data = [];

    for (var row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;

      final Map<String, dynamic> rowData = {};
      for (int i = 0; i < cells.length && i < headers.length; i++) {
        final header = headers[i];
        final cell = cells[i];

        // Extract PDF links
        final anchor = cell.querySelector('a');
        if (anchor != null && anchor.attributes.containsKey('href')) {
          rowData[header] = {
            'label': anchor.text.trim(),
            'url': anchor.attributes['href']!,
          };
        } else {
          rowData[header] = cell.text.trim();
        }
      }
      data.add(rowData);
    }

    return data;
  } catch (e) {
    print('Error fetching or parsing Cause List: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> fetchNCLTDisplayBoardListTable(String locationId) async {
  final url = Uri.parse('https://nclt.gov.in/dBWeb/?locationCode=$locationId');

  try {
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }

    final document = html_parser.parse(response.body);

    // Select the specific table using its class
    final table = document.querySelector('table');

    if (table == null) {
      throw Exception('No matching table found on the page.');
    }

    // Extract headers
    final headers =
        table
            .querySelectorAll('thead tr th')
            .map((e) => e.text.trim())
            .toList();

    // Extract table rows
    final rows = table.querySelectorAll('tbody tr');

    final List<Map<String, dynamic>> tableData = [];

    for (var row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;

      final Map<String, dynamic> rowData = {};
      for (int i = 0; i < cells.length && i < headers.length; i++) {
        final header = headers[i];
        final cell = cells[i];

        // Extract links inside the "Action" column
        final anchor = cell.querySelector('a');
        if (anchor != null && anchor.attributes.containsKey('href')) {
          final href = anchor.attributes['href']!;
          final label = anchor.text.trim();
          rowData[header] = {'label': label, 'url': href};
        } else {
          // If Item No., Case No., or Cause Title are missing, set them to "Not In Session"
          if (['Item No.', 'Case No.', 'Cause Title'].contains(header)) {
            rowData[header] =
                cell.text.trim().isEmpty ? 'Not In Session' : cell.text.trim();
          } else {
            rowData[header] = cell.text.trim();
          }
        }
      }
      tableData.add(rowData);
    }

    return tableData;
  } catch (e) {
    print('Error fetching or parsing Display Board Table: $e');
    rethrow;
  }
}

/// Fetch CSRF Token from Cause List Page
Future<String?> fetchCsrfToken() async {
  final url = Uri.parse('https://efilingreat.up.gov.in/upreat/cause_list.php');

  try {
    final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0',
    });

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final tokenElement = document.querySelector('input[name="generate_token_csrf"]');
      return tokenElement?.attributes['value']; // Extract CSRF token
    } else {
      throw Exception('Failed to load CSRF token.');
    }
  } catch (e) {
    print('Error fetching CSRF token: $e');
    return null;
  }
}

/// Fetch Cause List Using CSRF Token
Future<void> fetchUpreatCauseList(String startDate, String endDate) async {
  final csrfToken = await fetchCsrfToken();
  if (csrfToken == null) {
    print('CSRF token retrieval failed.');
    return;
  }

  final url = Uri.parse('https://efilingreat.up.gov.in/upreat/ajax/ajax.php');

  try {
    final response = await http.post(
      url,
      headers: {
        'User-Agent': 'Mozilla/5.0',
        'Referer': 'https://efilingreat.up.gov.in/upreat/cause_list.php',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'action': 'case_status_datewise',
        'listing_date': startDate,
        'date_to': endDate,
        'token': csrfToken,
      },
    );

    if (response.statusCode == 200) {
      print('Cause List Response: ${response.body}');
    } else {
      throw Exception('Failed to fetch cause list.');
    }
  } catch (e) {
    print('Error fetching cause list: $e');
  }
}

Future<List<Map<String, dynamic>>> fetchNgtCauseListTable(String benchName, int page) async {
  final url = Uri.parse('https://greentribunal.gov.in/$benchName?page=$page');

  log("Fetching NGT Cause List for Bench: $benchName");
  log("Request URL: $url");

  try {
    // Create an HttpClient that ignores certificate errors
    final ioClient = IOClient(HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true);

    final response = await ioClient.get(url);
    log("Response Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final table = document.querySelector('table');

      if (table == null) {
        throw Exception('No table found for bench: $benchName');
      }

      final headers = table.querySelectorAll('thead tr th').map((e) => e.text.trim()).toList();
      final rows = table.querySelectorAll('tbody tr');

      final List<Map<String, dynamic>> data = [];

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty) continue;

        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          final cell = cells[i];

          final anchor = cell.querySelector('a');
          if (anchor != null && anchor.attributes.containsKey('href')) {
            final href = anchor.attributes['href']!;
            final label = anchor.text.trim();
            rowData[header] = {'label': label, 'url': href};
          } else {
            rowData[header] = cell.text.trim();
          }
        }
        data.add(rowData);
      }

      log("Fetched ${data.length} rows for bench: $benchName");
      return data;
    } else {
      throw Exception('Failed to load cause list. HTTP Status: ${response.statusCode}');
    }
  } catch (e) {
    log("Error fetching NGT cause list for bench: $benchName - $e");
    rethrow;
  }
}