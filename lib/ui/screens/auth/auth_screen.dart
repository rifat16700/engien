import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/theme/app_theme.dart';
import 'country_picker.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  String _selectedCallingCode = '+880';
  String _selectedCountryFlag = '🇧🇩';
  String _selectedCountryName = 'Bangladesh';
  bool _passwordVisible = false;

  // OTP 5-digit inputs
  final List<TextEditingController> _otpControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(5, (_) => FocusNode());

  // Countdown timer
  int _secondsLeft = 120;
  Timer? _countdownTimer;
  bool _hasVerified = false;

  // Shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = 120);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      if (mounted) setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Start countdown when code screen appears
    ref.listen(authNotifierProvider, (prev, next) {
      if (next.needsCode && !(prev?.needsCode ?? false)) {
        _startCountdown();
        _hasVerified = false;
      }
      // Shake on error and clear OTP boxes so user can retry
      if (next.errorMessage != null && prev?.errorMessage == null) {
        _shakeController.forward(from: 0);
        // Clear all OTP boxes so user can type again
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            for (final c in _otpControllers) { c.clear(); }
            setState(() => _hasVerified = false);
            _otpFocusNodes[0].requestFocus();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
          child: _buildBody(authState),
        ),
      ),
    );
  }

  Widget _buildBody(AuthState authState) {
    if (authState.needsCode) return _buildCodeScreen(authState);
    if (authState.needsPassword) return _buildPasswordScreen(authState);
    return _buildPhoneScreen(authState);
  }

  // ─── Phone Number Screen ─────────────────────────────────────────────────
  Widget _buildPhoneScreen(AuthState authState) {
    return SingleChildScrollView(
      key: const ValueKey('phone'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppTheme.tgBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_rounded, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Phone',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Please confirm your country code\nand enter your phone number.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Country selector
          GestureDetector(
            onTap: _openCountryPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Text(_selectedCountryFlag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCountryName,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),

          // Phone number input
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: TextEditingController(text: _selectedCallingCode),
                    readOnly: true,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Phone Number',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitPhone(authState),
                  ),
                ),
              ],
            ),
          ),

          if (authState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                authState.errorMessage!,
                style: const TextStyle(color: AppTheme.tgRed, fontSize: 14),
              ),
            ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authState.isSubmitting ? null : () => _submitPhone(authState),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tgBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: authState.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── OTP Code Screen ──────────────────────────────────────────────────────
  Widget _buildCodeScreen(AuthState authState) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final timerStr = '$minutes:$seconds';

    return SingleChildScrollView(
      key: const ValueKey('code'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppTheme.tgBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.message_rounded, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('Enter Code', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            "We've sent a code to $_selectedCallingCode ${_phoneController.text}",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // 5-digit OTP boxes with shake on error
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) => _buildOtpBox(i, authState)),
              ),
            ),
          ), const SizedBox(height: 20),

          // Timer
          Text(
            _secondsLeft > 0 ? timerStr : '00:00',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _secondsLeft > 0 ? AppTheme.tgBlue : Colors.grey,
            ),
          ),

          if (authState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                authState.errorMessage!,
                style: const TextStyle(color: AppTheme.tgRed, fontSize: 14),
              ),
            ),

          const SizedBox(height: 24),

          // Resend buttons (active when timer hits 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _secondsLeft == 0
                    ? () {
                        ref.read(tdlibCoreProvider).sendRaw({'@type': 'resendAuthenticationCode'});
                        _startCountdown();
                        for (final c in _otpControllers) { c.clear(); }
                        setState(() => _hasVerified = false);
                        _otpFocusNodes[0].requestFocus();
                      }
                    : null,
                child: Text(
                  'Send via SMS',
                  style: TextStyle(
                    color: _secondsLeft == 0 ? AppTheme.tgBlue : Colors.grey,
                  ),
                ),
              ),
              Text('•', style: TextStyle(color: Colors.grey[400])),
              TextButton(
                onPressed: _secondsLeft == 0
                    ? () {
                        ref.read(tdlibCoreProvider).sendRaw({'@type': 'resendAuthenticationCode'});
                        _startCountdown();
                        for (final c in _otpControllers) { c.clear(); }
                        setState(() => _hasVerified = false);
                        _otpFocusNodes[0].requestFocus();
                      }
                    : null,
                child: Text(
                  'Call Me',
                  style: TextStyle(
                    color: _secondsLeft == 0 ? AppTheme.tgBlue : Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Manual verify button — always visible as fallback
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authState.isSubmitting ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tgBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: authState.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),

        ],
      ),
    );
  }

  void _verifyOtp() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length == 5 && !_hasVerified) {
      _hasVerified = true;
      FocusScope.of(context).unfocus();
      ref.read(authNotifierProvider.notifier).checkCode(code);
    }
  }

  Widget _buildOtpBox(int index, AuthState authState) {
    final hasError = authState.errorMessage != null;
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError ? AppTheme.tgRed : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError ? AppTheme.tgRed : AppTheme.tgBlue,
              width: 2,
            ),
          ),
        ),
        onChanged: (val) {
          // Clear error state on new input
          if (authState.errorMessage != null) {
            setState(() => _hasVerified = false);
          }
          if (val.isNotEmpty && index < 4) {
            // Move to next box
            _otpFocusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            // Move back on delete
            _otpFocusNodes[index - 1].requestFocus();
          }
          // Auto-submit when all 5 digits filled
          final code = _otpControllers.map((c) => c.text).join();
          if (code.length == 5 && !_hasVerified) {
            _verifyOtp();
          }
        },
        onTap: () {
          _otpControllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _otpControllers[index].text.length),
          );
        },
      ),
    );
  }

  // ─── 2FA Password Screen ──────────────────────────────────────────────────
  Widget _buildPasswordScreen(AuthState authState) {
    return SingleChildScrollView(
      key: const ValueKey('password'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Animated padlock
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppTheme.tgBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 52, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Two-Step Verification',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Please enter your password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: child,
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.tgBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.tgRed, width: 2),
                ),
                errorText: authState.errorMessage,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              onSubmitted: (_) => _submitPassword(authState),
            ),
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ref.read(tdlibCoreProvider).sendRaw({
                  '@type': 'recoverAuthenticationPassword',
                  'recovery_code': '',
                });
              },
              child: const Text('Forgot password?', style: TextStyle(color: AppTheme.tgBlue)),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authState.isSubmitting ? null : () => _submitPassword(authState),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tgBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: authState.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _submitPhone(AuthState authState) {
    final phone = '$_selectedCallingCode${_phoneController.text.trim()}';
    if (phone.length < 8) return;
    ref.read(authNotifierProvider.notifier).loginWithPhone(phone);
  }

  void _submitPassword(AuthState authState) {
    final pass = _passwordController.text;
    if (pass.isEmpty) return;
    ref.read(authNotifierProvider.notifier).checkPassword(pass);
  }

  void _openCountryPicker() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CountryPickerSheet(),
    );
    if (result != null) {
      setState(() {
        _selectedCallingCode = '+${result['code']!}';
        _selectedCountryFlag = result['flag']!;
        _selectedCountryName = result['name']!;
      });
      _phoneFocusNode.requestFocus();
    }
  }
}
