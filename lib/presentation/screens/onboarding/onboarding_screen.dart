import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/onboard1.png",
      "title": "Welcome to Tribunal App",
      "desc": "Your one-stop solution for managing legal case statuses with ease and accuracy."
    },
    {
      "image": "assets/onboard2.png",
      "title": "Track Your Cases",
      "desc": "Instant access to case updates, hearing dates, and court orders – anytime, anywhere."
    },
    {
      "image": "assets/onboard3.png",
      "title": "Search Tribunal Details",
      "desc": "Explore tribunals, their jurisdictions, and historical judgments from a unified dashboard."
    },
    {
      "image": "assets/onboard4.png",
      "title": "Smart Notifications",
      "desc": "Get notified about your hearings, updates, or case status without checking manually."
    },
    {
      "image": "assets/onboard5.png",
      "title": "Secure & Reliable",
      "desc": "Built with Firebase and modern technologies to keep your data safe and experience smooth."
    },
  ];

  void _nextPage() {
    if (_currentIndex < _onboardingData.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _onboardingData.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(data['image']!, height: 250),
                        const SizedBox(height: 40),
                        customText(data['title']!, size: 24, weight: FontWeight.bold, align: TextAlign.center),
                        const SizedBox(height: 20),
                        customText(data['desc']!, size: 16, color: Colors.white70, align: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  customButton(
                    _currentIndex == _onboardingData.length - 1 ? "Get Started" : "Next",
                    _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
