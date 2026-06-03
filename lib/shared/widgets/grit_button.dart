import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';

class GritPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? fontSize;
  final double? letterSpacing;

  const GritPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.arrow_forward,
    this.height = 52,
    this.fontSize,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return SizedBox(
      width: double.infinity,
      height: height, // Spec 5.2: Height 52px (default)
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                await GritHaptics.buttonTap();
                onPressed();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: grit.accent,
          foregroundColor: Colors.white, // White text on accent for better contrast
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GritTextStyles.metric(
                      fontSize ?? 18,
                      weight: FontWeight.w900, 
                      letterSpacing: letterSpacing ?? 3,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: (fontSize ?? 18) * 1.0, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

class GritSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double height;
  final double? fontSize;
  final double? letterSpacing;

  const GritSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.fontSize,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return SizedBox(
      width: double.infinity,
      height: height, // Spec 5.3: Height 52px (default)
      child: ElevatedButton(
        onPressed: () async {
          await GritHaptics.buttonTap();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: grit.surface2, // Spec 5.3: Color Surface2
          foregroundColor: grit.textPrimary,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: GritTextStyles.metric(
                fontSize ?? 14,
                weight: FontWeight.w700, 
                letterSpacing: letterSpacing ?? 3,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: (fontSize ?? 14) * 1.1),
            ],
          ],
        ),
      ),
    );
  }
}

class GritGhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAccent;
  final double? height;
  final double fontSize;

  const GritGhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isAccent = false,
    this.height,
    this.fontSize = 12,
  });

  @override
  State<GritGhostButton> createState() => _GritGhostButtonState();
}

class _GritGhostButtonState extends State<GritGhostButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final baseColor = widget.isAccent ? grit.accent : grit.textSecondary;
    final borderColor = widget.isAccent ? grit.accent : grit.border;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Container(
        height: widget.height ?? 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _isPressed ? grit.accent.withValues(alpha: 0.05) : Colors.transparent,
          border: Border.all(
            color: _isPressed ? grit.accent : borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label.toUpperCase(),
          style: GritTextStyles.metric(
            widget.fontSize,
            weight: FontWeight.w700,
            color: _isPressed ? grit.accent : baseColor,
            height: 1.0,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
