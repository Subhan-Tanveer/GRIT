import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/grit_theme.dart';

class GritNumericInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isCompleted;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;
  final double? width;
  final TextInputType keyboardType;

  const GritNumericInput({
    super.key,
    required this.controller,
    required this.label,
    this.isCompleted = false,
    required this.onChanged,
    this.textAlign = TextAlign.center,
    this.width,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });

  @override
  State<GritNumericInput> createState() => _GritNumericInputState();
}

class _GritNumericInputState extends State<GritNumericInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.controller.text == '0.0' || widget.controller.text == '0') {
        widget.controller.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final hasFocus = _focusNode.hasFocus;
    return Container(
      width: widget.width,
      height: 52, // Spec 5.9: Height 52px
      decoration: BoxDecoration(
        color: widget.isCompleted 
            ? grit.accent.withValues(alpha: 0.05) 
            : grit.surface,
        border: Border.all(
          color: widget.isCompleted 
              ? grit.accent.withValues(alpha: 0.2) 
              : (hasFocus ? grit.accent : grit.border),
          width: hasFocus ? 2 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: !widget.isCompleted,
            keyboardType: widget.keyboardType,
            textAlign: widget.textAlign,
            textAlignVertical: TextAlignVertical.center,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            style: GritTextStyles.metric(24,
                weight: FontWeight.w900,
                color: widget.isCompleted
                    ? grit.accent
                    : grit.textPrimary),
            decoration: InputDecoration(
              hintText: '-',
              hintStyle: GritTextStyles.metric(24,
                  weight: FontWeight.w900,
                  color: widget.isCompleted
                      ? grit.accent.withValues(alpha: 0.2)
                      : grit.muted),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
            ),
            onChanged: widget.onChanged,
          ),
          if (widget.label.isNotEmpty)
            Positioned(
              right: 8,
              bottom: 4,
              child: Text(
                widget.label,
                style: GritTextStyles.mono(8,
                    weight: FontWeight.w900,
                    color: widget.isCompleted
                        ? grit.accent.withValues(alpha: 0.3)
                        : grit.textSecondary.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }
}
