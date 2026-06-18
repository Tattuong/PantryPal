import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/locale_provider.dart';
import 'strings/app_strings_en.dart';
import 'strings/app_strings_vi.dart';

class AppStrings {
  static Map<String, String> _mapFor(String languageCode) {
    return languageCode == 'vi' ? appStringsVi : appStringsEn;
  }

  static String languageCodeOf(BuildContext context) {
    return context.read<LocaleProvider>().languageCode;
  }

  static String t(BuildContext context, String key, [Map<String, String>? params]) {
    return tCode(languageCodeOf(context), key, params);
  }

  static String tCode(String languageCode, String key, [Map<String, String>? params]) {
    var text = _mapFor(languageCode)[key] ?? appStringsEn[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }
}
