import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../home/farmer_home_screen.dart';
import '../home/vet_home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF20B769);
  static const Color darkGreen = Color(0xFF176B43);

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Main entrance animation (1.5 sec)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // ✅ Simple pulse animation (2 sec)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ✅ Background float animation (6 sec)
    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _mainController.forward();

    // ✅ Splash time: 3.5 seconds
    Timer(const Duration(milliseconds: 3500), _navigateToNextScreen);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // ================= NAVIGATE =================
  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final profile = await authService.getUserProfile();
      final userType = profile?['user_type'] ?? '';
      final userName = profile?['full_name'] ?? 'User';

      if (!mounted) return;

      if (userType.toString().toLowerCase().contains('vet')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VetHomeScreen(userName: userName)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FarmerHomeScreen(userName: userName),
          ),
        );
      }
    } catch (e) {
      print('❌ Splash navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF42B97A), Color(0xFF20B769), Color(0xFF176B43)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ================= FLOATING BACKGROUND =================
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top:
                          -80 +
                          (math.sin(_floatController.value * 2 * math.pi) * 20),
                      right: -80,
                      child: _buildCircle(250, 0.10),
                    ),
                    Positioned(
                      bottom:
                          -120 +
                          (math.cos(_floatController.value * 2 * math.pi) * 15),
                      left: -80,
                      child: _buildCircle(300, 0.08),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.35,
                      right: -40,
                      child: _buildCircle(120, 0.06),
                    ),
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.25,
                      left: -30,
                      child: _buildCircle(100, 0.05),
                    ),
                  ],
                );
              },
            ),

            // ================= MAIN CONTENT =================
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ LOGO (Scale animation)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildLogo(),
                        ),
                      ),

                      SizedBox(height: 40 + _slideAnimation.value),

                      // ✅ APP NAME
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: const Text(
                            'FarmCare',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ================= BOTTOM LOADING =================
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= VERSION =================
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CIRCLE =================
  Widget _buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  // ================= LOGO (Simple Scale Animation) =================
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // ✅ Simple scale: 1.0 → 1.10 → 1.0
        final scale = 1.0 + (_pulseAnimation.value * 0.10);

        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              // Middle ring
              Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              // Main icon circle
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.pets, color: primaryGreen, size: 75),
              ),
            ],
          ),
        );
      },
    );
  }
}
