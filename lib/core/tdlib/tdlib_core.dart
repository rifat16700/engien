import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tdlib/td_api.dart' as td;
import 'package:tdlib/tdlib.dart';

// ─── TDLib Constants ───────────────────────────────────────────────────────
// আপনার Telegram API ID এবং Hash যা my.telegram.org থেকে পাওয়া
const int _kApiId = 24255398;
const String _kApiHash = '49d35a381af2befd1eecc77d34ca7090';

// ─── Event callback type ───────────────────────────────────────────────────
typedef TdEventCallback = void Function(Map<String, dynamic> event);

/// TDLib এর low-level wrapper।
/// এটি শুধু TDLib এর সাথে কথা বলে এবং events গুলো broadcast করে।
/// Business logic (Riverpod notifiers) এখানে থাকবে না।
class TdlibCore {
  int _clientId = 0;
  bool _isReceiving = false;
  bool _tdlibParamsSent = false;

  final StreamController<Map<String, dynamic>> _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;

  bool get isInitialized => _clientId != 0;

  // ─── Initialize ──────────────────────────────────────────────────────────
  Future<void> initialize(String? libraryPath) async {
    await TdPlugin.initialize(libraryPath);
  }

  void createClient() {
    _clientId = tdCreate();
    // Reduce log verbosity to errors/warnings only (level 1) to stop console spam
    send(const td.SetLogVerbosityLevel(newVerbosityLevel: 1));
    _startReceiveLoop();
  }

  // ─── Send ─────────────────────────────────────────────────────────────────
  void send(td.TdFunction function, [dynamic extra]) {
    if (_clientId == 0) return;
    tdSend(_clientId, function, extra);
  }

  void sendRaw(Map<String, dynamic> json) {
    if (_clientId == 0) return;
    TdPlugin.instance.tdSend(_clientId, jsonEncode(json));
  }

  // ─── Receive loop ─────────────────────────────────────────────────────────
  Future<void> _startReceiveLoop() async {
    if (_isReceiving) return;
    _isReceiving = true;
    while (_isReceiving) {
      try {
        final raw = TdPlugin.instance.tdReceive(0);
        if (raw != null) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            _eventStreamController.add(decoded);
          }
        }
      } catch (e) {
        debugPrint('TdlibCore receive error: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  // ─── Setup TDLib params ───────────────────────────────────────────────────
  Future<void> sendTdlibParams() async {
    if (_tdlibParamsSent) return;
    _tdlibParamsSent = true;
    try {
      debugPrint('Sending Tdlib parameters...');
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('App doc dir: ${dir.path}');
      final dbDir = p.join(dir.path, 'nchat_tdlib');
      send(td.SetTdlibParameters(
      useTestDc: false,
      databaseDirectory: dbDir,
      filesDirectory: p.join(dbDir, 'files'),
      databaseEncryptionKey: '',
      useFileDatabase: true,
      useChatInfoDatabase: true,
      useMessageDatabase: true,     // TDLib নিজেই সব মেসেজ DB তে রাখে
      useSecretChats: true,
      apiId: _kApiId,
      apiHash: _kApiHash,
      systemLanguageCode: 'en',
      deviceModel: 'Android',
      systemVersion: '1.0',
      applicationVersion: '1.0.0',
      enableStorageOptimizer: true,
      ignoreFileNames: false,
    ));
    } catch (e) {
      debugPrint('Error sending tdlib params: $e');
    }
  }

  // ─── File download ────────────────────────────────────────────────────────
  void downloadFile(int fileId, {int priority = 1}) {
    send(td.DownloadFile(
      fileId: fileId,
      priority: priority,
      offset: 0,
      limit: 0,
      synchronous: false,
    ));
  }

  // ─── Load chats ───────────────────────────────────────────────────────────
  /// TDLib এর recommended method: GetChats এর বদলে LoadChats ব্যবহার করা।
  /// এটি TDLib এর নিজস্ব ডাটাবেস থেকে দ্রুত চ্যাট লোড করে UpdateNewChat ইভেন্ট পাঠায়।
  void loadChats({int limit = 100}) {
    send(td.LoadChats(chatList: const td.ChatListMain(), limit: limit));
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    _isReceiving = false;
    if (_clientId != 0) {
      send(const td.Close());
      _clientId = 0;
    }
    await _eventStreamController.close();
  }
}
