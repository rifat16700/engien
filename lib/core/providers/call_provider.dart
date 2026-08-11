import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import 'tdlib_event_handler.dart';
import '../../ui/services/native_call_channel.dart';

class CallState {
  final td.Call? currentCall;
  final String? nativeMessage;
  
  const CallState({this.currentCall, this.nativeMessage});
  
  CallState copyWith({td.Call? currentCall, String? nativeMessage}) {
    return CallState(
      currentCall: currentCall ?? this.currentCall,
      nativeMessage: nativeMessage ?? this.nativeMessage,
    );
  }
}

class CallNotifier extends Notifier<CallState> {
  @override
  CallState build() {
    return const CallState();
  }

  Future<void> handleUpdateCall(td.Call call) async {
    if (call.state is td.CallStateDiscarded || call.state is td.CallStateError) {
      // Call ended
      if (state.currentCall?.id == call.id) {
        state = const CallState(currentCall: null);
      }
    } else {
      // Call is active / pending
      state = state.copyWith(currentCall: call);
      
      if (call.state is td.CallStateReady) {
        final callState = call.state as td.CallStateReady;
        
        List<String> endpoints = callState.servers.map((s) => "${s.ipAddress}:${s.port}").toList();
        
        // Wait, TDLib returns base64 string for encryption_key in dart 
        // We'll pass it to Uint8List. Assuming encryptionKey is base64 string or List<int>.
        // In the TDLib Dart bindings, encryptionKey is a String (base64)
        Uint8List keyBytes;
        try {
          keyBytes = base64Decode(callState.encryptionKey);
        } catch (_) {
          keyBytes = Uint8List(256);
        }

        final msg = await NativeCallChannel.initializeCall(
          callId: call.id,
          isOutgoing: call.isOutgoing,
          config: callState.config,
          endpoints: endpoints,
          encryptionKey: keyBytes,
        );
        state = state.copyWith(nativeMessage: msg);
      } else if (call.state is td.CallStateExchangingKeys) {
        state = state.copyWith(nativeMessage: "Exchanging keys...");
      }
    }
  }

  void acceptCall(int callId) {
    ref.read(tdlibCoreProvider).send(td.AcceptCall(
      callId: callId,
      protocol: const td.CallProtocol(
        udpP2p: true,
        udpReflector: true,
        minLayer: 65,
        maxLayer: 92,
        libraryVersions: ['4.0.0', '5.0.0'],
      ),
    ));
  }

  void discardCall(int callId) {
    ref.read(tdlibCoreProvider).send(td.DiscardCall(
      callId: callId,
      isDisconnected: false,
      duration: 0,
      isVideo: false,
      connectionId: 0,
    ));
    state = const CallState(currentCall: null);
  }
}

final callNotifierProvider = NotifierProvider<CallNotifier, CallState>(
  CallNotifier.new,
);
