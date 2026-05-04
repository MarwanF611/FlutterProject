import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/chat.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  Stream<List<Chat>>? _chatsStream;
  String? _currentUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AuthProvider>().appUser?.uid;
    if (uid != null && uid != _currentUid) {
      _currentUid = uid;
      _chatsStream = context.read<ChatProvider>().userChats(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().appUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Niet ingelogd.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berichten'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Chat>>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Fout: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Je hebt nog geen gesprekken.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherParticipantId = chat.participants.firstWhere(
                  (id) => id != uid,
                  orElse: () => chat.participants.first);
              final otherParticipantName =
                  chat.participantNames[otherParticipantId] ?? 'Onbekend';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    otherParticipantName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  otherParticipantName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toestel: ${chat.deviceTitle}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      chat.lastMessage.isEmpty
                          ? 'Geen berichten nog'
                          : chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: chat.lastMessage.isEmpty
                            ? AppColors.textLight
                            : AppColors.textDark,
                        fontStyle: chat.lastMessage.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  DateFormat('dd/MM HH:mm').format(chat.updatedAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        chat: chat,
                        currentUserId: uid,
                        otherUserName: otherParticipantName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
