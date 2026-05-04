import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _fs;

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
}
