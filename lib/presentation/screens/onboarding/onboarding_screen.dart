import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final _pages = const [
    {
      'image': 'assets/onboard1.png',
      'title': 'Welcome to eTribunals',
      'desc': 'Public case status, cause lists, judgements and display boards.',
    },
    {
      'image': 'assets/onboard2.png',
      'title': '16 tribunals',
      'desc': 'NCLAT, NCLT, UPREAT, NGT, RCT, DRT, CAT, ITAT, CESTAT, TDSAT, APTEL, SAT, AFT, NCDRC, ATFP and CGIT. Search official records the way the court sites publish them.',
    },
    {
      'image': 'assets/onboard3.png',
      'title': 'Follow on this phone',
      'desc': 'Bookmark a matter. It stays on this device.',
    },
    {
      'image': '',
      'title': 'AI Summarize',
      'desc': 'Open an order or judgement PDF and tap AI Summarize. See held points and directions, then ask a follow-up about that case. No API key to paste.',
    },
    {
      'image': 'assets/onboard4.png',
      'title': "Today's board",
      'desc': 'Open cause lists and live display boards from the Today tab, including RCT listed today.',
    },
    {
      'image': 'assets/onboard5.png',
      'title': 'Official sources',
      'desc': 'Data comes from public tribunal websites. Always verify on the source site before filing.',
    },
  ];

  Future<void> _goHome() async {
    await LocalStorageService.setOnboardingComplete();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _goHome();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _currentIndex == _pages.length - 1;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Image.asset('assets/brand_scales.png', width: 36, height: 36),
                    const SizedBox(width: 8),
                    const Text(
                      'eTribunals',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _goHome,
                      child: const Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        const Spacer(),
                        if ((data['image'] ?? '').isEmpty)
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(Icons.auto_awesome, size: 64, color: AppColors.accent),
                          )
                        else
                          Image.asset(data['image']!, height: MediaQuery.sizeOf(context).height * 0.28),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                data['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['desc']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final on = _currentIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: on ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: on ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    customButton(last ? 'Get started' : 'Next', _nextPage),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
