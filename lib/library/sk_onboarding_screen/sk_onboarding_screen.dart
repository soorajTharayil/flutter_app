library sk_onboarding_screen;

import 'package:devkitflutter/ui/reusable/cache_image_network.dart';
import 'package:flutter/material.dart';
import 'package:devkitflutter/library/sk_onboarding_screen/sk_onboarding_model.dart';

class SKOnboardingScreen extends StatefulWidget {
  final List<SkOnboardingModel> pages;
  final Color bgColor;
  final Color themeColor;
  final ValueChanged<String> skipClicked;
  final ValueChanged<String> getStartedClicked;

  const SKOnboardingScreen({
    Key? key,
    required this.pages,
    required this.bgColor,
    required this.themeColor,
    required this.skipClicked,
    required this.getStartedClicked,
  }) : super(key: key);

  @override
  SKOnboardingScreenState createState() => SKOnboardingScreenState();
}

class SKOnboardingScreenState extends State<SKOnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < widget.pages.length; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  List<Widget> buildOnboardingPages() {
    final children = <Widget>[];

    for (int i = 0; i < widget.pages.length; i++) {
      children.add(_showPageData(widget.pages[i]));
    }
    return children;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 6.0,
      width: isActive ? 32.0 : 6.0,
      decoration: BoxDecoration(
        color: isActive ? widget.themeColor : widget.themeColor.withOpacity(0.3),
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Modern Skip Button - Fixed height
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        widget.skipClicked("Skip Tapped");
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          side: BorderSide(color: widget.themeColor.withOpacity(0.3), width: 1.5),
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: widget.themeColor,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // PageView - Flexible to take remaining space
                Flexible(
                  child: PageView(
                    physics: const ClampingScrollPhysics(),
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: buildOnboardingPages(),
                  ),
                ),
                // Page Indicators - Fixed height
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(),
                  ),
                ),
                // Next Button - Fixed height
                if (_currentPage != widget.pages.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56.0,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.themeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
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
      bottomSheet: _currentPage == widget.pages.length - 1
          ? _showGetStartedButton()
          : null,
    );
  }

  Widget _showPageData(SkOnboardingModel page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        
        // Calculate responsive sizes
        final imageSize = (availableWidth * 0.6).clamp(200.0, 350.0);
        final horizontalPadding = (availableWidth * 0.08).clamp(16.0, 32.0);
        final verticalPadding = (availableHeight * 0.02).clamp(8.0, 20.0);
        
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Image with modern container - Flexible
              Flexible(
                flex: 5,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: imageSize,
                    maxHeight: imageSize,
                  ),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: (page.imageAssetPath != null)
                      ? Image.asset(
                          page.imageAssetPath!,
                          fit: BoxFit.contain,
                          width: imageSize - 40,
                          height: imageSize - 40,
                        )
                      : buildCacheNetworkImage(
                          width: imageSize - 40,
                          height: imageSize - 40,
                          url: page.imageFromUrl,
                          plColor: Colors.transparent),
                ),
              ),
              // Spacing - Flexible
              Flexible(
                flex: 1,
                child: SizedBox(
                  height: (availableHeight * 0.03).clamp(16.0, 32.0),
                ),
              ),
              // Title - Flexible
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    page.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: page.titleColor,
                      fontSize: 28,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              // Spacing
              SizedBox(height: (availableHeight * 0.02).clamp(8.0, 16.0)),
              // Description - Flexible
              Flexible(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.5),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      page.description,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: page.descripColor,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _showGetStartedButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0, bottom: 30.0),
      child: SizedBox(
        width: double.infinity,
        height: 56.0,
        child: ElevatedButton(
          onPressed: _getStartedTapped,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.themeColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: widget.themeColor.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0),
            ),
          ),
          child: Text(
            'Get Started',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  void _getStartedTapped() {
    widget.getStartedClicked("Get Started Tapped");
  }
}
