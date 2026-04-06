import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BottomSheetContent extends StatefulWidget {
  final Function(String courtName, String startDate, String? endDate) onFilterApplied;
  final DateTime defaultStartDate;
  final DateTime? defaultEndDate;
  final List<Map<String, String>>? courtList; // Optional court list
  final bool showDropdown; // Control dropdown visibility
  final bool showStartDate; // Control start date visibility
  final bool showEndDate; // Control end date visibility

  const BottomSheetContent({
    super.key,
    required this.onFilterApplied,
    required this.defaultStartDate,
    this.defaultEndDate,
    this.courtList, // Now optional
    this.showDropdown = true, // Default to true
    this.showStartDate = true, // Default to true
    this.showEndDate = true, // Default to true
  });

  @override
  _BottomSheetContentState createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  String? _selectedOption = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.defaultStartDate;
    _endDate = widget.defaultEndDate;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    try {
      DateTime defaultStart = widget.defaultStartDate;
      DateTime initialDate = isStartDate ? (_startDate ?? defaultStart) : (_endDate ?? defaultStart.add(const Duration(days: 30)));
      DateTime firstDate = isStartDate ? DateTime(2016, 1, 1) : (_startDate ?? DateTime(2016, 1, 1));
      DateTime lastDate = isStartDate ? DateTime.now() : (_startDate!.add(const Duration(days: 30)));

      if (lastDate.isBefore(firstDate)) {
        lastDate = firstDate.add(const Duration(days: 30));
      }

      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );

      if (picked != null) {
        setState(() {
          if (isStartDate) {
            _startDate = picked;
            if (widget.showEndDate) {
              _endDate = picked.add(const Duration(days: 30));
            }
          } else {
            _endDate = picked;
          }
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error selecting date: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

 void _applyFilter() {
  try {
    if (widget.showDropdown && (_selectedOption == null || _selectedOption!.isEmpty)) {
      Fluttertoast.showToast(msg: 'Please select a court.', backgroundColor: Colors.red);
      return;
    }

    // Ensure start date is non-null if required
    if (widget.showStartDate && _startDate == null) {
      Fluttertoast.showToast(msg: 'Please select a start date.', backgroundColor: Colors.red);
      return;
    }

    // Ensure end date is non-null if required
    if (widget.showEndDate && _endDate == null) {
      Fluttertoast.showToast(msg: 'Please select an end date.', backgroundColor: Colors.red);
      return;
    }

    // Prevent invalid date selection where end date is before start date
    if (widget.showStartDate && widget.showEndDate && _endDate != null && _startDate != null && _endDate!.isBefore(_startDate!)) {
      Fluttertoast.showToast(msg: 'End date cannot be before the start date.', backgroundColor: Colors.red);
      return;
    }

    // Assign safe default values instead of allowing null
    String safeStartDate = _startDate != null ? _startDate!.toLocal().toString().split(' ')[0] : '';
    String? safeEndDate = widget.showEndDate && _endDate != null ? _endDate!.toLocal().toString().split(' ')[0] : null;

    widget.onFilterApplied(_selectedOption ?? 'All', safeStartDate, safeEndDate ?? '');
  // debugPrint("Selected Court: $_selectedOption, Start Date: $safeStartDate, End Date: $safeEndDate"); // Debugging for deeper insights
    Navigator.pop(context);
  } catch (e) {
    debugPrint("Error applying filter: ${e.toString()}"); // Debugging for deeper insights
    Fluttertoast.showToast(msg: 'Error applying filter: ${e.toString()}', backgroundColor: Colors.red);
  }
}


  @override
  Widget build(BuildContext context) {
    // Log courtList for debugging
    debugPrint('courtList: ${widget.courtList}');

    return Container(
      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Search and Filter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            // Only show dropdown if `showDropdown` is true
            if (widget.showDropdown)
              CustomDropdown(
                label: 'Select Court',
                selectedValue: _selectedOption,
                items: widget.courtList ?? [],
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value;
                  });
                },
              ),

            if (widget.showStartDate) ...[
              const SizedBox(height: 16),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context, true)),
                ),
                controller: TextEditingController(
                  text: _startDate != null ? _startDate!.toLocal().toString().split(' ')[0] : '',
                ),
              ),
            ],

            if (widget.showEndDate) ...[
              const SizedBox(height: 16),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context, false)),
                ),
                controller: TextEditingController(
                  text: _endDate != null ? _endDate!.toLocal().toString().split(' ')[0] : '',
                ),
              ),
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
              onPressed: _applyFilter,
              child: const Text('Apply Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
