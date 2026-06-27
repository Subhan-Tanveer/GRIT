import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';

/// Before/after comparison: drag the vertical handle to reveal more of
/// either photo. Both photos are stacked full-size; the "before" image is
/// clipped to the handle's position.
class PhotoComparisonSlider extends StatefulWidget {
  final String beforePath;
  final String afterPath;
  final String beforeLabel;
  final String afterLabel;

  const PhotoComparisonSlider({
    super.key,
    required this.beforePath,
    required this.afterPath,
    required this.beforeLabel,
    required this.afterLabel,
  });

  @override
  State<PhotoComparisonSlider> createState() => _PhotoComparisonSliderState();
}

class _PhotoComparisonSliderState extends State<PhotoComparisonSlider> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _position = (_position + details.delta.dx / width).clamp(0.0, 1.0);
            });
          },
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.afterPath), fit: BoxFit.cover),
                  ClipRect(
                    clipper: _LeftClipper(_position),
                    child: Image.file(File(widget.beforePath), fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: (width * _position) - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Colors.white),
                  ),
                  Positioned(
                    left: (width * _position) - 18,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.compare_arrows, size: 20, color: grit.background),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _labelChip(widget.beforeLabel),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _labelChip(widget.afterLabel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _labelChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black54,
      child: Text(text, style: GritTextStyles.labelMicro().copyWith(color: Colors.white, letterSpacing: 1)),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double position;
  _LeftClipper(this.position);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) => oldClipper.position != position;
}
