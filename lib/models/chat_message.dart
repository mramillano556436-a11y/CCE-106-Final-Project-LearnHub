import '../utils/format.dart';

/// A document in `orders/{orderId}/messages`.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String fileUrl;
  final String fileName;
  final bool isImage;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text = '',
    this.fileUrl = '',
    this.fileName = '',
    this.isImage = false,
    this.createdAt,
  });

  bool get hasFile => fileUrl.isNotEmpty;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> d) => ChatMessage(
        id: id,
        senderId: d['senderId'] as String? ?? '',
        senderName: d['senderName'] as String? ?? '',
        text: d['text'] as String? ?? '',
        fileUrl: d['fileUrl'] as String? ?? '',
        fileName: d['fileName'] as String? ?? '',
        isImage: d['isImage'] as bool? ?? false,
        createdAt: toDate(d['createdAt']),
      );
}
