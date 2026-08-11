import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/providers/call_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/chat_avatar.dart';

import 'dart:async';

class CallOverlay extends ConsumerStatefulWidget {
  const CallOverlay({super.key});

  @override
  ConsumerState<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends ConsumerState<CallOverlay> {
  Timer? _timer;
  int _seconds = 0;
  bool _isTimerRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _seconds = 0;
    _isTimerRunning = false;
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callNotifierProvider);
    final call = callState.currentCall;

    if (call == null) {
      if (_isTimerRunning) _stopTimer();
      return const SizedBox.shrink();
    }

    if (call.state is td.CallStateReady) {
      _startTimer();
    } else {
      _stopTimer();
    }

    return Material(
      color: Colors.black,
      child: _buildCallScreen(context, ref, call),
    );
  }

  Widget _buildCallScreen(BuildContext context, WidgetRef ref, td.Call call) {
    final user = ref.watch(userByIdProvider(call.userId));
    final isIncoming = !call.isOutgoing && call.state is td.CallStatePending;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF285373), Color(0xFF101B20)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Avatar
            ChatAvatar(
              file: user?.profilePhoto?.big,
              name: user != null ? '${user.firstName} ${user.lastName}' : 'Unknown',
              radius: 60,
            ),
            const SizedBox(height: 24),
            // Name
            Text(
              user != null ? '${user.firstName} ${user.lastName}' : 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Status
            Text(
              _getCallStatusText(call),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            
            const Spacer(),
            if (ref.watch(callNotifierProvider).nativeMessage != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      ref.watch(callNotifierProvider).nativeMessage!,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),

            // Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
              child: Row(
                mainAxisAlignment: isIncoming
                    ? MainAxisAlignment.spaceAround
                    : MainAxisAlignment.center,
                children: [
                  if (isIncoming) ...[
                    // Decline
                    _CallButton(
                      icon: Icons.call_end,
                      color: AppTheme.tgRed,
                      label: 'Decline',
                      onPressed: () => ref.read(callNotifierProvider.notifier).discardCall(call.id),
                    ),
                    // Accept
                    _CallButton(
                      icon: Icons.call,
                      color: AppTheme.tgGreen,
                      label: 'Accept',
                      onPressed: () => ref.read(callNotifierProvider.notifier).acceptCall(call.id),
                    ),
                  ] else ...[
                    // End call
                    _CallButton(
                      icon: Icons.call_end,
                      color: AppTheme.tgRed,
                      label: 'End Call',
                      onPressed: () => ref.read(callNotifierProvider.notifier).discardCall(call.id),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCallStatusText(td.Call call) {
    if (call.state is td.CallStatePending) {
      return call.isOutgoing ? 'Ringing...' : 'Telegram Audio...';
    }
    if (call.state is td.CallStateExchangingKeys) {
      return 'Connecting...';
    }
    if (call.state is td.CallStateReady) {
      final m = (_seconds ~/ 60).toString().padLeft(2, '0');
      final s = (_seconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    if (call.state is td.CallStateHangingUp) {
      return 'Hanging up...';
    }
    return 'Calling...';
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: color,
          onPressed: onPressed,
          elevation: 0,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
