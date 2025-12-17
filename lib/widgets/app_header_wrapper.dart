import 'package:flutter/material.dart';
import 'package:devkitflutter/widgets/app_header_bar.dart';

class AppHeaderWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;
  final bool showLogo;
  final bool showLanguageSelector;

  const AppHeaderWrapper({
    Key? key,
    required this.child,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.bottom,
    this.bottomNavigationBar,
    this.showLogo = false,
    this.showLanguageSelector = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeaderBar(
        title: title,
        titleWidget: titleWidget,
        actions: actions,
        showBackButton: showBackButton,
        bottom: bottom,
        showLogo: showLogo,
        showLanguageSelector: showLanguageSelector,
      ),
      body: child,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
