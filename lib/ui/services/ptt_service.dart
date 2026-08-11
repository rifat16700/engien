import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tdlib/td_api.dart' as td;
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../core/providers/file_provider.dart';
import '../../core/providers/tdlib_event_handler.dart';

// ─── PTT State ────────────────────────────────────────────────────────────
class PttState {
  final bool isRecording;
  final bool isPlaying;
  final int? activeChatId;

  const PttState({
    this.isRecording = false,
    this.isPlaying = false,
    this.activeChatId,
  });

  PttState copyWith({
    bool? isRecording,
    bool? isPlaying,
    int? activeChatId,
  }) {
    return PttState(
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      activeChatId: activeChatId ?? this.activeChatId,
    );
  }
}

// ─── PTT Service (Notifier) ───────────────────────────────────────────────
class PttNotifier extends Notifier<PttState> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _playQueue = <td.Message>[];

  Timer? _chunkTimer;
  int _chunkCounter = 0;
  String? _currentRecordPath;

  @override
  PttState build() {
    ref.onDispose(() {
      _recorder.dispose();
      _player.dispose();
      _chunkTimer?.cancel();
    });

    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _playNextInQueue();
      }
    });

    return const PttState();
  }

  // Expose amplitude stream for 60fps waveform
  Stream<Amplitude> get amplitudeStream => _recorder.onAmplitudeChanged(const Duration(milliseconds: 16));

  // ─── Sending (Recording Chunks) ─────────────────────────────────────────

  Future<void> startPtt(int chatId) async {
    if (state.isRecording) return;
    if (!await _recorder.hasPermission()) return;

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      service.startService();
    }

    state = state.copyWith(isRecording: true, activeChatId: chatId);
    _chunkCounter = 0;
    await _startNextChunk();
  }

  Future<void> stopPtt() async {
    if (!state.isRecording) return;
    _chunkTimer?.cancel();
    _chunkTimer = null;
    await _finishChunkAndSend(isFinal: true);
    state = state.copyWith(isRecording: false, activeChatId: null);

    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  Future<void> _startNextChunk() async {
    final dir = await getTemporaryDirectory();
    _currentRecordPath = p.join(
      dir.path,
      'ptt_${DateTime.now().millisecondsSinceEpoch}_$_chunkCounter.m4a',
    );
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000), // Low bitrate for speed
      path: _currentRecordPath!,
    );

    // Send chunk every 2 seconds for low latency
    _chunkTimer = Timer(const Duration(seconds: 2), () async {
      await _finishChunkAndSend(isFinal: false);
      if (state.isRecording) {
        _chunkCounter++;
        await _startNextChunk();
      }
    });
  }

  Future<void> _finishChunkAndSend({required bool isFinal}) async {
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) return;

    final file = File(path);
    if (!await file.exists() || await file.length() < 1000) {
      // Too small, skip
      return;
    }

    final chatId = state.activeChatId;
    if (chatId == null) return;

    final tag = '#PTT_CHUNK_${_chunkCounter.toString().padLeft(3, '0')}${isFinal ? "_END" : ""}';

    ref.read(tdlibCoreProvider).send(td.SendMessage(
      chatId: chatId,
      messageThreadId: 0,
      replyTo: null,
      options: const td.MessageSendOptions(
        disableNotification: true, // Silent to prevent spam
        fromBackground: false,
        protectContent: false,
        updateOrderOfInstalledStickerSets: false,
        schedulingState: null,
        sendingId: 0,
      ),
      replyMarkup: null,
      inputMessageContent: td.InputMessageVoiceNote(
        voiceNote: td.InputFileLocal(path: path),
        duration: 0,
        waveform: '',
        caption: td.FormattedText(text: tag, entities: []), // Hidden tag
      ),
    ));
  }

  // ─── Receiving (Playing Queue) ──────────────────────────────────────────

  void enqueueChunk(td.Message message) {
    if (message.content is! td.MessageVoiceNote) return;

    _playQueue.add(message);
    _playQueue.sort((a, b) => a.date.compareTo(b.date)); // Keep chronological

    if (!state.isPlaying) {
      _playNextInQueue();
    }
  }

  Future<void> _playNextInQueue() async {
    if (_playQueue.isEmpty) {
      state = state.copyWith(isPlaying: false);
      return;
    }

    state = state.copyWith(isPlaying: true);
    final msg = _playQueue.removeAt(0);
    final content = msg.content as td.MessageVoiceNote;

    final file = content.voiceNote.voice;
    String? localPath;

    if (file.local.isDownloadingCompleted && file.local.path.isNotEmpty) {
      localPath = file.local.path;
    } else {
      // Need to download it first
      ref.read(tdlibCoreProvider).downloadFile(file.id, priority: 32); // High priority
      // Wait for it? Let's just poll for a bit for simplicity in this prototype
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final updatedFile = ref.read(fileNotifierProvider.notifier).getFile(file.id);
        if (updatedFile?.local.isDownloadingCompleted == true) {
          localPath = updatedFile!.local.path;
          break;
        }
      }
    }

    if (localPath != null && File(localPath).existsSync()) {
      try {
        await _player.setFilePath(localPath);
        await _player.play();
      } catch (e) {
        debugPrint('Error playing chunk: $e');
        _playNextInQueue();
      }
    } else {
      // Failed to download or find, skip
      _playNextInQueue();
    }
  }
}

final pttNotifierProvider = NotifierProvider<PttNotifier, PttState>(
  PttNotifier.new,
);
