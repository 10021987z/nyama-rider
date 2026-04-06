import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Slider horizontal anti-erreur — Kevin conduit une moto
/// L'utilisateur doit glisser jusqu'à la fin pour confirmer
class SwipeButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onConfirmed;
  final bool enabled;

  const SwipeButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.color = AppColors.ctaGreen,
    this.enabled = true,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton> {
  double _position = 0;
  bool _confirmed = false;

  static const double _btnHeight = 72;
  static const double _thumbSize = 64;
  static const double _minConfirm = 0.8; // 80% du chemin

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - 8;

        return Container(
          height: _btnHeight,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // ── Fill progress ───────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: _thumbSize + _position + 8,
                height: _btnHeight,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              // ── Label ────────────────────────────────────────────────
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _confirmed ? 0 : (1 - (_position / maxDrag) * 1.5).clamp(0, 1),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                ),
              ),

              // ── Thumb ────────────────────────────────────────────────
              Positioned(
                left: 4 + _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.enabled
                      ? (details) {
                          if (_confirmed) return;
                          setState(() {
                            _position =
                                (_position + details.delta.dx).clamp(0, maxDrag);
                          });
                        }
                      : null,
                  onHorizontalDragEnd: widget.enabled
                      ? (details) {
                          if (_position / maxDrag >= _minConfirm) {
                            setState(() {
                              _position = maxDrag;
                              _confirmed = true;
                            });
                            widget.onConfirmed();
                          } else {
                            setState(() => _position = 0);
                          }
                        }
                      : null,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 26,
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
}
