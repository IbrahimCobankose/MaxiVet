class Message {
  final String id;
  final String senderId; // Mesajı gönderenin ID'si (Klinik veya PetOwner)
  final String senderType; // Gönderen Tipi (Örn: 'clinic' veya 'pet_owner')
  final String receiverId; // Mesajı alanın ID'si
  final String receiverType; // Alıcı Tipi
  final String petId; // Hangi hayvan hakkında konuşulduğu (Foreign Key)
  final String content; // Mesaj metni
  final DateTime sentAt; // Gönderilme zamanı
  final bool isRead; // Okundu bilgisi

  Message({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.receiverId,
    required this.receiverType,
    required this.petId,
    required this.content,
    required this.sentAt,
    required this.isRead,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory Message.fromJson(Map<String, dynamic> json, String documentId) {
    return Message(
      id: documentId,
      senderId: json['sender_id'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? '',
      receiverId: json['receiver_id'] as String? ?? '',
      receiverType: json['receiver_type'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      content: json['content'] as String? ?? '',

      // Firebase Timestamp nesnesini Dart DateTime'a çeviriyoruz
      sentAt: json['sent_at'] != null
          ? (json['sent_at'] as dynamic).toDate()
          : DateTime.now(),

      isRead: json['is_read'] as bool? ?? false,
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'sender_type': senderType,
      'receiver_id': receiverId,
      'receiver_type': receiverType,
      'pet_id': petId,
      'content': content,
      'sent_at': sentAt,
      'is_read': isRead,
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  Message copyWith({
    String? id,
    String? senderId,
    String? senderType,
    String? receiverId,
    String? receiverType,
    String? petId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      receiverId: receiverId ?? this.receiverId,
      receiverType: receiverType ?? this.receiverType,
      petId: petId ?? this.petId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
