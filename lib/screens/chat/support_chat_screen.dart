import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/chat/message_bubble.dart';
import 'dart:async';

class SupportChatScreen extends StatefulWidget {
  final String chatId;

  const SupportChatScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.loadChatDetails(widget.chatId);
      chatProvider.loadMessages(widget.chatId);
      chatProvider.connectToChat(widget.chatId);
      chatProvider.markMessagesAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    context.read<ChatProvider>().disconnectFromChat();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTyping() {
    if (!_isTyping) {
      _isTyping = true;
      context.read<ChatProvider>().sendTypingStatus(widget.chatId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      context.read<ChatProvider>().sendTypingStatus(widget.chatId, false);
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _isTyping = false;
    context.read<ChatProvider>().sendTypingStatus(widget.chatId, false);

    try {
      await context.read<ChatProvider>().sendMessage(widget.chatId, content);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'فشل إرسال الرسالة', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green,
              child: Icon(Icons.support_agent, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدعم الفني',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'متاح 24/7',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // TODO: Make support call
              AppHelpers.showSnackBar(context, 'جاري الاتصال بالدعم الفني...');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Support Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'فريق الدعم الفني جاهز لمساعدتك في أي استفسار',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'مرحباً بك في الدعم الفني',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'كيف يمكننا مساعدتك اليوم؟',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _QuickReplyChip(
                              label: 'استفسار عن شحنة',
                              onTap: () => _sendQuickReply('عندي استفسار عن شحنة'),
                            ),
                            _QuickReplyChip(
                              label: 'مشكلة في التطبيق',
                              onTap: () => _sendQuickReply('واجهت مشكلة في التطبيق'),
                            ),
                            _QuickReplyChip(
                              label: 'شكوى',
                              onTap: () => _sendQuickReply('أريد تقديم شكوى'),
                            ),
                            _QuickReplyChip(
                              label: 'اقتراح',
                              onTap: () => _sendQuickReply('عندي اقتراح للتحسين'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final showAvatar = index == 0 ||
                        chatProvider.messages[index - 1].senderId != message.senderId;

                    return MessageBubble(
                      message: message,
                      showAvatar: showAvatar,
                      isSupport: true,
                    );
                  },
                );
              },
            ),
          ),

          // Quick Replies (when no messages or recent)
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.messages.isNotEmpty &&
                  chatProvider.messages.last.senderId != 'support') {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickReplyChip(
                          label: 'شكراً',
                          onTap: () => _sendQuickReply('شكراً لكم'),
                        ),
                        const SizedBox(width: 8),
                        _QuickReplyChip(
                          label: 'أفهم',
                          onTap: () => _sendQuickReply('تمام، فهمت'),
                        ),
                        const SizedBox(width: 8),
                        _QuickReplyChip(
                          label: 'أحتاج مساعدة أخرى',
                          onTap: () => _sendQuickReply('أحتاج مساعدة في أمر آخر'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // TODO: Attach files
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك للدعم الفني...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => _onTyping(),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      return FloatingActionButton.small(
                        onPressed: chatProvider.isSending ? null : _sendMessage,
                        backgroundColor: Colors.green,
                        child: chatProvider.isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendQuickReply(String message) {
    _messageController.text = message;
    _sendMessage();
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReplyChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
      ),
      onPressed: onTap,
      backgroundColor: Colors.grey[200],
      side: BorderSide.none,
    );
  }
}
