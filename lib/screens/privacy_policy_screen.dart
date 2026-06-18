import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'privacyPolicy'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.t(context, 'privacyPolicyTitle'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.t(context, 'privacyPolicyBody'),
            style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
