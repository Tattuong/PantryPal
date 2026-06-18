import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final _pages = const [
    (Icons.kitchen_rounded, 'onboardingTitle1', 'onboardingDesc1', Color(0xFF1B8A5A)),
    (Icons.event_busy_rounded, 'onboardingTitle2', 'onboardingDesc2', Color(0xFF2ECC71)),
    (Icons.stars_rounded, 'onboardingTitle3', 'onboardingDesc3', Color(0xFFF39C12)),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pp_onboarding_seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(onPressed: _finish, child: Text(AppStrings.t(context, 'skip'))),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final (icon, titleKey, descKey, color) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: Icon(icon, size: 56, color: color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          AppStrings.t(context, titleKey),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.t(context, descKey),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: () {
                  if (_page < _pages.length - 1) {
                    _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  } else {
                    _finish();
                  }
                },
                child: Text(AppStrings.t(context, _page < _pages.length - 1 ? 'next' : 'getStarted')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
