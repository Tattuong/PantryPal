import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_strings.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/shop_provider.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final shop = context.read<ShopProvider>();
    await shop.init();
    final pantry = context.read<PantryProvider>();
    await pantry.load();
    final shopping = context.read<ShoppingProvider>();
    await shopping.load();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('pp_onboarding_seen') ?? false;

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final next = seenOnboarding ? const MainShell() : const OnboardingScreen();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = context.watch<ShopProvider>().activeTheme.headerGradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) => Transform.scale(
                    scale: 1.0 + _ctrl.value * 0.05,
                    child: child,
                  ),
                  child: Image.asset('assets/logo.png', width: 120, height: 120, fit: BoxFit.cover),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.t(context, 'appName'),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t(context, 'appTagline'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.t(context, 'splashLoading'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
