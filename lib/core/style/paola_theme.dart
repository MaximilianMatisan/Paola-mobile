import 'package:flutter/material.dart';

// 1. PaolaPalette: the raw colour values, named by hue and shade (50 = lightest … 950 = darkest)
// 2. PaolaColors: what each colour is for, once for light and once for dark
//    mode. Read them with `context.colors`.

/// Raw colour values. Only referenced by [PaolaColors].
abstract final class PaolaPalette {
  // Neutrals
  static const neutral50 = Color(0xFFF6F6F4);
  static const neutral100 = Color(0xFFECEDE9);
  static const neutral200 = Color(0xFFE2E3DF);
  static const neutral300 = Color(0xFFDADCD7);

  // Greys
  static const grey400 = Color(0xFF9A9E97);
  static const grey500 = Color(0xFF6C706A);
  static const grey700 = Color(0xFF363934);
  static const grey800 = Color(0xFF2B2E2A);
  static const grey900 = Color(0xFF1C1E1B);
  static const grey950 = Color(0xFF121411);

  // Greens
  static const green50 = Color(0xFFE6F2EA);
  static const green200 = Color(0xFF6FCB92);
  static const green300 = Color(0xFF3FB46C);
  static const green400 = Color(0xFF2FA862);
  static const green600 = Color(0xFF1E8A4C);
  static const green800 = Color(0xFF166B3A);
  static const green900 = Color(0xFF1C2E22);
  static const green950 = Color(0xFF0C1A11);

  // Reds
  static const red50 = Color(0xFFFBEAE7);
  static const red400 = Color(0xFFE5624F);
  static const red600 = Color(0xFFD2412F);
  static const red900 = Color(0xFF3A201C);

  // Black & white
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const black35 = Color(0x59000000); // 35 % opacity
  static const black60 = Color(0x99000000); // 60 % opacity
}

/// Colour roles used throughout the app.
@immutable
class PaolaColors extends ThemeExtension<PaolaColors> {
  // Surfaces
  /// Page background.
  final Color background;

  /// Cards, inputs, secondary buttons, nav bar.
  final Color surface;

  /// 1 px lines: borders, dividers.
  final Color line;

  /// Empty part of the timer ring, timeline and switch.
  final Color track;

  // Brand / primary actions
  final Color primary;

  /// Light tint behind primary content (avatar).
  final Color primaryContainer;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Login screen button (kept subtle: two close greens).
  final LinearGradient primaryGradient;

  // Text
  final Color textPrimary;
  final Color textSecondary;

  /// Text and icons on [textPrimary] (selected mode).
  final Color onTextPrimary;

  /// Text typed into input fields.
  final Color textInput;
  final Color link;

  // States & outlines
  final Color border;
  final Color error;

  /// Text and icons on [error] (confirm button of the delete dialog).
  final Color onError;

  /// Light tint behind destructive content (movement countdown).
  final Color errorContainer;

  /// Dims the screen behind dialogs.
  final Color scrim;

  const PaolaColors({
    required this.background,
    required this.surface,
    required this.line,
    required this.track,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.primaryGradient,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTextPrimary,
    required this.textInput,
    required this.link,
    required this.border,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.scrim,
  });

  static const light = PaolaColors(
    background: PaolaPalette.neutral50,
    surface: PaolaPalette.white,
    line: PaolaPalette.neutral200,
    track: PaolaPalette.neutral300,
    primary: PaolaPalette.green600,
    primaryContainer: PaolaPalette.green50,
    onPrimary: PaolaPalette.white,
    primaryGradient: LinearGradient(
      colors: [PaolaPalette.green400, PaolaPalette.green600],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: PaolaPalette.grey900,
    textSecondary: PaolaPalette.grey500,
    onTextPrimary: PaolaPalette.white,
    textInput: PaolaPalette.black,
    link: PaolaPalette.green800,
    border: PaolaPalette.grey500,
    error: PaolaPalette.red600,
    onError: PaolaPalette.white,
    errorContainer: PaolaPalette.red50,
    scrim: PaolaPalette.black35,
  );

  /// Green-grey darks; primary and error are lighter so they stand out, with
  /// dark text on them.
  static const dark = PaolaColors(
    background: PaolaPalette.grey950,
    surface: PaolaPalette.grey900,
    line: PaolaPalette.grey800,
    track: PaolaPalette.grey700,
    primary: PaolaPalette.green300,
    primaryContainer: PaolaPalette.green900,
    onPrimary: PaolaPalette.green950,
    primaryGradient: LinearGradient(
      colors: [PaolaPalette.green200, PaolaPalette.green300],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: PaolaPalette.neutral100,
    textSecondary: PaolaPalette.grey400,
    onTextPrimary: PaolaPalette.grey950,
    textInput: PaolaPalette.white,
    link: PaolaPalette.green200,
    border: PaolaPalette.grey400,
    error: PaolaPalette.red400,
    onError: PaolaPalette.grey950,
    errorContainer: PaolaPalette.red900,
    scrim: PaolaPalette.black60,
  );

  @override
  PaolaColors copyWith() => this;

  @override
  PaolaColors lerp(PaolaColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PaolaColors(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      line: c(line, other.line),
      track: c(track, other.track),
      primary: c(primary, other.primary),
      primaryContainer: c(primaryContainer, other.primaryContainer),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      onTextPrimary: c(onTextPrimary, other.onTextPrimary),
      textInput: c(textInput, other.textInput),
      link: c(link, other.link),
      border: c(border, other.border),
      error: c(error, other.error),
      onError: c(onError, other.onError),
      errorContainer: c(errorContainer, other.errorContainer),
      scrim: c(scrim, other.scrim),
    );
  }
}

extension PaolaColorsContext on BuildContext {
  /// The [PaolaColors] of the current theme (light or dark).
  PaolaColors get colors => Theme.of(this).extension<PaolaColors>()!;
}

/// Corner radii: small on controls, a bit larger on cards.
abstract final class PaolaRadius {
  static const control = 4.0;
  static const card = 8.0;
}

/// Flat white card with a 1 px line.
class PaolaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PaolaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.line),
        borderRadius: BorderRadius.circular(PaolaRadius.card),
      ),
      child: child,
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const GradientText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => context.colors.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

enum PaolaButtonStyle { primary, secondary, danger, dangerFilled }

/// 40 px button: filled green (primary), white with a line (secondary), red
/// text only (danger) or filled red (dangerFilled, confirms a deletion).
class PaolaButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final PaolaButtonStyle style;
  final VoidCallback? onPressed;

  const PaolaButton({
    super.key,
    required this.label,
    this.icon,
    this.style = PaolaButtonStyle.primary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (style) {
      PaolaButtonStyle.primary => (context.colors.primary, context.colors.onPrimary),
      PaolaButtonStyle.secondary => (
        context.colors.surface,
        context.colors.textPrimary,
      ),
      PaolaButtonStyle.danger => (null, context.colors.error),
      PaolaButtonStyle.dangerFilled => (context.colors.error, context.colors.onError),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PaolaRadius.control),
      side: style == PaolaButtonStyle.secondary
          ? BorderSide(color: context.colors.line)
          : BorderSide.none,
    );
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: background ?? Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onPressed,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Left-aligned screen title, optionally with a back chevron.
class ScreenTitle extends StatelessWidget {
  final String text;
  final VoidCallback? onBack;

  const ScreenTitle(this.text, {super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkResponse(
              onTap: onBack,
              radius: 20,
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        Text(
          text,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Small grey label above a group ("Profile", "Today").
class GroupLabel extends StatelessWidget {
  final String text;

  const GroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: context.colors.textSecondary,
      ),
    );
  }
}

/// 1 px divider line.
class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.colors.line);
}
