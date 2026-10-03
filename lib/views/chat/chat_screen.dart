import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../models/chat_message.dart';
import '../../providers/sip_provider.dart';
import '../../services/chat_service.dart';
import '../call/active_call_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  StreamSubscription<ChatMessage>? _messageSub;
  List<ChatMessage> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _messageSub = _chatService.onMessage.listen((_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    final list = await _chatService.getRecentConversations();
    if (mounted) {
      setState(() {
        _conversations = list;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _openNewChatDialog(BuildContext context, bool isDark) {
    final textController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('New Message'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Enter SIP extension (e.g. 102)',
            keyboardType: TextInputType.text,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Chat'),
            onPressed: () {
              final ext = textController.text.trim();
              if (ext.isNotEmpty) {
                Navigator.pop(ctx);
                _openThread(ext, ext);
              }
            },
          ),
        ],
      ),
    );
  }

  void _openThread(String extension, String displayName) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ChatThreadScreen(
          remoteExtension: extension,
          displayName: displayName,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_pencil, color: AppColors.brandPrimary),
            tooltip: 'New Message',
            onPressed: () => _openNewChatDialog(context, isDark),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.chat_bubble_2_fill,
                              size: 38,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Messages Yet',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send instant SIP SIMPLE messages to any extension on your PBX server.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _openNewChatDialog(context, isDark),
                            icon: const Icon(CupertinoIcons.plus, size: 18),
                            label: const Text('Start Conversation', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _conversations.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.8,
                      indent: 74,
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    ),
                    itemBuilder: (context, index) {
                      final item = _conversations[index];
                      final timeStr = DateFormat('h:mm a').format(item.timestamp);

                      return Dismissible(
                        key: ValueKey(item.remoteExtension),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.endCallRed,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(CupertinoIcons.trash, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          _chatService.deleteConversation(item.remoteExtension);
                          _loadConversations();
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                            child: Text(
                              item.remoteExtension.isNotEmpty
                                  ? item.remoteExtension.substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.remoteName.isNotEmpty ? item.remoteName : 'Ext ${item.remoteExtension}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.isOutgoing ? 'You: ${item.message}' : item.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          onTap: () => _openThread(
                            item.remoteExtension,
                            item.remoteName.isNotEmpty ? item.remoteName : item.remoteExtension,
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class ChatThreadScreen extends StatefulWidget {
  final String remoteExtension;
  final String displayName;

  const ChatThreadScreen({
    super.key,
    required this.remoteExtension,
    required this.displayName,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ChatMessage>? _streamSub;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _streamSub = _chatService.onMessage.listen((msg) {
      if (msg.remoteExtension == widget.remoteExtension) {
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    final list = await _chatService.getMessagesForContact(widget.remoteExtension);
    if (mounted) {
      setState(() {
        _messages = list;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    Haptics.light();
    _textController.clear();

    final sip = context.read<SipProvider>();
    sip.sendTextMessage(widget.remoteExtension, text);

    _loadMessages();
  }

  void _callContact(bool isVideo) {
    Haptics.medium();
    final sip = context.read<SipProvider>();
    sip.makeCall(widget.remoteExtension, isVideo: isVideo);
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const ActiveCallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
              child: Text(
                widget.remoteExtension.isNotEmpty
                    ? widget.remoteExtension.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Ext ${widget.remoteExtension}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.phone_fill, color: AppColors.brandPrimary, size: 20),
            tooltip: 'Audio Call',
            onPressed: () => _callContact(false),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.video_camera_solid, color: AppColors.brandAccent, size: 22),
            tooltip: 'Video Call',
            onPressed: () => _callContact(true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Send a message to Ext ${widget.remoteExtension}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final time = DateFormat('h:mm a').format(msg.timestamp);

                            return Align(
                              alignment: msg.isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: msg.isOutgoing
                                      ? AppColors.brandPrimary
                                      : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(msg.isOutgoing ? 16 : 4),
                                    bottomRight: Radius.circular(msg.isOutgoing ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      msg.isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.message,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: msg.isOutgoing
                                          ? Colors.white
                                          : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: msg.isOutgoing
                                            ? Colors.white70
                                            : (isDark ? Colors.white54 : Colors.black45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.arrow_up,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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
}
