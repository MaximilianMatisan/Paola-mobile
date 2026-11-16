// Settings: change nickname, toggle dark mode, choose the language, hide the
// timer's time, check timer notifications and set up the (optional) web app
// connection. Everything except the web app part is stored on the device.

import 'package:flutter/material.dart';

import 'package:paola_mobile/core/data/local_settings.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/l10n/translations.dart';
import 'package:paola_mobile/core/network/api_exception.dart';
import 'package:paola_mobile/core/network/paola_api.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/core/style/theme.dart';
import 'package:paola_mobile/core/util/constants.dart';
import 'package:paola_mobile/features/timer/util/hide_time.dart';
import 'package:paola_mobile/features/timer/util/timer_notification.dart';
import 'package:paola_mobile/core/widgets/delete_confirmation.dart';
import 'package:paola_mobile/core/widgets/page_help.dart';
import 'package:paola_mobile/features/auth/presentation/login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _api = PaolaApi.instance;
  final _nickname = TextEditingController(text: LocalSettings.nickname.value);

  /// In the order they are offered: automatic, light, dark.
  static const _themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  bool _requestingDeletion = false;
  NotificationStatus? _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final name = _nickname.text.trim();
    if (name.isEmpty) return;
    FocusScope.of(context).unfocus();
    await LocalSettings.setNickname(name);
    if (mounted) setState(() {});
    _showMessage((t) => t.nicknameSaved);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await LocalSettings.setThemeMode(mode);
    if (mounted) setState(() {});
  }

  Future<void> _setLanguage(Language language) => AppLanguage.set(language);

  /// Opens the login for the web app.
  Future<void> _connectWebApp() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
    if (mounted) setState(() {});
  }

  /// Forgets the web app session; the data on the device stays.
  Future<void> _disconnectWebApp() async {
    await _api.logout();
    if (mounted) setState(() {});
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

  /// Opens an empty mail to [email] in the phone's mail app.
  Future<void> _contact(String email) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'mailto', path: email));
    } catch (_) {
      // No mail app that could take it; reported below.
    }
    if (!opened) _showMessage((t) => t.contactNoMailApp(email));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final name = LocalSettings.nickname.value;
    final connected = _api.loggedIn;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: PageHelpButton(
        help: PageHelpContent(
          title: t.helpSettingsTitle,
          intro: t.helpSettingsIntro,
          bullets: t.helpSettingsBullets,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            PageHelpButton.bottomSpace,
          ),
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
                        title: name.isEmpty ? t.nickname : name,
                        subtitle: t.savedOnDevice,
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
                      label: t.save,
                      style: PaolaButtonStyle.secondary,
                      onPressed: _saveNickname,
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
                        title: t.colorScheme,
                        subtitle: t.colorSchemeDesc,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SegmentPicker<ThemeMode>(
                      values: _themeModes,
                      value: AppTheme.mode.value,
                      onChanged: _setThemeMode,
                      builder: (mode, color, _) => Icon(
                        switch (mode) {
                          ThemeMode.system => Icons.autorenew,
                          ThemeMode.light => Icons.light_mode_outlined,
                          ThemeMode.dark => Icons.dark_mode_outlined,
                        },
                        size: _SegmentPicker.iconSize,
                        color: color,
                      ),
                    ),
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
                    _SegmentPicker<Language>(
                      values: Language.values,
                      value: AppLanguage.current.value,
                      onChanged: _setLanguage,
                      builder: (language, color, selected) => Text(
                        language.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _Group(
              label: t.timerTitle,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _RowText(
                        title: t.hideTime,
                        subtitle: t.hideTimeDesc,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ListenableBuilder(
                      listenable: HideTime.enabled,
                      builder: (context, _) => _Toggle(
                        value: HideTime.enabled.value,
                        onChanged: HideTime.set,
                      ),
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
              label: t.webApp,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _RowText(
                        title: t.webApp,
                        subtitle: connected
                            ? t.webAppConnected(_api.serverUrl)
                            : t.webAppNotConnected,
                      ),
                    ),
                    const SizedBox(width: 12),
                    PaolaButton(
                      label: connected ? t.disconnect : t.setUp,
                      style: PaolaButtonStyle.secondary,
                      onPressed: connected ? _disconnectWebApp : _connectWebApp,
                    ),
                  ],
                ),
                // Deletion is done by the researchers on the web app.
                if (connected)
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
                        onPressed: _requestingDeletion
                            ? null
                            : _requestDeletion,
                      ),
                    ],
                  ),
              ],
            ),
            // Only with CONTACT_EMAIL in .env.
            if (contactEmail case final email?)
              _Group(
                label: t.contact,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RowText(
                          title: t.contact,
                          subtitle: t.contactDesc,
                        ),
                      ),
                      const SizedBox(width: 12),
                      PaolaButton(
                        label: t.contactWrite,
                        style: PaolaButtonStyle.secondary,
                        onPressed: () => _contact(email),
                      ),
                    ],
                  ),
                ],
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

/// Segmented switch between a few [values], styled like the timer's mode
/// toggle. [builder] draws a value in the given colour.
class _SegmentPicker<T> extends StatelessWidget {
  static const iconSize = 18.0;

  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final Widget Function(T value, Color color, bool selected) builder;

  const _SegmentPicker({
    required this.values,
    required this.value,
    required this.onChanged,
    required this.builder,
  });

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
          for (final option in values)
            Semantics(
              selected: option == value,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: option == value
                      ? context.colors.textPrimary
                      : context.colors.surface,
                  child: builder(
                    option,
                    option == value
                        ? context.colors.onTextPrimary
                        : context.colors.textSecondary,
                    option == value,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
