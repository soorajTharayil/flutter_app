import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:devkitflutter/services/hospital_logo_service.dart';

class HospitalLogoWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final bool showCircular;
  final bool showRectangular;

  const HospitalLogoWidget({
    Key? key,
    this.width,
    this.height,
    this.padding,
    this.showCircular = false,
    this.showRectangular = true,
  }) : super(key: key);

  @override
  State<HospitalLogoWidget> createState() => _HospitalLogoWidgetState();
}

class _HospitalLogoWidgetState extends State<HospitalLogoWidget> {
  Uint8List? _logoBytes;
  bool _isLoadingLogo = true;

  @override
  void initState() {
    super.initState();
    _loadLogo();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLogo) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 80,
        padding: widget.padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (_logoBytes != null) {
      if (widget.showRectangular) {
        // Rectangular container for Dashboard
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 80,
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.memory(
            _logoBytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.local_hospital,
                  color: Colors.grey,
                  size: 40,
                ),
              );
            },
          ),
        );
      } else if (widget.showCircular) {
        // Circular container for header
        return Container(
          width: widget.width ?? 50,
          height: widget.height ?? 50,
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
    }

    // Fallback - rectangular container
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 80,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }
}

