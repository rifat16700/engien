import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;

// ─── File State ───────────────────────────────────────────────────────────
class FileNotifier extends Notifier<Map<int, td.File>> {
  @override
  Map<int, td.File> build() => {};

  void updateFile(td.File file) {
    state = {...state, file.id: file};
  }

  td.File? getFile(int fileId) => state[fileId];

  bool isDownloaded(int fileId) {
    final file = state[fileId];
    return file?.local.isDownloadingCompleted == true;
  }

  String? getLocalPath(int fileId) {
    final file = state[fileId];
    if (file?.local.isDownloadingCompleted == true) {
      return file!.local.path.isNotEmpty ? file.local.path : null;
    }
    return null;
  }
}

final fileNotifierProvider =
    NotifierProvider<FileNotifier, Map<int, td.File>>(
  FileNotifier.new,
);

// ─── Convenience provider ─────────────────────────────────────────────────
final fileByIdProvider = Provider.family<td.File?, int>((ref, fileId) {
  return ref.watch(fileNotifierProvider)[fileId];
});
