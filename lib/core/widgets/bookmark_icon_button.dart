import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:etribunals/data/services/hearing_reminder_service.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BookmarkIconButton extends StatefulWidget {
  final BookmarkedCase caseItem;
  final Color iconColor;

  const BookmarkIconButton({
    super.key,
    required this.caseItem,
    this.iconColor = Colors.white,
  });

  @override
  State<BookmarkIconButton> createState() => _BookmarkIconButtonState();
}

class _BookmarkIconButtonState extends State<BookmarkIconButton> {
  bool _saved = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await LocalStorageService.addRecent(widget.caseItem);
    final saved = await LocalStorageService.isBookmarked(widget.caseItem.id);
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    await LocalStorageService.toggleBookmark(
      widget.caseItem.copyWith(savedAt: DateTime.now().millisecondsSinceEpoch),
    );
    final saved = await LocalStorageService.isBookmarked(widget.caseItem.id);
    await HearingReminderService.instance.rescheduleAll();
    if (!mounted) return;
    setState(() => _saved = saved);
    Fluttertoast.showToast(
      msg: saved ? 'Case saved to My Cases' : 'Removed from My Cases',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return IconButton(
        onPressed: null,
        icon: Icon(Icons.bookmark_border, color: widget.iconColor),
      );
    }
    return IconButton(
      tooltip: _saved ? 'Remove bookmark' : 'Save case',
      onPressed: _toggle,
      icon: Icon(
        _saved ? Icons.bookmark : Icons.bookmark_border,
        color: widget.iconColor,
      ),
    );
  }
}
