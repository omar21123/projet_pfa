import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/widgets/Buttons/CustomNavigationButton.dart';
import 'package:connectia/Features/main/Widgets/FirstIntroduction.dart';
import 'package:connectia/Features/main/Widgets/FourthIntroduction.dart';
import 'package:connectia/Features/main/Widgets/secondIntroduction.dart';
import 'package:connectia/Features/main/Widgets/thirdIntroduction.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Introductionview extends StatefulWidget {
  const Introductionview({super.key});

  @override
  State<Introductionview> createState() => _IntroductionviewState();
}

class _IntroductionviewState extends State<Introductionview> {
  final _controller = PageController();
  static const _totalPages = 4;
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLoginPage();
    }
  }

  void _goToLoginPage() {}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: const [
                  Firstintroduction(),
                  Secondintroduction(),
                  Thirdintroduction(),
                  Fourthintroduction(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.019,
                vertical: size.height * 0.03,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: size.width * 0.28,
                    child: _currentPage > 0
                        ? Customnavigationbutton(
                            text: 'Ignorer',
                            backgroundColor: AppColors.surface(context),
                            textColor: AppColors.primaryText(context),
                            onPressed: _goToLoginPage,
                          )
                        : const SizedBox.shrink(),
                  ),
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _totalPages,
                    effect: ExpandingDotsEffect(
                      dotHeight: 10.0,
                      dotWidth: 10.0,
                      activeDotColor: AppColors.primary(context),
                      dotColor: AppColors.primary(
                        context,
                      ).withValues(alpha: 0.25),
                    ),
                  ),
                  Customnavigationbutton(
                    text: isLastPage ? 'Commencer' : 'Suivante',
                    backgroundColor: AppColors.primary(context),
                    textColor: AppColors.onPrimary(context),
                    onPressed: _goToNextPage,
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
