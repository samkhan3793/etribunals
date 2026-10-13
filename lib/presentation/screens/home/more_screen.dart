import 'dart:io';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/constants/app_help.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/data/services/hearing_reminder_service.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  List<Map<String, String>> _files = [];
  String _version = '';
  bool _reminders = true;
  bool _osAlerts = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final files = await LocalStorageService.getOpenedFiles();
    final info = await PackageInfo.fromPlatform();
    final reminders = await LocalStorageService.remindersEnabled();
    final osAlerts = await HearingReminderService.instance.osNotificationsOn();
    if (!mounted) return;
    setState(() {
      _files = files;
      _version = '${info.version} (${info.buildNumber})';
      _reminders = reminders;
      _osAlerts = osAlerts;
    });
  }

  void _openText(String title, String body) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _HelpPage(title: title, body: body),
      ),
    );
  }

  void _openFaq() {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _FaqPage()));
  }

  Future<void> _setReminders(bool on) async {
    setState(() => _reminders = on);
    await LocalStorageService.setRemindersEnabled(on);
    await HearingReminderService.instance.rescheduleAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(on ? 'Reminders on · 7:00 pm previous day and 8:00 am listing day' : 'Hearing reminders off')),
    );
  }

  Future<bool> _confirm({required String title, required String body, required String action}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
        content: Text(body, style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action, style: const TextStyle(color: AppColors.stampRed, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _unfollowAll() async {
    final ok = await _confirm(
      title: 'Unfollow all cases?',
      body: 'Saved matters will be removed from this phone. This cannot be undone.',
      action: 'Unfollow all',
    );
    if (!ok) return;
    await LocalStorageService.clearAllBookmarks();
    await HearingReminderService.instance.rescheduleAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All followed cases removed')));
  }

  Future<void> _clearPdfs() async {
    final ok = await _confirm(
      title: 'Delete saved PDFs?',
      body: 'Files this app saved on the phone will be deleted, and the list on More will be cleared.',
      action: 'Delete PDFs',
    );
    if (!ok) return;
    await LocalStorageService.clearSavedPdfs();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved PDFs cleared')));
  }

  Future<void> _shareApp() {
    return Share.share('${AppHelp.shareApp}\n${AppHelp.playUrl}');
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse(AppHelp.privacyUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      await _openText('Privacy', AppHelp.privacy);
    }
  }

  Future<void> _openPlay() async {
    final uri = Uri.parse(AppHelp.playUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Play Store.')));
    }
  }

  Future<void> _reportIssue() async {
    final subject = Uri.encodeComponent('eTribunals issue');
    final body = Uri.encodeComponent('What went wrong:\n\nTribunal:\n\nApp version: $_version\n');
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app found. Note the issue and try again from a mail app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'eTribunals',
            subtitle: 'Independent companion to public tribunal sites',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              child: SwitchListTile(
                value: _reminders,
                onChanged: _setReminders,
                activeThumbColor: AppColors.accent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: const Text('Hearing reminders', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                subtitle: const Text(
                  '8:00 am on a saved listing day. Not a court notice.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                secondary: const Icon(Icons.notifications_outlined, color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0x3314384A)),
                ),
              ),
            ),
          ),
          if (!_osAlerts)
            _tile(
              icon: Icons.notifications_off_outlined,
              title: 'Allow alerts',
              subtitle: 'Android has blocked notifications for this app',
              onTap: () async {
                await HearingReminderService.instance.requestPermission();
                await _load();
              },
            ),
          _tile(
            icon: Icons.notification_add_outlined,
            title: 'Send a test alert',
            subtitle: 'Confirms permission and the reminder channel',
            onTap: () async {
              await HearingReminderService.instance.sendTest();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test alert sent. Check the shade, then tap it.')),
              );
            },
          ),
          _tile(
            icon: Icons.auto_awesome_outlined,
            title: 'What’s new',
            subtitle: 'AI Summarize, share, save PDF',
            onTap: () => _openText('What’s new', AppHelp.whatsNew),
          ),
          _tile(
            icon: Icons.share_outlined,
            title: 'Share eTribunals',
            subtitle: 'Send a short note about this app',
            onTap: _shareApp,
          ),
          _tile(
            icon: Icons.shop_outlined,
            title: 'Play Store listing',
            subtitle: 'Opens this app’s Play page when it is live',
            onTap: _openPlay,
          ),
          _tile(
            icon: Icons.help_outline,
            title: 'Help & FAQ',
            subtitle: 'AI Summarize, bookmarks, PDFs, reminders, official site',
            onTap: _openFaq,
          ),
          _tile(
            icon: Icons.gavel_outlined,
            title: 'Disclaimer',
            subtitle: 'Not a government app. Verify before you file.',
            onTap: () => _openText('Disclaimer', AppHelp.disclaimer),
          ),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            subtitle: 'Opens the full privacy policy on the web',
            onTap: _openPrivacy,
          ),
          _tile(
            icon: Icons.info_outline,
            title: 'Official sources',
            subtitle: AppHelp.sources,
            onTap: () => _openText('Official sources', AppHelp.sources),
          ),
          _tile(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'Report a problem',
            subtitle: 'Opens your email app with a short template',
            onTap: _reportIssue,
          ),
          _tile(
            icon: Icons.bookmark_remove_outlined,
            title: 'Unfollow all cases',
            subtitle: 'Removes bookmarks from this phone',
            onTap: _unfollowAll,
          ),
          _tile(
            icon: Icons.delete_outline,
            title: 'Delete saved PDFs',
            subtitle: 'Clears files this app saved locally',
            onTap: _clearPdfs,
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Saved PDFs on this phone', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            ..._files.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0x3314384A)),
                    ),
                    leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accent),
                    title: Text(
                      f['title'] ?? 'PDF',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () async {
                      final path = f['path'] ?? '';
                      final file = File(path);
                      if (!await file.exists()) return;
                      if (!context.mounted) return;
                      final bytes = await file.readAsBytes();
                      if (!context.mounted) return;
                      await InAppDocumentScreen.open(
                        context,
                        path,
                        title: f['title'] ?? 'PDF',
                        pdfBytes: bytes,
                        showOfficialLink: false,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            _version.isEmpty ? 'eTribunals' : 'eTribunals  ·  $_version',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          const Text(
            'Data from live court sites  ·  always verify on the source',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x3314384A)),
          ),
          leading: Icon(icon, color: AppColors.accent),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right, color: AppColors.textMuted),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        ),
      ),
    );
  }
}

class _HelpPage extends StatelessWidget {
  final String title;
  final String body;
  const _HelpPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Text(
                body,
                style: const TextStyle(fontSize: 14.5, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqPage extends StatelessWidget {
  const _FaqPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Quick answers',
            subtitle: 'Tap a question. Keep the official site as the source of truth.',
            icon: Icons.help_outline,
          ),
          const SizedBox(height: 12),
          for (final faq in AppHelp.faqs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    title: Text(
                      faq.$1,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                    ),
                    children: [
                      Text(
                        faq.$2,
                        style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
