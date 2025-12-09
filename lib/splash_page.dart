import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaa_cleaning/profile_setup_page.dart';

import 'settings/app_theme.dart';
import 'login_system/login_page.dart';
import 'profile_edit_page.dart'; // ⬅️ use ProfileEditPage instead
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Simple logo + text animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _goNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    // Slightly longer to enjoy the animation
    await Future.delayed(const Duration(seconds: 3));

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      // Not logged in → go to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    // Logged in → check profile in Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    final data = doc.data() ?? {};
    final hasName = (data['name'] ?? '')
        .toString()
        .isNotEmpty;

    if (!doc.exists || !hasName) {
      // New user → go to SETUP page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfileSetupPage(user: user),
        ),
      );
    } else {
      // Profile exists → go to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    }
  }


    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.orange,
              AppColors.green,
              AppColors.blue,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔥 much bigger logo
                    SizedBox(
                      height: 210,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لمعة الاتقان',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'خدمات تنظيف احترافية في متناول يدك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // small animated cleaning row
                    SizedBox(
                      height: 46,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final t = _controller.value;
                          final bubbleOpacity =
                          (0.3 + 0.7 * t).clamp(0.0, 1.0);
                          final broomOffset = (t * 40) - 20; // -20 → +20

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // bubbles
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: bubbleOpacity,
                                    child: const Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Opacity(
                                    opacity: bubbleOpacity * 0.8,
                                    child: const Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Opacity(
                                    opacity: bubbleOpacity * 0.6,
                                    child: const Icon(
                                      Icons.circle,
                                      size: 5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),

                              // broom sliding a little left-right
                              Transform.translate(
                                offset: Offset(broomOffset, 8),
                                child: Transform.rotate(
                                  angle: 0.1 - 0.05 * t,
                                  child: const Icon(
                                    Icons.cleaning_services_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
