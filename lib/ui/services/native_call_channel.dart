import 'package:flutter/services.dart';

class NativeCallChannel {
  static const MethodChannel _channel = MethodChannel('com.nchat/tgcalls');

  static Future<String?> initializeCall({
    required int callId,
    required bool isOutgoing,
    required String config,
    required List<String> endpoints,
    required Uint8List encryptionKey,
  }) async {
    try {
      final String? resultMessage = await _channel.invokeMethod('initCall', {
        'callId': callId,
        'isOutgoing': isOutgoing,
        'config': config,
        'endpoints': endpoints,
        'encryptionKey': encryptionKey,
      });
      print("\n\n********************************************************");
      print("NATIVE CALL RESULT: $resultMessage");
      print("********************************************************\n\n");
      return resultMessage;
    } on PlatformException catch (e) {
      print("\n\n********************************************************");
      print("Failed to init native call: ${e.message}");
      print("********************************************************\n\n");
      return "ERROR: ${e.message}";
    }
  }
}
