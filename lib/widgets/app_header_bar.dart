import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:devkitflutter/services/hospital_logo_service.dart';
import 'package:devkitflutter/widgets/language_selector_button.dart';
import 'package:devkitflutter/config/constant.dart';

class AppHeaderBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;
  final bool showLogo;
  final bool showLanguageSelector;

  const AppHeaderBar({
    Key? key,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.bottom,
    this.showLogo = false,
    this.showLanguageSelector = false,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  State<AppHeaderBar> createState() => _AppHeaderBarState();
}

class _AppHeaderBarState extends State<AppHeaderBar> {
  Uint8List? _logoBytes;
  bool _isLoadingLogo = true;
  String? _hospitalName;

  @override
  void initState() {
    super.initState();
    if (widget.showLogo) {
      _loadLogo();
      _loadHospitalName();
    } else {
      _isLoadingLogo = false;
    }
  }

  Future<void> _loadLogo() async {
    try {
      final logoBase64 = await HospitalLogoService.getLogo();
      if (logoBase64 != null) {
        final bytes = HospitalLogoService.base64ToBytes(logoBase64);
        if (mounted) {
          setState(() {
            _logoBytes = bytes;
            _isLoadingLogo = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLogo = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLogo = false;
        });
      }
    }
  }

  Future<void> _loadHospitalName() async {
    try {
      final name = await HospitalLogoService.getHospitalName();
      if (mounted) {
        setState(() {
          _hospitalName = name;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Widget _buildLogo() {
    if (_isLoadingLogo) {
      return const SizedBox(
        width: 50,
        height: 50,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_logoBytes != null) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: ClipOval(
          child: Image.memory(
            _logoBytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.local_hospital, color: Colors.grey, size: 28);
            },
          ),
        ),
      );
    }

    // Fallback icon if no logo
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.local_hospital,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildTitle() {
    if (widget.title == null) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Text(
        widget.title!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> appBarActions = [];
    
    if (widget.showLanguageSelector) {
      appBarActions.add(const LanguageSelectorButton());
    }
    
    if (widget.actions != null) {
      appBarActions.addAll(widget.actions!);
    }

    return AppBar(
      backgroundColor: efeedorBrandGreen,
      elevation: 0,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Row(
        children: [
          if (widget.showLogo) ...[
            _buildLogo(),
            const SizedBox(width: 12),
          ],
          if (_hospitalName != null && widget.title == null && widget.showLogo) ...[
            Flexible(
              child: Text(
                _hospitalName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ] else ...[
            _buildTitle(),
          ],
        ],
      ),
      actions: appBarActions.isNotEmpty ? appBarActions : null,
      bottom: widget.bottom,
      automaticallyImplyLeading: false,
    );
  }
}

