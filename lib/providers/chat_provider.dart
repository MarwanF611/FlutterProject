import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _fs;

  StreamSubscription? _chatListSub;
  final Map<String, StreamSubscription> _chatMsgSubs = {};
  final Map<String, String> _lastKnownMsgId = {};

  ChatProvider(this._fs);

  Stream<List<Chat>> userChats(String uid) => _fs.getUserChats(uid);

  Stream<List<ChatMessage>> chatMessages(String chatId) =>
      _fs.getChatMessages(chatId);

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final msg = ChatMessage(
      id: '',
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    await _fs.sendMessage(chatId, msg);
  }

  Future<String> getOrCreateChat({
    required String tenantUid,
    required String ownerUid,
    required String tenantName,
    required String ownerName,
    required String deviceId,
    required String deviceTitle,
  }) {
    return _fs.getOrCreateChat(
      tenantUid: tenantUid,
      ownerUid: ownerUid,
      tenantName: tenantName,
      ownerName: ownerName,
      deviceId: deviceId,
      deviceTitle: deviceTitle,
    );
  }

  /// Start listening to all chats for the user and show a local notification
  /// when a new message arrives from someone else.
  void startMessageListener(String currentUserId) {
    stopMessageListener();

    _chatListSub = _fs.getUserChats(currentUserId).listen((chats) {
      final chatIds = chats.map((c) => c.id).toSet();

      // Cancel subscriptions for chats that are no longer in the list
      _chatMsgSubs.keys
          .where((id) => !chatIds.contains(id))
          .toList()
          .forEach((id) {
        _chatMsgSubs.remove(id)?.cancel();
        _lastKnownMsgId.remove(id);
      });

      for (final chat in chats) {
        if (_chatMsgSubs.containsKey(chat.id)) continue;

        bool firstEmission = true;

        _chatMsgSubs[chat.id] =
            _fs.getChatMessages(chat.id).listen((messages) {
          // First emission: record current latest message, no notification
          if (firstEmission) {
            if (messages.isNotEmpty) {
              _lastKnownMsgId[chat.id] = messages.first.id;
            }
            firstEmission = false;
            return;
          }

          if (messages.isEmpty) return;

          final latest = messages.first;
          final alreadySeen = _lastKnownMsgId[chat.id] == latest.id;

          if (!alreadySeen && latest.senderId != currentUserId) {
            _lastKnownMsgId[chat.id] = latest.id;
            final sender =
                chat.participantNames[latest.senderId] ?? 'Onbekend';
            NotificationService.showMessageNotification(
              id: chat.id.hashCode,
              senderName: sender,
              messageText: latest.text,
            );
          }
        });
      }
    });
  }

  void stopMessageListener() {
    _chatListSub?.cancel();
    _chatListSub = null;
    for (final sub in _chatMsgSubs.values) {
      sub.cancel();
    }
    _chatMsgSubs.clear();
    _lastKnownMsgId.clear();
  }

  @override
  void dispose() {
    stopMessageListener();
    super.dispose();
  }
}
