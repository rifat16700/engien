import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import 'tdlib_event_handler.dart';

// ─── Auth State ───────────────────────────────────────────────────────────
class AuthState {
  final String authorizationState;
  final bool isSubmitting;
  final String? errorMessage;

  const AuthState({
    this.authorizationState = 'initializing',
    this.isSubmitting = false,
    this.errorMessage,
  });

  AuthState copyWith({
    String? authorizationState,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AuthState(
      authorizationState: authorizationState ?? this.authorizationState,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  bool get isReady => authorizationState == td.AuthorizationStateReady.CONSTRUCTOR;
  bool get needsPhone => authorizationState == td.AuthorizationStateWaitPhoneNumber.CONSTRUCTOR;
  bool get needsCode => authorizationState == td.AuthorizationStateWaitCode.CONSTRUCTOR;
  bool get needsPassword => authorizationState == td.AuthorizationStateWaitPassword.CONSTRUCTOR;
  bool get isInitializing => authorizationState == 'initializing';
}

// ─── Auth Notifier ────────────────────────────────────────────────────────
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void handleUpdate(Map<String, dynamic> event) {
    final authStateMap = event['authorization_state'] as Map<String, dynamic>?;
    if (authStateMap == null) return;
    final stateType = authStateMap['@type'] as String;
    _onStateChange(stateType, authStateMap);
  }

  void _onStateChange(String stateType, Map<String, dynamic> stateData) {
    state = state.copyWith(
      authorizationState: stateType,
      isSubmitting: false,
      errorMessage: null,
    );

    final core = ref.read(tdlibCoreProvider);

    switch (stateType) {
      case td.AuthorizationStateWaitTdlibParameters.CONSTRUCTOR:
        core.sendTdlibParams();
        break;
      case td.AuthorizationStateReady.CONSTRUCTOR:
        // Load initial data
        core.send(const td.GetMe());
        core.loadChats(limit: 20);
        break;
    }
  }

  void handleError(Map<String, dynamic> event) {
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: 'Error ${event['code']}: ${event['message']}',
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────
  void loginWithPhone(String fullPhone) {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    ref.read(tdlibCoreProvider).sendRaw({
      '@type': 'setAuthenticationPhoneNumber',
      'phone_number': fullPhone,
      'settings': {
        '@type': 'phoneNumberAuthenticationSettings',
        'allow_flash_call': false,
        'is_current_phone_number': false,
        'allow_sms_retriever_api': false,
        'authentication_tokens': [],
      }
    });
  }

  void checkCode(String code) {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    ref.read(tdlibCoreProvider).sendRaw({
      '@type': 'checkAuthenticationCode',
      'code': code,
    });
  }

  void checkPassword(String password) {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    ref.read(tdlibCoreProvider).sendRaw({
      '@type': 'checkAuthenticationPassword',
      'password': password,
    });
  }

  void logout() {
    ref.read(tdlibCoreProvider).send(const td.LogOut());
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
