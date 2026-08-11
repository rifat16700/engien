import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:record/record.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../services/ptt_service.dart';
import 'physics/voice_record_button.dart';

import '../../../core/providers/chat_list_provider.dart';
import '../../../core/providers/messages_provider.dart';

// ─── Message Input Widget ─────────────────────────────────────────────────
class MessageInput extends ConsumerStatefulWidget {
  final int chatId;

  const MessageInput({super.key, required this.chatId});

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  final AudioRecorder _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _cancelReply() {
    ref.read(tdlibCoreProvider).send(td.SetChatDraftMessage(
      chatId: widget.chatId,
      messageThreadId: 0,
      draftMessage: null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatListNotifierProvider).chats[widget.chatId];
    final draft = chat?.draftMessage;
    final int? replyToMessageId = (draft != null && draft.replyToMessageId != 0) ? draft.replyToMessageId : null;
    
    td.Message? replyMsg;
    if (replyToMessageId != null) {
      final msgs = ref.read(messagesNotifierProvider(widget.chatId)).messages;
      final idx = msgs.indexWhere((m) => m.id == replyToMessageId);
      if (idx != -1) replyMsg = msgs[idx];
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, -1))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply Banner
            if (replyToMessageId != null && replyMsg != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, color: AppTheme.tgBlue),
                    const SizedBox(width: 8),
                    Container(width: 2, height: 32, color: AppTheme.tgBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reply to Message', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            _getSnippet(replyMsg.content),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.tgGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.tgGrey),
                      onPressed: _cancelReply,
                    ),
                  ],
                ),
              ),
            
            // Input Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: AppTheme.tgGrey),
                  onPressed: _attachFile,
                ),

                // Text field or Waveform
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final isRecording = ref.watch(pttNotifierProvider).isRecording;
                      
                      return AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: isRecording
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  maxLines: 5,
                                  minLines: 1,
                                  textInputAction: TextInputAction.newline,
                                  decoration: const InputDecoration(
                                    hintText: 'Message',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              // Emoji button
                              IconButton(
                                icon: const Icon(Icons.emoji_emotions_outlined, color: AppTheme.tgGrey),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        secondChild: Container(
                          height: 50,
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              const Text(
                                'Recording...',
                                style: TextStyle(color: AppTheme.tgRed, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildWaveform(ref),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 4),

                // Send / Mic / PTT button
                VoiceRecordButton(
                  chatId: widget.chatId,
                  hasText: _hasText,
                  onSendText: _sendText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSnippet(td.MessageContent content) {
    if (content is td.MessageText) return content.text.text;
    if (content is td.MessagePhoto) return 'Photo';
    if (content is td.MessageVideo) return 'Video';
    if (content is td.MessageVoiceNote) return 'Voice message';
    if (content is td.MessageDocument) return 'Document';
    if (content is td.MessageSticker) return 'Sticker';
    return 'Message';
  }

  Widget _buildWaveform(WidgetRef ref) {
    return StreamBuilder<Amplitude>(
      stream: ref.read(pttNotifierProvider.notifier).amplitudeStream,
      builder: (context, snapshot) {
        // Amplitude is typically between -160 and 0.
        // We normalize it: if it's below -60 it's 0, if it's 0 it's 1.0.
        double currentDb = snapshot.data?.current ?? -60.0;
        double normalized = ((currentDb + 60.0) / 60.0).clamp(0.0, 1.0);
        
        final barHeight = 6.0 + (normalized * 24.0); // max height 30
        
        return Row(
          children: List.generate(
            20,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: barHeight,
              decoration: BoxDecoration(
                color: AppTheme.tgBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }
    );
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final chat = ref.read(chatListNotifierProvider).chats[widget.chatId];
    final draft = chat?.draftMessage;
    final int? replyToId = (draft != null && draft.replyToMessageId != 0) ? draft.replyToMessageId : null;

    ref.read(tdlibCoreProvider).send(td.SendMessage(
      chatId: widget.chatId,
      messageThreadId: 0,
      replyTo: replyToId != null ? td.MessageReplyToMessage(chatId: widget.chatId, messageId: replyToId) : null,
      options: const td.MessageSendOptions(
        disableNotification: false,
        fromBackground: false,
        protectContent: false,
        updateOrderOfInstalledStickerSets: false,
        schedulingState: null,
        sendingId: 0,
      ),
      replyMarkup: null,
      inputMessageContent: td.InputMessageText(
        text: td.FormattedText(text: text, entities: []),
        disableWebPagePreview: false,
        clearDraft: true,
      ),
    ));
    
    // Clear draft locally too
    if (replyToId != null) {
      _cancelReply();
    }
  }

  Future<void> _startVoiceRecord() async {
    ref.read(pttNotifierProvider.notifier).startPtt(widget.chatId);
  }

  Future<void> _stopVoiceRecord() async {
    ref.read(pttNotifierProvider.notifier).stopPtt();
  }

  void _attachFile() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(icon: Icons.photo_rounded, label: 'Photo', onTap: () {}),
                _AttachOption(icon: Icons.videocam_rounded, label: 'Video', onTap: () {}),
                _AttachOption(icon: Icons.insert_drive_file_rounded, label: 'File', onTap: () {}),
                _AttachOption(icon: Icons.location_on_rounded, label: 'Location', onTap: () {}),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(icon: Icons.person_rounded, label: 'Contact', onTap: () {}),
                _AttachOption(icon: Icons.music_note_rounded, label: 'Music', onTap: () {}),
                _AttachOption(icon: Icons.gif_box_rounded, label: 'GIF', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppTheme.tgBlue, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.tgGrey)),
        ],
      ),
    );
  }
}
