import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _fs;

  ChatProvider(this._fs);

  Stream<List<Chat>> userChats(String uid) {
    return _fs.getUserChats(uid);
  }

  Stream<List<ChatMessage>> chatMessages(String chatId) {
    return _fs.getChatMessages(chatId);
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final msg = ChatMessage(
      id: '',
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    await _fs.sendMessage(chatId, msg);
  }
}
