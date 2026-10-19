// Settings: change nickname, toggle dark mode, check timer notifications,

import 'package:flutter/material.dart';

import 'package:interactive_notifications/core/network/api_exception.dart';
import 'package:interactive_notifications/core/network/paola_api.dart';
import 'package:interactive_notifications/core/style/paola_theme.dart';
import 'package:interactive_notifications/features/timer/util/timer_notification.dart';
import 'package:interactive_notifications/core/widgets/delete_confirmation.dart';
import 'package:interactive_notifications/features/auth/presentation/login_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _api = PaolaApi.instance;
  final _nickname = TextEditingController();

  AppUser? _user;
  bool _darkMode = false;
  bool _saving = false;
  bool _requestingDeletion = false;
  NotificationStatus? _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _loadNotificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nickname.dispose();
    super.dispose();
  }

  // Coming back from the system notification settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    if (!TimerNotification.supported) return;
    final status = await TimerNotification.status();
    if (mounted) setState(() => _notifications = status);
  }

  Future<void> _allowNotifications() async {
    final status = await TimerNotification.allow();
    if (mounted) setState(() => _notifications = status);
  }

  Future<void> _load() async {
    try {
      final (user, prefs) = await (_api.currentUser(), _api.preferences()).wait;
      if (!mounted) return;
      setState(() {
        _user = user;
        _nickname.text = user?.nickname ?? '';
        _darkMode = prefs['dark_mode'] == 1 || prefs['dark_mode'] == true;
      });
    } catch (e) {
      _showMessage('Could not load settings: ${_errorText(e)}');
    }
  }

  static String _errorText(Object e) =>
      e is ApiException ? e.message : 'No connection to the server';

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _saveNickname() async {
    final user = _user;
    final name = _nickname.text.trim();
    if (user == null || name.isEmpty || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await _api.updateNickname(user.id, name);
      if (!mounted) return;
      setState(() => _user = AppUser(id: user.id, nickname: name));
      _showMessage('Nickname saved');
    } catch (e) {
      _showMessage('Could not save nickname: ${_errorText(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _darkMode = enabled);
    try {
      await _api.setDarkMode(enabled);
    } catch (e) {
      if (mounted) setState(() => _darkMode = !enabled);
      _showMessage('Could not save dark mode: ${_errorText(e)}');
    }
  }

  Future<void> _requestDeletion() async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete your data?',
      message:
          'Your account will be marked for deletion and all your stored '
          "learning data will be removed. This can't be undone.",
      confirmLabel: 'Request',
    );
    if (!confirmed || !mounted) return;
    setState(() => _requestingDeletion = true);
    try {
      await _api.requestDeletion();
      _showMessage('Deletion requested');
    } catch (e) {
      _showMessage('Could not request deletion: ${_errorText(e)}');
    } finally {
      if (mounted) setState(() => _requestingDeletion = false);
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.nickname ?? '';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Scaffold(
      backgroundColor: PaolaColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            const ScreenTitle('Settings'),
            _Group(
              label: 'Profile',
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: PaolaColors.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          PaolaRadius.control,
                        ),
                      ),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PaolaColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RowText(
                        title: name.isEmpty ? '…' : name,
                        subtitle: 'Logged in',
                        bold: true,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _NicknameField(
                        controller: _nickname,
                        onSubmitted: (_) => _saveNickname(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PaolaButton(
                      label: _saving ? 'Saving…' : 'Save',
                      style: PaolaButtonStyle.secondary,
                      onPressed: _user == null || _saving
                          ? null
                          : _saveNickname,
                    ),
                  ],
                ),
              ],
            ),
            _Group(
              label: 'Appearance',
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: _RowText(
                        title: 'Dark mode',
                        subtitle: 'Use a dark color scheme',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Toggle(value: _darkMode, onChanged: _setDarkMode),
                  ],
                ),
              ],
            ),
            if (_notifications case final status?)
              _Group(
                label: 'Notifications',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RowText(
                          title: 'Timer notifications',
                          subtitle: status == NotificationStatus.allowed
                              ? 'On: lock screen timer and end alerts'
                              : "Off: the lock screen timer and end alerts won't show",
                        ),
                      ),
                      if (status != NotificationStatus.allowed) ...[
                        const SizedBox(width: 12),
                        PaolaButton(
                          label: 'Turn on',
                          style: PaolaButtonStyle.secondary,
                          onPressed: _allowNotifications,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            _Group(
              label: 'Data and privacy',
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: _RowText(
                        title: 'Delete my data',
                        subtitle:
                            'Remove all recorded data.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    PaolaButton(
                      label: _requestingDeletion ? 'Requesting…' : 'Request',
                      style: PaolaButtonStyle.danger,
                      onPressed: _requestingDeletion ? null : _requestDeletion,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log out', style: TextStyle(fontSize: 16)),
                style: TextButton.styleFrom(
                  foregroundColor: PaolaColors.textPrimary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grey label, the rows below it and a line underneath.
class _Group extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Group({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GroupLabel(label),
          for (final child in children) ...[const SizedBox(height: 12), child],
          const SizedBox(height: 16),
          const Hairline(),
        ],
      ),
    );
  }
}

/// Title with a smaller grey line below.
class _RowText extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool bold;

  const _RowText({
    required this.title,
    required this.subtitle,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
            color: PaolaColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: PaolaColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _NicknameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _NicknameField({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(PaolaRadius.control));
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        expands: true,
        maxLines: null,
        textAlignVertical: TextAlignVertical.center,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.done,
        cursorColor: PaolaColors.primary,
        style: const TextStyle(fontSize: 15, color: PaolaColors.textInput),
        decoration: const InputDecoration(
          hintText: 'Nickname',
          isDense: true,
          filled: true,
          fillColor: PaolaColors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: PaolaColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: PaolaColors.primary),
          ),
        ),
      ),
    );
  }
}

/// Small on/off switch.
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 20,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? PaolaColors.primary : PaolaColors.track,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: PaolaColors.surface,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
