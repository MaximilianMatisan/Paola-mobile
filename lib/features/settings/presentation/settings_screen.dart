// Settings: change nickname, toggle dark mode, choose the language, check
// timer notifications,

import 'package:flutter/material.dart';

import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/l10n/translations.dart';
import 'package:paola_mobile/core/network/api_exception.dart';
import 'package:paola_mobile/core/network/paola_api.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/core/style/theme.dart';
import 'package:paola_mobile/features/timer/util/timer_notification.dart';
import 'package:paola_mobile/core/widgets/delete_confirmation.dart';
import 'package:paola_mobile/features/auth/presentation/login_page.dart';

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
      _applyDarkMode(_darkMode);
      AppLanguage.set(Language.fromFlag(prefs['language']));
    } catch (e) {
      _showMessage((t) => t.settingsLoadFailed(_errorText(e)));
    }
  }

  String _errorText(Object e) =>
      e is ApiException ? e.message : context.t.noConnection;

  /// [text] picks the message from the current language's texts.
  void _showMessage(String Function(Translations t) text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text(context.t))));
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
      _showMessage((t) => t.nicknameSaved);
    } catch (e) {
      _showMessage((t) => t.nicknameSaveFailed(_errorText(e)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static void _applyDarkMode(bool enabled) =>
      AppTheme.mode.value = enabled ? ThemeMode.dark : ThemeMode.light;

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _darkMode = enabled);
    _applyDarkMode(enabled);
    try {
      await _api.setDarkMode(enabled);
    } catch (e) {
      if (mounted) setState(() => _darkMode = !enabled);
      _applyDarkMode(!enabled);
      _showMessage((t) => t.darkModeSaveFailed(_errorText(e)));
    }
  }

  /// Switches right away and reverts if the server can't store it.
  Future<void> _setLanguage(Language language) async {
    final previous = AppLanguage.current.value;
    if (language == previous) return;
    await AppLanguage.set(language);
    try {
      await _api.setLanguage(language);
    } catch (e) {
      await AppLanguage.set(previous);
      _showMessage((t) => t.languageSaveFailed(_errorText(e)));
    }
  }

  Future<void> _requestDeletion() async {
    final confirmed = await confirmDelete(
      context,
      title: context.t.deleteDataTitle,
      message: context.t.deleteDataMessage,
      confirmLabel: context.t.request,
    );
    if (!confirmed || !mounted) return;
    setState(() => _requestingDeletion = true);
    try {
      await _api.requestDeletion();
      _showMessage((t) => t.deletionRequested);
    } catch (e) {
      _showMessage((t) => t.deletionRequestFailed(_errorText(e)));
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
    final t = context.t;
    final name = _user?.nickname ?? '';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            ScreenTitle(t.settingsTitle),
            _Group(
              label: t.profile,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          PaolaRadius.control,
                        ),
                      ),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RowText(
                        title: name.isEmpty ? '…' : name,
                        subtitle: t.loggedIn,
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
                        hint: t.nickname,
                        onSubmitted: (_) => _saveNickname(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PaolaButton(
                      label: _saving ? t.saving : t.save,
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
              label: t.appearance,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _RowText(
                        title: t.darkMode,
                        subtitle: t.darkModeDesc,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Toggle(value: _darkMode, onChanged: _setDarkMode),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _RowText(
                        title: t.language,
                        subtitle: t.languageDesc,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _LanguagePicker(
                      value: AppLanguage.current.value,
                      onChanged: _setLanguage,
                    ),
                  ],
                ),
              ],
            ),
            if (_notifications case final status?)
              _Group(
                label: t.notifications,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RowText(
                          title: t.timerNotifications,
                          subtitle: status == NotificationStatus.allowed
                              ? t.timerNotificationsOn
                              : t.timerNotificationsOff,
                        ),
                      ),
                      if (status != NotificationStatus.allowed) ...[
                        const SizedBox(width: 12),
                        PaolaButton(
                          label: t.turnOn,
                          style: PaolaButtonStyle.secondary,
                          onPressed: _allowNotifications,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            _Group(
              label: t.dataPrivacy,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _RowText(
                        title: t.deleteMyData,
                        subtitle: t.deleteMyDataDesc,
                      ),
                    ),
                    const SizedBox(width: 12),
                    PaolaButton(
                      label: _requestingDeletion ? t.requesting : t.request,
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
                label: Text(t.logOut, style: const TextStyle(fontSize: 16)),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textPrimary,
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
            color: context.colors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _NicknameField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  const _NicknameField({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
  });

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
        cursorColor: context.colors.primary,
        style: TextStyle(fontSize: 15, color: context.colors.textInput),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: context.colors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: context.colors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: context.colors.primary),
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
            color: value ? context.colors.primary : context.colors.track,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented switch between the languages, styled like the timer's mode
/// toggle. Each language is shown in itself, so it can always be found.
class _LanguagePicker extends StatelessWidget {
  final Language value;
  final ValueChanged<Language> onChanged;

  const _LanguagePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.line),
        borderRadius: BorderRadius.circular(PaolaRadius.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final language in Language.values)
            Semantics(
              selected: language == value,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(language),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: language == value
                      ? context.colors.textPrimary
                      : context.colors.surface,
                  child: Text(
                    language.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: language == value
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: language == value
                          ? context.colors.onTextPrimary
                          : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
