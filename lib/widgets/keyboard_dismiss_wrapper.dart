import 'package:flutter/material.dart';

/// Widget that dismisses keyboard when tapping outside input fields
/// This works globally across the entire application
class KeyboardDismissWrapper extends StatelessWidget {
  final Widget child;

  const KeyboardDismissWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      // Use translucent to allow taps to pass through to child widgets
      // but still capture taps on empty areas
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

