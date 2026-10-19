import 'package:flutter/material.dart';

// Colours come in two layers:
//
// 1. PaolaPalette: the raw colour values, named by hue and shade
//    (50 = lightest … 900 = darkest), never by where they are used.
//    Change or swap these to re-skin the app.
// 2. PaolaColors: what each colour is *for* (background, primary, text…),
//    pointing into the palette. Screens only ever use these roles, so a role
//    can be repointed without touching any screen.
//
// To add a colour: add the value to PaolaPalette, then a role for it in
// PaolaColors. Don't use Color(...) or Colors.* outside this file.
//
// The values follow the "Minimal" variables of the Figma file: flat
// surfaces, 1 px lines, no gradients or shadows.

/// Raw colour values. Only referenced by [PaolaColors].
abstract final class PaolaPalette {
  // Neutrals
  static const neutral50 = Color(0xFFF6F6F4);
  static const neutral200 = Color(0xFFE2E3DF);
  static const neutral300 = Color(0xFFDADCD7);

  // Greys
  static const grey500 = Color(0xFF6C706A);
  static const grey900 = Color(0xFF1C1E1B);

  // Greens
  static const green50 = Color(0xFFE6F2EA);
  static const green400 = Color(0xFF2FA862);
  static const green600 = Color(0xFF1E8A4C);
  static const green800 = Color(0xFF166B3A);

  // Reds
  static const red50 = Color(0xFFFBEAE7);
  static const red600 = Color(0xFFD2412F);

  // Black & white
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const black35 = Color(0x59000000); // 35 % opacity
}

/// Colour roles used throughout the app.
abstract final class PaolaColors {
  // Surfaces
  /// Page background.
  static const background = PaolaPalette.neutral50;

  /// Cards, inputs, secondary buttons, nav bar.
  static const surface = PaolaPalette.white;

  /// 1 px lines: borders, dividers.
  static const line = PaolaPalette.neutral200;

  /// Empty part of the timer ring, timeline and switch.
  static const track = PaolaPalette.neutral300;

  // Brand / primary actions
  static const primary = PaolaPalette.green600;

  /// Light tint behind primary content (avatar).
  static const primaryContainer = PaolaPalette.green50;

  /// Text and icons on [primary].
  static const onPrimary = PaolaPalette.white;

  /// Login screen button (kept subtle: two close greens).
  static const primaryGradient = LinearGradient(
    colors: [PaolaPalette.green400, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text
  static const textPrimary = PaolaPalette.grey900;
  static const textSecondary = PaolaPalette.grey500;

  /// Text and icons on [textPrimary] (selected mode).
  static const onTextPrimary = PaolaPalette.white;

  /// Text typed into input fields.
  static const textInput = PaolaPalette.black;
  static const link = PaolaPalette.green800;

  // States & outlines
  static const border = PaolaPalette.grey500;
  static const error = PaolaPalette.red600;

  /// Text and icons on [error] (confirm button of the delete dialog).
  static const onError = PaolaPalette.white;

  /// Light tint behind destructive content (movement countdown).
  static const errorContainer = PaolaPalette.red50;

  /// Dims the screen behind dialogs.
  static const scrim = PaolaPalette.black35;
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
        color: PaolaColors.surface,
        border: Border.all(color: PaolaColors.line),
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
      shaderCallback: (bounds) => PaolaColors.primaryGradient.createShader(
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
      PaolaButtonStyle.primary => (PaolaColors.primary, PaolaColors.onPrimary),
      PaolaButtonStyle.secondary => (
        PaolaColors.surface,
        PaolaColors.textPrimary,
      ),
      PaolaButtonStyle.danger => (null, PaolaColors.error),
      PaolaButtonStyle.dangerFilled => (PaolaColors.error, PaolaColors.onError),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PaolaRadius.control),
      side: style == PaolaButtonStyle.secondary
          ? const BorderSide(color: PaolaColors.line)
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
              child: const Icon(
                Icons.chevron_left,
                size: 28,
                color: PaolaColors.textPrimary,
              ),
            ),
          ),
        Text(
          text,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: PaolaColors.textPrimary,
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: PaolaColors.textSecondary,
      ),
    );
  }
}

/// 1 px divider line.
class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: PaolaColors.line);
}
