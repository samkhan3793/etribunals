import 'package:etribunals/core/utils/cgit_client.dart';
import 'package:etribunals/core/utils/ncdrc_client.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:etribunals/data/services/hearing_reminder_service.dart';
import 'package:etribunals/data/services/local_storage_service.dart';

class BookmarkRefreshResult {
  final int checked;
  final int changed;
  const BookmarkRefreshResult({required this.checked, required this.changed});
}

class BookmarkRefreshService {
  static Future<BookmarkRefreshResult> refreshAll() async {
    final items = await LocalStorageService.getBookmarks();
    var changed = 0;
    var checked = 0;
    for (final item in items) {
      try {
        final next = await _nextDate(item);
        if (next == null) continue;
        checked += 1;
        final old = (item.nextHearing ?? '').trim();
        if (old == next) {
          await LocalStorageService.updateBookmark(item.copyWith(listingChanged: false, lastCheckedAt: DateTime.now().millisecondsSinceEpoch));
          continue;
        }
        changed += 1;
        await LocalStorageService.updateBookmark(
          item.copyWith(
            previousNextHearing: old.isEmpty ? null : old,
            nextHearing: next,
            listingChanged: true,
            lastCheckedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } catch (_) {}
    }
    if (changed > 0) {
      await HearingReminderService.instance.rescheduleAll();
    }
    return BookmarkRefreshResult(checked: checked, changed: changed);
  }

  static Future<String?> _nextDate(BookmarkedCase item) async {
    final key = item.caseNo.trim().isNotEmpty ? item.caseNo.trim() : item.filingNo.trim();
    if (key.isEmpty) return null;
    switch (item.tribunal.toUpperCase()) {
      case 'NCDRC':
        final rows = await NcdrcClient.instance.searchByCaseNumber(key);
        if (rows.isEmpty) return null;
        final hit = rows.first;
        return hit.hearingDate.isNotEmpty ? hit.hearingDate : (hit.orderDate.isNotEmpty ? hit.orderDate : null);
      case 'CGIT':
        final rows = await CgitClient.instance.causeList(caseNo: key);
        if (rows.isEmpty) return null;
        return rows.first.nextDate.isEmpty ? null : rows.first.nextDate;
      default:
        return null;
    }
  }
}
