// lib/features/auth/widgets/message_overlay.dart
import 'package:flutter/material.dart';

class MessageOverlay {
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool showOkButton = true,
    OverlayPosition position = OverlayPosition.top,
    bool showBackgroundOverlay = false,
    Color? backgroundOverlayColor,
  }) {
    _showOverlay(
      context: context,
      message: message,
      type: MessageType.error,
      duration: duration,
      showOkButton: showOkButton,
      position: position,
      showBackgroundOverlay: showBackgroundOverlay,
      backgroundOverlayColor: backgroundOverlayColor,
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onComplete,
    bool showOkButton = false,
    OverlayPosition position = OverlayPosition.top,
    bool showBackgroundOverlay = false,
    Color? backgroundOverlayColor,
  }) {
    _showOverlay(
      context: context,
      message: message,
      type: MessageType.success,
      duration: duration,
      onComplete: onComplete,
      showOkButton: showOkButton,
      position: position,
      showBackgroundOverlay: showBackgroundOverlay,
      backgroundOverlayColor: backgroundOverlayColor,
    );
  }

  static void _showOverlay({
    required BuildContext context,
    required String message,
    required MessageType type,
    required Duration duration,
    VoidCallback? onComplete,
    bool showOkButton = false,
    OverlayPosition position = OverlayPosition.top,
    bool showBackgroundOverlay = false,
    Color? backgroundOverlayColor,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _MessageOverlayWidget(
        message: message,
        type: type,
        duration: duration,
        onComplete: onComplete,
        showOkButton: showOkButton,
        position: position,
        showBackgroundOverlay: showBackgroundOverlay,
        backgroundOverlayColor: backgroundOverlayColor,
        onDismiss: () {
          overlayEntry.remove();
          if (onComplete != null) {
            onComplete();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

enum MessageType { success, error }

enum OverlayPosition { top, center, bottom }

class _MessageOverlayWidget extends StatefulWidget {
  final String message;
  final MessageType type;
  final Duration duration;
  final VoidCallback? onComplete;
  final bool showOkButton;
  final OverlayPosition position;
  final bool showBackgroundOverlay;
  final Color? backgroundOverlayColor;
  final VoidCallback onDismiss;

  const _MessageOverlayWidget({
    required this.message,
    required this.type,
    required this.duration,
    this.onComplete,
    required this.showOkButton,
    required this.position,
    required this.showBackgroundOverlay,
    this.backgroundOverlayColor,
    required this.onDismiss,
  });

  @override
  State<_MessageOverlayWidget> createState() => __MessageOverlayWidgetState();
}

class __MessageOverlayWidgetState extends State<_MessageOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Opacity animation
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Scale animation for center position
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Slide animations based on position
    switch (widget.position) {
      case OverlayPosition.top:
        _slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, -1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            );
        break;
      case OverlayPosition.bottom:
        _slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            );
        break;
      case OverlayPosition.center:
        _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            );
        break;
    }

    _controller.forward();

    // Auto dismiss after duration (only if no OK button)
    if (!widget.showOkButton) {
      Future.delayed(widget.duration, () {
        if (_isVisible && mounted) {
          _dismiss();
        }
      });
    }
  }

  void _dismiss() {
    if (!_isVisible) return;

    _isVisible = false;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background overlay (if enabled) - WITHOUT GestureDetector
        if (widget.showBackgroundOverlay)
          Positioned.fill(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                color:
                    widget.backgroundOverlayColor ??
                    Colors.black.withOpacity(0.5),
              ),
            ),
          ),

        // Message widget with proper positioning
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Position based on widget.position
                  Widget positionedChild;

                  switch (widget.position) {
                    case OverlayPosition.top:
                      positionedChild = Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: child,
                          ),
                        ),
                      );
                      break;
                    case OverlayPosition.bottom:
                      positionedChild = Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 50),
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: child,
                          ),
                        ),
                      );
                      break;
                    case OverlayPosition.center:
                      positionedChild = Align(
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                      break;
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height,
                    child: positionedChild,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.type == MessageType.success
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFff7e5f), Color(0xFFfeb47b)],
                            ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: widget.type == MessageType.error
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // First Row: Icon and Title with Close button
                        Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.type == MessageType.success
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title (ERROR or SUCCESS)
                            Text(
                              widget.type == MessageType.success
                                  ? "SUCCESS"
                                  : "ERROR",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Close button (X)
                            GestureDetector(
                              onTap: _dismiss,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Second Row: Message
                        Row(
                          children: [
                            const SizedBox(width: 4), // Align with title
                            Expanded(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // OK Button (only for errors when showOkButton is true)
                        if (widget.showOkButton &&
                            widget.type == MessageType.error) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _dismiss,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFff7e5f),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Progress indicator for auto-close
                        if (!widget.showOkButton) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: widget.duration,
                              builder: (context, value, child) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.transparent,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                  borderRadius: BorderRadius.circular(2),
                                );
                              },
                              onEnd: _dismiss,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Closing in ${widget.duration.inSeconds} second${widget.duration.inSeconds > 1 ? 's' : ''}...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
