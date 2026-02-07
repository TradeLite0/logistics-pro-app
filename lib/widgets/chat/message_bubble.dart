import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../utils/app_helpers.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final bool isSupport;

  const MessageBubble({
    Key? key,
    required this.message,
    this.showAvatar = true,
    this.isSupport = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.sender?.name == 'أنت' || message.isRead;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          if (!isMe && !showAvatar) const SizedBox(width: 44),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : isSupport
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && showAvatar && message.sender != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender!.name,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSupport ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppHelpers.formatTime(message.createdAt),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.blue : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(isMe: true),
          ],
          if (isMe && !showAvatar) const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAvatar({bool isMe = false}) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: message.sender?.avatar != null && !isMe
          ? NetworkImage(message.sender!.avatar!)
          : null,
      backgroundColor: isSupport && !isMe ? Colors.green : Colors.grey[300],
      child: isSupport && !isMe
          ? const Icon(Icons.support_agent, size: 16, color: Colors.white)
          : message.sender?.avatar == null || isMe
              ? Icon(
                  isMe ? Icons.person : Icons.person_outline,
                  size: 18,
                  color: Colors.grey[600],
                )
              : null,
    );
  }
}
