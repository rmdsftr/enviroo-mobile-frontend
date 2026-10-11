import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  static final NumberFormat _f = NumberFormat('#,###', 'id_ID');

  static String formatRibuan(num v) => _f.format(v);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll('.', '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');

    final number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;

    final formatted = _f.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
