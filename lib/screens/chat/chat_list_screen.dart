import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_helpers.dart';
import 'chat_screen.dart';
import 'support_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ChatProvider>().loadChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic),
            tooltip: 'الدعم الفني',
            onPressed: () => _navigateToSupport(context),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.error != null && chatProvider.chats.isEmpty) {
            return _buildErrorWidget(chatProvider.error!);
          }

          if (chatProvider.chats.isEmpty) {
            return _buildEmptyWidget();
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.loadChats(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chatProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];
                return _ChatListItem(
                  chat: chat,
                  onTap: () => _navigateToChat(context, chat),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSupport(context),
        icon: const Icon(Icons.support_agent),
        label: const Text('الدعم الفني'),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد محادثات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ محادثة مع الدعم الفني للمساعدة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToSupport(context),
            icon: const Icon(Icons.support_agent),
            label: const Text('الدعم الفني'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<ChatProvider>().loadChats(),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(BuildContext context, ChatModel chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chat.id),
      ),
    );
  }

  Future<void> _navigateToSupport(BuildContext context) async {
    AppHelpers.showLoadingDialog(context, message: 'جاري الاتصال...');
    try {
      final chatProvider = context.read<ChatProvider>();
      final chat = await chatProvider.createSupportChat();
      if (mounted) {
        AppHelpers.hideLoadingDialog(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SupportChatScreen(chatId: chat.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.hideLoadingDialog(context);
        AppHelpers.showSnackBar(context, 'فشل الاتصال بالدعم: $e', isError: true);
      }
    }
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: chat.otherParticipantAvatar != null
                ? NetworkImage(chat.otherParticipantAvatar!)
                : null,
            child: chat.otherParticipantAvatar == null
                ? Text(
                    chat.chatTitle.isNotEmpty ? chat.chatTitle[0] : '?',
                    style: const TextStyle(fontSize: 20),
                  )
                : null,
          ),
          if (chat.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.chatTitle,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            chat.lastMessage != null
                ? AppHelpers.getRelativeTime(chat.lastMessage!.createdAt)
                : AppHelpers.getRelativeTime(chat.createdAt),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: chat.unreadCount > 0
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
        ],
      ),
      subtitle: Text(
        chat.lastMessage?.content ?? 'لا توجد رسائل',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
          fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: chat.type == 'support'
          ? Icon(
              Icons.support_agent,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.chevron_left, color: Colors.grey),
    );
  }
}
