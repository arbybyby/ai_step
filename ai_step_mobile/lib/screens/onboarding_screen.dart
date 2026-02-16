import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> _buildPages() {
    return List.generate(3, (index) => _buildPage(index));
  }

  // (Removed unused stat card helper; onboarding pages now show explanatory content.)

  Widget _buildPage(int index) {
    // Build three onboarding pages that match the screenshot styling
    const contentPadding = EdgeInsets.symmetric(horizontal: 28.0, vertical: 18);
    final titleStyle = const TextStyle(
      color: Colors.white,
      fontSize: 38,
      fontWeight: FontWeight.w800,
      shadows: [Shadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8)],
    );
    final subtitleStyle = const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5);

    Widget buildIcon(IconData iconData) {
      return Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40, spreadRadius: 2, offset: Offset(0, 18))],
        ),
        child: Center(child: Icon(iconData, size: 88, color: const Color(0xFF0B8B57))),
      );
    }

    switch (index) {
      case 0:
        return Padding(
          padding: contentPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              buildIcon(Icons.local_fire_department),
              const SizedBox(height: 28),
              Text('Burn Calories', style: titleStyle),
              const SizedBox(height: 12),
              Text(
                'See real-time calorie tracking based on your activity. Make every step count toward your fitness journey.',
                style: subtitleStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case 1:
        return Padding(
          padding: contentPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              buildIcon(Icons.show_chart),
              const SizedBox(height: 28),
              Text('Smart Analytics', style: titleStyle),
              const SizedBox(height: 12),
              Text(
                'Get personalized insights and progress charts. Let AI guide you to better health every day.',
                style: subtitleStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      default:
        return Padding(
          padding: contentPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              buildIcon(Icons.directions_walk),
              const SizedBox(height: 28),
              Text('Track Your Steps', style: titleStyle),
              const SizedBox(height: 12),
              Text(
                'Monitor every step you take with precision. Stay motivated and reach your daily goals effortlessly.',
                style: subtitleStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  Widget _featureTile({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.white24, child: Icon(icon, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13))])),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.black54))]),
    );
  }

  Widget _benefitRow({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(icon, color: Colors.white70), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13))]))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8FFFBF), Color(0xFF0EA859)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) => pages[i],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                child: Column(
                  children: [
                    // Page indicator: small - big - small style, animated
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pages.length, (i) {
                        final selected = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: selected ? 44 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.white70.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Large pill button (Next/Get Started)
                    SizedBox(
                      width: double.infinity,
                      height: 68,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                          elevation: 6,
                        ),
                        onPressed: () {
                          if (_currentPage == pages.length - 1) {
                            // last page -> signup
                            Navigator.of(context).pushReplacementNamed('/signup');
                          } else {
                            _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.ease);
                          }
                        },
                        child: Text(
                          _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(color: Color(0xFF0B8B57), fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Sign in link on last page
                    if (_currentPage == pages.length - 1)
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/signin'),
                        child: const Text('Already have an account? Log In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
