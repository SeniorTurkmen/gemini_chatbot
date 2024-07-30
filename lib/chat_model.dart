import 'dart:typed_data';

class ChatModel {
  final String name;
  final String message;
  final String time;
  final bool isUser;
  final Uint8List? image;
  final String? mineType;

  ChatModel({
    required this.name,
    required this.message,
    required this.time,
    this.isUser = false,
    this.image,
    this.mineType,
  });
}
