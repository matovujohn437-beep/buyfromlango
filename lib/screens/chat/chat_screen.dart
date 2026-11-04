import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import '../../constants/app_assets.dart';
import '../../models/chat_thread.dart';
import '../../models/message.dart';
import '../../models/seller_tag.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/seller_tools_provider.dart';
import '../../services/chat_service.dart';
import '../../theme.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/seller_tag_picker_sheet.dart';
import '../../widgets/smart_responses_sheet.dart';

class ChatRouteData {
  const ChatRouteData({required this.otherUserName});

  final String otherUserName;
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.otherUserName,
  });

  final int threadId;
  final String otherUserName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _recorder = AudioRecorder();
  BytesBuilder? _recordingBuffer;
  StreamSubscription<Uint8List>? _recordingSubscription;
  Completer<void>? _recordingClosed;
  MessageModel? _replyTo;
  bool _isSending = false;
  bool _isRecording = false;

  @override
  void dispose() {
    _messageController.dispose();
    unawaited(_recordingSubscription?.cancel());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final messages = ref.watch(threadMessagesProvider(widget.threadId));
    final thread = ref.watch(chatThreadProvider(widget.threadId)).valueOrNull;
    final otherUserId = thread == null || user == null
        ? null
        : thread.buyerId == user.id
            ? thread.sellerId
            : thread.buyerId;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.otherUserName,
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Manage conversation tags',
              onPressed: () => _manageChatTags(user.id),
              icon: const Icon(Icons.sell_outlined),
            ),
          if (otherUserId != null)
            IconButton(
              tooltip: 'View seller catalog',
              onPressed: () => context.push('/seller/$otherUserId'),
              icon: const Icon(Icons.storefront_outlined),
            ),
        ],
      ),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 1),
      body: ResponsiveContent(
        maxWidth: 1000,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            if (user != null)
              ref.watch(chatTagKeysProvider((user.id, widget.threadId))).when(
                    loading: () => const SizedBox.shrink(),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Text(
                        'Could not load conversation tags: $error',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                    data: (tagKeys) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: tagKeys.isEmpty
                                ? Text(
                                    'No tags yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  )
                                : SellerTagPills(tagKeys: tagKeys),
                          ),
                          IconButton(
                            tooltip: 'Add or manage conversation tags',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _manageChatTags(user.id),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
            Expanded(
              child: messages.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load this conversation: $error'),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(
                            threadMessagesProvider(widget.threadId),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? const EmptyState(
                        title: 'Start the conversation',
                        message: 'Send a message to discuss this listing.',
                        imagePath: AppAssets.emptyChat,
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final message = items[items.length - 1 - index];
                          final replyTo = message.replyTo == null
                              ? null
                              : items
                                  .where((item) => item.id == message.replyTo)
                                  .firstOrNull;
                          return _MessageBubble(
                            message: message,
                            replyToMessage: replyTo,
                            isMine: message.senderId == user?.id,
                            onReply: () => setState(() => _replyTo = message),
                            onForward: () => _forwardMessage(message, user?.id),
                          );
                        },
                      ),
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyTo case final reply?)
                    _ReplyPreview(
                      message: reply,
                      onClose: () => setState(() => _replyTo = null),
                    ),
                  if (_isRecording)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: Text('Recording voice note… Tap the mic to send'),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Attach image or video',
                          onPressed: _isSending || _isRecording
                              ? null
                              : _showAttachmentOptions,
                          icon: const Icon(Icons.attach_file),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: 4000,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Write a message',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              suffixIcon: IconButton(
                                tooltip: 'Choose a Smart Response',
                                onPressed: user == null
                                    ? null
                                    : () => showSmartResponsesSheet(
                                          context: context,
                                          ref: ref,
                                          userId: user.id,
                                          onSelected: (content) {
                                            _messageController
                                              ..text = content
                                              ..selection =
                                                  TextSelection.collapsed(
                                                offset: content.length,
                                              );
                                          },
                                        ),
                                icon: const Icon(Icons.auto_awesome),
                                color: AppColors.primary,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(user?.id),
                          ),
                        ),
                        IconButton(
                          tooltip: _isRecording
                              ? 'Stop and send voice note'
                              : 'Record voice note',
                          onPressed: _isSending || user == null
                              ? null
                              : _isRecording
                                  ? _stopAndSendVoiceNote
                                  : _startVoiceNote,
                          color: _isRecording ? AppColors.error : null,
                          icon: Icon(
                            _isRecording ? Icons.stop_circle : Icons.mic_none,
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Send message',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primaryDark,
                            disabledForegroundColor: Colors.white,
                          ),
                          onPressed: _isSending || user == null
                              ? null
                              : () => _sendMessage(user.id),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manageChatTags(String userId) async {
    try {
      final service = ref.read(sellerToolsServiceProvider);
      final keys = await service.getChatTagKeys(
        userId: userId,
        threadId: widget.threadId,
      );
      if (!mounted) return;
      await showSellerTagPicker(
        context: context,
        title: 'Tag this conversation',
        selectedTags: keys.map(SellerTag.byKey).whereType<SellerTag>().toList(),
        onSave: (tags) => service.setChatTags(
          threadId: widget.threadId,
          tags: tags,
        ),
        onSaved: () => ref.invalidate(
          chatTagKeysProvider((userId, widget.threadId)),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load conversation tags: $error')),
        );
      }
    }
  }

  Future<void> _sendMessage(String? senderId) async {
    final content = _messageController.text.trim();
    if (content.isEmpty || senderId == null || _isSending) return;

    final sent = await _sendPayload(
      senderId: senderId,
      threadId: widget.threadId,
      content: content,
      mediaType: 'text',
      replyTo: _replyTo?.id,
    );
    if (sent && mounted) {
      _messageController.clear();
      setState(() => _replyTo = null);
    }
  }

  Future<bool> _sendPayload({
    required String senderId,
    required int threadId,
    required String mediaType,
    String? content,
    String? mediaUrl,
    int? replyTo,
    int? forwardedFrom,
  }) async {
    if (!mounted) return false;
    setState(() => _isSending = true);
    try {
      await ref.read(chatServiceProvider).sendMessage({
        'thread_id': threadId,
        'sender_id': senderId,
        'content': content,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'reply_to': replyTo,
        'forwarded_from': forwardedFrom,
      });
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showAttachmentOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment(isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment(
                  isVideo: false,
                  source: ImageSource.camera,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment(isVideo: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_camera_back_outlined),
              title: const Text('Record video note'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment(
                  isVideo: true,
                  source: ImageSource.camera,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAttachment({
    required bool isVideo,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();
      final file = isVideo
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source);
      final userId = ref.read(currentUserProvider)?.id;
      if (file == null || userId == null || !mounted) return;
      setState(() => _isSending = true);
      final bytes = await file.readAsBytes();
      final extension = isVideo
          ? _extensionOf(file.name, fallback: 'mp4')
          : _extensionOf(file.name, fallback: 'jpg');
      final allowedExtensions = isVideo
          ? const {'mp4', 'mov', 'webm'}
          : const {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
      if (!allowedExtensions.contains(extension)) {
        throw FormatException('Unsupported media format: .$extension');
      }
      final contentType =
          isVideo ? _videoContentType(extension) : _imageContentType(extension);
      final path = await ref.read(chatServiceProvider).uploadChatMedia(
            bytes: bytes,
            threadId: widget.threadId,
            userId: userId,
            extension: extension,
            contentType: contentType,
          );
      final sent = await _sendPayload(
        senderId: userId,
        threadId: widget.threadId,
        mediaType: isVideo ? 'video' : 'image',
        mediaUrl: path,
        replyTo: _replyTo?.id,
      );
      if (sent && mounted) setState(() => _replyTo = null);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach media: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _startVoiceNote() async {
    try {
      if (!await _recorder.hasPermission()) {
        throw StateError('Microphone permission is required to record audio.');
      }
      const config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      );
      if (kIsWeb) {
        await _recorder.start(
          config,
          path: 'voice-note-${DateTime.now().microsecondsSinceEpoch}.webm',
        );
      } else {
        final stream = await _recorder.startStream(config);
        final buffer = BytesBuilder(copy: false);
        final closed = Completer<void>();
        _recordingBuffer = buffer;
        _recordingClosed = closed;
        _recordingSubscription = stream.listen(
          buffer.add,
          onError: closed.completeError,
          onDone: () {
            if (!closed.isCompleted) closed.complete();
          },
        );
      }
      if (mounted) setState(() => _isRecording = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start voice note: $error')),
        );
      }
    }
  }

  Future<void> _stopAndSendVoiceNote() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null || !_isRecording) return;
    setState(() {
      _isRecording = false;
      _isSending = true;
    });
    try {
      final recordedPath = await _recorder.stop();
      Uint8List bytes;
      if (kIsWeb) {
        if (recordedPath == null) {
          throw StateError('The voice note could not be saved.');
        }
        bytes = await XFile(recordedPath).readAsBytes();
      } else {
        await _recordingClosed?.future;
        bytes = _recordingBuffer?.takeBytes() ?? Uint8List(0);
      }
      if (bytes.isEmpty) {
        throw StateError('The voice note was empty.');
      }
      const isWeb = kIsWeb;
      final path = await ref.read(chatServiceProvider).uploadChatMedia(
            bytes: bytes,
            threadId: widget.threadId,
            userId: userId,
            extension: isWeb ? 'webm' : 'm4a',
            contentType: isWeb ? 'audio/webm' : 'audio/mp4',
          );
      final sent = await _sendPayload(
        senderId: userId,
        threadId: widget.threadId,
        mediaType: 'audio',
        mediaUrl: path,
        replyTo: _replyTo?.id,
      );
      if (sent && mounted) setState(() => _replyTo = null);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send voice note: $error')),
        );
      }
    } finally {
      _recordingBuffer = null;
      _recordingClosed = null;
      await _recordingSubscription?.cancel();
      _recordingSubscription = null;
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _forwardMessage(MessageModel message, String? userId) async {
    if (userId == null) return;
    try {
      final threads =
          await ref.read(chatServiceProvider).getThreadsForUser(userId);
      final targets = threads.where((thread) => thread.id != widget.threadId);
      if (!mounted) return;
      final target = await showDialog<ChatThreadModel>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Forward to conversation'),
          content: SizedBox(
            width: 380,
            child: targets.isEmpty
                ? const Text('No other conversations are available.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final thread in targets)
                        ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            thread.buyerNeedId == null
                                ? 'Listing #${thread.listingId}'
                                : 'Buyer demand #${thread.buyerNeedId}',
                          ),
                          onTap: () => Navigator.pop(dialogContext, thread),
                        ),
                    ],
                  ),
          ),
        ),
      );
      if (target == null || !mounted) return;

      var mediaUrl = message.mediaUrl;
      if (mediaUrl != null &&
          mediaUrl.isNotEmpty &&
          !mediaUrl.startsWith('http://') &&
          !mediaUrl.startsWith('https://')) {
        final service = ref.read(chatServiceProvider);
        final bytes = await service.downloadChatMedia(mediaUrl);
        mediaUrl = await service.uploadChatMedia(
          bytes: bytes,
          threadId: target.id,
          userId: userId,
          extension: _extensionOf(mediaUrl, fallback: 'bin'),
          contentType: _mediaContentType(message.mediaType, mediaUrl),
        );
      }
      final sent = await _sendPayload(
        senderId: userId,
        threadId: target.id,
        mediaType: message.mediaType,
        content: message.content,
        mediaUrl: mediaUrl,
        forwardedFrom: message.id,
      );
      if (sent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message forwarded.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not forward message: $error')),
        );
      }
    }
  }

  String _extensionOf(String name, {required String fallback}) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return fallback;
    return name.substring(dot + 1).toLowerCase();
  }

  String _imageContentType(String extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' || 'heif' => 'image/heic',
        _ => 'image/jpeg',
      };

  String _videoContentType(String extension) => switch (extension) {
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        _ => 'video/mp4',
      };

  String _mediaContentType(String type, String path) {
    final extension = _extensionOf(path, fallback: '');
    return switch (type) {
      'image' => _imageContentType(extension),
      'video' => _videoContentType(extension),
      'audio' => switch (extension) {
          'mp3' => 'audio/mpeg',
          'webm' => 'audio/webm',
          'aac' => 'audio/aac',
          _ => 'audio/mp4',
        },
      _ => 'application/octet-stream',
    };
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.replyToMessage,
    required this.isMine,
    required this.onReply,
    required this.onForward,
  });

  final MessageModel message;
  final MessageModel? replyToMessage;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final content = message.isDeleted
        ? 'This message was deleted'
        : message.content ??
            switch (message.mediaType) {
              'image' => 'Photo',
              'video' => 'Video',
              'audio' => 'Voice note',
              _ => '',
            };
    final time = message.createdAt == null
        ? ''
        : TimeOfDay.fromDateTime(message.createdAt!.toLocal()).format(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => showModalBottomSheet<void>(
          context: context,
          builder: (sheetContext) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onReply();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.forward),
                  title: const Text('Forward'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onForward();
                  },
                ),
              ],
            ),
          ),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: AppShadow.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.forwardedFrom != null)
                _BubbleLabel(
                  text: 'Forwarded',
                  color: isMine ? Colors.white70 : AppColors.textSecondary,
                ),
              if (replyToMessage != null)
                _BubbleReplyQuote(message: replyToMessage!),
              if (!message.isDeleted && message.mediaUrl != null)
                _MessageMedia(
                  path: message.mediaUrl!,
                  type: message.mediaType,
                  isMine: isMine,
                ),
              if (content.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isMine ? Colors.white : AppColors.textPrimary,
                        ),
                  ),
                ),
              if (time.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            isMine ? Colors.white70 : AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.onClose});

  final MessageModel message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final quote = message.content ??
        switch (message.mediaType) {
          'image' => 'Photo',
          'video' => 'Video',
          'audio' => 'Voice note',
          _ => 'Message',
        };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Replying to: $quote',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _BubbleReplyQuote extends StatelessWidget {
  const _BubbleReplyQuote({required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.content ??
            switch (message.mediaType) {
              'image' => 'Photo',
              'video' => 'Video',
              'audio' => 'Voice note',
              _ => 'Message',
            },
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _BubbleLabel extends StatelessWidget {
  const _BubbleLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.forward, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
}

class _MessageMedia extends StatefulWidget {
  const _MessageMedia({
    required this.path,
    required this.type,
    required this.isMine,
  });

  final String path;
  final String type;
  final bool isMine;

  @override
  State<_MessageMedia> createState() => _MessageMediaState();
}

class _MessageMediaState extends State<_MessageMedia> {
  late Future<String> _url;

  @override
  void initState() {
    super.initState();
    _url = ChatService().createSignedChatMediaUrl(widget.path);
  }

  @override
  void didUpdateWidget(covariant _MessageMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _url = ChatService().createSignedChatMediaUrl(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _MediaPlaceholder(
            icon: Icons.broken_image_outlined,
            label: 'Could not load attachment',
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 220,
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return switch (widget.type) {
          'image' => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  snapshot.data!,
                  width: 240,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _MediaPlaceholder(
                    icon: Icons.broken_image_outlined,
                    label: 'Image unavailable',
                  ),
                ),
              ),
            ),
          'video' => _VideoNote(url: snapshot.data!),
          'audio' => _AudioNote(url: snapshot.data!, isMine: widget.isMine),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: AppSpacing.sm),
            Text(label),
          ],
        ),
      );
}

class _AudioNote extends StatefulWidget {
  const _AudioNote({required this.url, required this.isMine});

  final String url;
  final bool isMine;

  @override
  State<_AudioNote> createState() => _AudioNoteState();
}

class _AudioNoteState extends State<_AudioNote> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    try {
      await _player.setUrl(widget.url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load voice note.')),
        );
      }
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _isPlaying ? 'Pause voice note' : 'Play voice note',
            onPressed: () async {
              if (_isPlaying) {
                await _player.pause();
              } else {
                await _player.play();
              }
            },
            color: widget.isMine ? Colors.white : AppColors.primary,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          Text(
            'Voice note',
            style: TextStyle(
              color: widget.isMine ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      );
}

class _VideoNote extends StatefulWidget {
  const _VideoNote({required this.url});

  final String url;

  @override
  State<_VideoNote> createState() => _VideoNoteState();
}

class _VideoNoteState extends State<_VideoNote> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialized;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.addListener(_updateVideoState);
    _initialized = _controller.initialize();
  }

  void _updateVideoState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_updateVideoState);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialized,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _MediaPlaceholder(
            icon: Icons.videocam_off_outlined,
            label: 'Could not load video',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 220,
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return SizedBox(
          width: 240,
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                IconButton.filled(
                  onPressed: () => setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  }),
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
