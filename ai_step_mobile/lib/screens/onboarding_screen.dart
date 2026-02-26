import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _darkBg = Color(0xFF0E0E0E);
  static const _green = Color(0xFF1DB954); // яркий зелёный как на скрине
  static const _greenCircle = Color(0xFF15A84A);

  final List<_OnboardData> _pages = const [
    _OnboardData(
      icon: Icons.directions_walk,
      title: 'Track Your\nSteps',
      subtitle:
          'Monitor every step you take throughout the day. Build healthy habits and hit your daily goal — one step at a time.',
    ),
    _OnboardData(
      icon: Icons.local_fire_department,
      title: 'Burn\nCalories',
      subtitle:
          'See exactly how many calories you burn with each activity. Stay in the zone and make every workout count.',
    ),
    _OnboardData(
      icon: Icons.bar_chart,
      title: 'Smart\nAnalytics',
      subtitle:
          'Get clear insights into your progress with smart charts and trends. Understand your body and improve every week.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Pages ───────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // ─── Bottom controls ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final sel = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: sel ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: sel ? _green : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _darkBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.of(context).pushReplacementNamed('/signup');
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.ease,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  // Log in link (только на последней странице)
                  if (_currentPage == _pages.length - 1) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushReplacementNamed('/signin'),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Большой зелёный круг с иконкой
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _greenCircle,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _green.withOpacity(0.45),
                  blurRadius: 60,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(data.icon, size: 90, color: Colors.black),
          ),

          const Spacer(flex: 2),

          // Заголовок
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 20),

          // Подзаголовок
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 16,
              height: 1.55,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// Простая data-class для страниц
class _OnboardData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
