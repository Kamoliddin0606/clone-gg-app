import 'package:flutter/services.dart';

/// Custom TextInputFormatter for Uzbek phone numbers
/// Automatically adds +998 prefix when user starts typing numbers
/// Allows manual entry of + for international numbers
/// Ensures phone number is exactly 13 characters (+998XXXXXXXXX)
class UzbekPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    
    // If empty, allow it
    if (newText.isEmpty) {
      return newValue;
    }

    // If starts with +, allow it (user wants to enter international number)
    if (newText.startsWith('+')) {
      // Limit to 13 characters for +998XXXXXXXXX format
      if (newText.length > 13) {
        return oldValue;
      }
      return newValue;
    }

    // If user starts typing a number (not +), auto-add +998
    if (RegExp(r'^\d').hasMatch(newText)) {
      // Remove any existing +998 prefix to avoid duplication
      String digitsOnly = newText.replaceAll(RegExp(r'[^\d]'), '');
      
      // If starts with 998, don't duplicate
      if (digitsOnly.startsWith('998')) {
        digitsOnly = digitsOnly.substring(3);
      }
      
      // Limit to 9 digits after +998
      if (digitsOnly.length > 9) {
        digitsOnly = digitsOnly.substring(0, 9);
      }
      
      final formattedText = '+998$digitsOnly';
      
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }

    // If text doesn't start with + or digit, reject it
    return oldValue;
  }
}

/// Validator for Uzbek phone numbers
/// Ensures phone number is exactly 13 characters (+998XXXXXXXXX)
String? validateUzbekPhoneNumber(String? value, {bool isRequired = false}) {
  if (value == null || value.trim().isEmpty) {
    if (isRequired) {
      return 'Telefon raqami kiritilishi shart';
    }
    return null;
  }

  final trimmed = value.trim();
  
  // Must start with +
  if (!trimmed.startsWith('+')) {
    return 'Telefon raqami + belgisi bilan boshlanishi kerak';
  }

  // Must be exactly 13 characters
  if (trimmed.length != 13) {
    return 'Telefon raqami 13 ta belgidan iborat bo\'lishi kerak (+998XXXXXXXXX)';
  }

  // Must contain only + and digits
  if (!RegExp(r'^\+\d{12}$').hasMatch(trimmed)) {
    return 'Telefon raqami noto\'g\'ri formatda';
  }

  return null;
}
