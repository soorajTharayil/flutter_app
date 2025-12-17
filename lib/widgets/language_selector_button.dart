import 'package:flutter/material.dart';
import 'package:devkitflutter/services/op_localization_service.dart';
import 'package:devkitflutter/config/constant.dart';

/// Language selector button for OP module only
/// This button only affects OP pages, not Dashboard or other modules
/// UI matches reference design: rectangular button with text + icon
class LanguageSelectorButton extends StatefulWidget {
  const LanguageSelectorButton({Key? key}) : super(key: key);

  @override
  State<LanguageSelectorButton> createState() => _LanguageSelectorButtonState();
}

class _LanguageSelectorButtonState extends State<LanguageSelectorButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  bool _isPopupOpen = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Listen to OP localization changes only
    OPLocalizationService.instance.addListener(_onLanguageChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    OPLocalizationService.instance.removeListener(_onLanguageChanged);
    _closePopup();
    _animationController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePopup() {
    // Dismiss the keyboard when language selector is tapped
    FocusScope.of(context).unfocus();
    if (_isPopupOpen) {
      _closePopup();
    } else {
      _showPopup();
    }
  }

  void _showPopup() {
    if (_isPopupOpen) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isPopupOpen = true;
    });
    _animationController.forward();
  }

  void _closePopup() {
    if (!_isPopupOpen) return;

    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() {
          _isPopupOpen = false;
        });
      }
    });
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(100, 40);
    final buttonOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final popupWidth = 320.0;

    // Calculate button center position (top-right corner)
    final buttonCenterX = buttonOffset.dx + size.width / 2;
    final buttonCenterY = buttonOffset.dy + size.height / 2;

    return OverlayEntry(
      builder: (overlayContext) {
        final screenSize = MediaQuery.of(overlayContext).size;

        // Calculate screen center position
        final screenCenterX = screenSize.width / 2;
        final screenCenterY = screenSize.height / 2;

        // Calculate offset from button to center for animation
        final deltaX = screenCenterX - buttonCenterX;
        final deltaY = screenCenterY - buttonCenterY;

        return GestureDetector(
          onTap: _closePopup,
          behavior: HitTestBehavior.opaque,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Backdrop with dimming effect
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Container(
                        color: Colors.black
                            .withOpacity(0.4 * _fadeAnimation.value),
                      );
                    },
                  ),
                ),
                // Center-aligned popup with animation from button
                Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping inside popup
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        // Calculate current position interpolated from button to center
                        final currentX = deltaX * (1 - _slideAnimation.value);
                        final currentY = deltaY * (1 - _slideAnimation.value);

                        return Transform.translate(
                          offset: Offset(currentX, currentY),
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            alignment: Alignment.center,
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: Material(
                                elevation: 20,
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.white,
                                shadowColor: Colors.black.withOpacity(0.25),
                                child: Container(
                                  width: popupWidth,
                                  constraints:
                                      const BoxConstraints(maxHeight: 500),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Premium header with icon
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 28, 24, 20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              efeedorBrandGreen
                                                  .withOpacity(0.1),
                                              efeedorBrandGreen
                                                  .withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            topRight: Radius.circular(24),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            // Icon circle
                                            Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    efeedorBrandGreen,
                                                    efeedorBrandGreen
                                                        .withOpacity(0.8),
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: efeedorBrandGreen
                                                        .withOpacity(0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.language,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            // Title
                                            const Text(
                                              'Select Language',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Subtitle
                                            Text(
                                              'Choose your preferred language to continue',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.grey[600],
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Language options
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 12, 20, 20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildLanguageItem(
                                              'en',
                                              'A',
                                              'English',
                                              'English',
                                              overlayContext,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLanguageItem(
                                              'kn',
                                              'ಕ',
                                              'Kannada',
                                              'ಕನ್ನಡ',
                                              overlayContext,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLanguageItem(
                                              'ml',
                                              'മ',
                                              'Malayalam',
                                              'മലയാളം',
                                              overlayContext,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectLanguage(String languageCode) async {
    await OPLocalizationService.setLanguage(languageCode);
    _closePopup();
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ml':
        return 'മലയാളം';
      default:
        return 'English';
    }
  }

  Color _getLanguageIconColor(String code) {
    switch (code) {
      case 'en':
        return Colors.blue;
      case 'kn':
        return Colors.orange;
      case 'ml':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = OPLocalizationService.currentLanguage;
    final languageName = _getLanguageName(currentLang);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: GestureDetector(
        onTap: _togglePopup,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language name text
              Text(
                languageName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              // Language icon
              Icon(
                Icons.translate,
                size: 18,
                color: efeedorBrandGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    String code,
    String icon,
    String title,
    String subtitle,
    BuildContext overlayContext,
  ) {
    final isSelected = OPLocalizationService.currentLanguage == code;
    final iconColor = _getLanguageIconColor(code);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectLanguage(code),
        borderRadius: BorderRadius.circular(16),
        splashColor: efeedorBrandGreen.withOpacity(0.1),
        highlightColor: efeedorBrandGreen.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? efeedorBrandGreen.withOpacity(0.08)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? efeedorBrandGreen : Colors.grey[300]!,
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: efeedorBrandGreen.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Language icon in colored circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Language name and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? efeedorBrandGreen : Colors.black87,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Checkmark for selected
              if (isSelected)
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: efeedorBrandGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
