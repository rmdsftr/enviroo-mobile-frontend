import 'package:flutter/painting.dart';

abstract final class AppText {
  static const String family = 'Poppins';

  static TextStyle p(
    double size, {
    FontWeight? weight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
        fontStyle: fontStyle,
      );

  static TextStyle r(double size, [Color? color]) =>
      TextStyle(fontFamily: family, fontSize: size, color: color);

  static TextStyle w400(double size, [Color? color]) =>
      _w(size, FontWeight.w400, color);
  static TextStyle w500(double size, [Color? color]) =>
      _w(size, FontWeight.w500, color);
  static TextStyle w600(double size, [Color? color]) =>
      _w(size, FontWeight.w600, color);
  static TextStyle w700(double size, [Color? color]) =>
      _w(size, FontWeight.w700, color);
  static TextStyle w800(double size, [Color? color]) =>
      _w(size, FontWeight.w800, color);

  static TextStyle _w(double size, FontWeight weight, Color? color) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}
