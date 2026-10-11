import 'package:flutter/material.dart';

import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class StateMessage extends StatelessWidget {
  final String? illustration;
  final double illustrationWidth;

  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final EdgeInsetsGeometry badgePadding;

  final String message;
  final TextStyle? messageStyle;
  final TextAlign textAlign;

  final String? subtitle;
  final TextStyle? subtitleStyle;
  final TextAlign? subtitleAlign;

  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  final double gap;
  final double subtitleGap;
  final double actionGap;

  final Widget? action;

  const StateMessage({
    super.key,
    required this.message,
    this.illustration,
    this.illustrationWidth = 118,
    this.icon = Icons.error_outline_rounded,
    this.iconSize = 40,
    this.iconColor,
    this.badgeColor,
    this.badgePadding = const EdgeInsets.all(20),
    this.messageStyle,
    this.textAlign = TextAlign.center,
    this.subtitle,
    this.subtitleStyle,
    this.subtitleAlign,
    this.padding = const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
    this.alignment = Alignment.center,
    this.gap = 14,
    this.subtitleGap = 6,
    this.actionGap = 16,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    if (illustration != null) {
      leading = Image.asset(illustration!, width: illustrationWidth);
    } else if (icon != null) {
      leading = Icon(
        icon,
        size: iconSize,
        color: iconColor ?? AppColors.dangerSoft.withValues(alpha: 0.5),
      );
      if (badgeColor != null) {
        leading = Container(
          padding: badgePadding,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          child: leading,
        );
      }
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, SizedBox(height: gap)],
            Text(
              message,
              textAlign: textAlign,
              style: messageStyle ??
                  AppText.w600(13, AppColors.dark.withValues(alpha: 0.4)),
            ),
            if (subtitle != null) ...[
              SizedBox(height: subtitleGap),
              Text(
                subtitle!,
                textAlign: subtitleAlign ?? textAlign,
                style: subtitleStyle ??
                    AppText.r(12, AppColors.dark.withValues(alpha: 0.3)),
              ),
            ],
            if (action != null) ...[SizedBox(height: actionGap), action!],
          ],
        ),
      ),
    );
  }
}

class StateRetryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final double iconSize;
  final Color color;
  final Color foregroundColor;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final TextStyle? labelStyle;
  final bool _pill;

  const StateRetryButton({
    super.key,
    required this.onPressed,
    this.label = 'Coba Lagi',
    this.color = AppColors.dark,
    this.foregroundColor = Colors.white,
    this.radius = 12,
    this.padding,
    this.elevation,
    this.labelStyle,
  })  : icon = null,
        iconSize = 16,
        _pill = false;

  const StateRetryButton.icon({
    super.key,
    required this.onPressed,
    this.label = 'Coba Lagi',
    this.icon = Icons.refresh_rounded,
    this.iconSize = 14,
    this.color = AppColors.dark,
    this.foregroundColor = Colors.white,
    this.radius = 35,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    this.elevation = 0,
    this.labelStyle,
  }) : _pill = false;

  const StateRetryButton.pill({
    super.key,
    required this.onPressed,
    this.label = 'Coba Lagi',
    this.color = AppColors.green,
    this.radius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    this.labelStyle,
  })  : icon = null,
        iconSize = 16,
        foregroundColor = Colors.white,
        elevation = null,
        _pill = true;

  @override
  Widget build(BuildContext context) {
    if (_pill) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
          child:
              Text(label, style: labelStyle ?? AppText.w600(13, Colors.white)),
        ),
      );
    }
    
    final style = ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: foregroundColor,
      elevation: elevation,
      padding: padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    );
    final text = Text(
      label,
      style: labelStyle ?? const TextStyle(fontFamily: AppText.family),
    );

    return icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: text)
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: iconSize),
            label: text,
            style: style,
          );
  }
}

abstract final class StateArt {
  static const empty = 'assets/images/state-icon-1.png';
  static const emptyMoney = 'assets/images/state-icon-2.png';
  static const error = 'assets/images/state-icon-3.png';
}
