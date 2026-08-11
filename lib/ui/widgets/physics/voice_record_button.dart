import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../../core/providers/tdlib_event_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/ptt_service.dart';

class VoiceRecordButton extends ConsumerStatefulWidget {
  final int chatId;
  final bool hasText;
  final VoidCallback onSendText;

  const VoiceRecordButton({
    super.key,
    required this.chatId,
    required this.hasText,
    required this.onSendText,
  });

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _micController;
  late Animation<double> _micScaleAnimation;
  
  OverlayEntry? _overlayEntry;
  Offset _dragOffset = Offset.zero;
  bool _isLocked = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _micScaleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _micController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _micController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _startRecording(LongPressStartDetails details) {
    if (widget.hasText) return;
    HapticFeedback.vibrate();

    setState(() {
      _isRecording = true;
      _isLocked = false;
      _dragOffset = Offset.zero;
    });

    _micController.forward();
    ref.read(pttNotifierProvider.notifier).startPtt(widget.chatId);
    ref.read(tdlibCoreProvider).send(td.SendChatAction(
      chatId: widget.chatId,
      messageThreadId: 0,
      action: const td.ChatActionRecordingVoiceNote(),
    ));

    _showOverlay(details.globalPosition);
  }

  void _updateRecording(LongPressMoveUpdateDetails details) {
    if (!_isRecording || _isLocked) return;

    setState(() {
      _dragOffset = details.offsetFromOrigin;
    });

    // Check Lock (Slide Up)
    if (_dragOffset.dy < -60) {
      _isLocked = true;
      HapticFeedback.lightImpact();
      _dragOffset = Offset(0, -100); // Snap to lock
    }

    // Check Cancel (Slide Left)
    if (_dragOffset.dx < -80 && !_isLocked) {
      _cancelRecording();
    }
    
    _overlayEntry?.markNeedsBuild();
  }

  void _endRecording(LongPressEndDetails details) {
    if (!_isRecording) return;
    
    if (!_isLocked) {
      _stopRecordingAndSend();
    }
  }

  void _stopRecordingAndSend() {
    setState(() => _isRecording = false);
    _micController.reverse();
    _removeOverlay();
    ref.read(pttNotifierProvider.notifier).stopPtt();
  }

  void _cancelRecording() {
    setState(() => _isRecording = false);
    HapticFeedback.mediumImpact();
    _micController.reverse();
    _removeOverlay();
    ref.read(pttNotifierProvider.notifier).stopPtt(); // Typically discard instead of send
    ref.read(tdlibCoreProvider).send(td.SendChatAction(
      chatId: widget.chatId,
      messageThreadId: 0,
      action: const td.ChatActionCancel(),
    ));
  }

  void _showOverlay(Offset initialPosition) {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: initialPosition.dx - 22 + _dragOffset.dx,
          top: initialPosition.dy - 22 + _dragOffset.dy,
          child: AnimatedBuilder(
            animation: _micScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _micScaleAnimation.value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppTheme.tgBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1)
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 22),
                ),
              );
            },
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasText) {
      return GestureDetector(
        onTap: widget.onSendText,
        child: _buildButtonIcon(Icons.send_rounded, true),
      );
    }

    return GestureDetector(
      onLongPressStart: _startRecording,
      onLongPressMoveUpdate: _updateRecording,
      onLongPressEnd: _endRecording,
      child: _isRecording ? const SizedBox(width: 44, height: 44) : _buildButtonIcon(Icons.mic_none_rounded, false),
    );
  }

  Widget _buildButtonIcon(IconData icon, bool isSend) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 6, top: 6),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.tgBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
