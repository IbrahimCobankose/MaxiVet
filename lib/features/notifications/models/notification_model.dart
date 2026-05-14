class NotificationModel {
  final String id;
  final String
  recipientId; // Bildirimi alacak kişinin ID'si (Klinik veya PetOwner)
  final String recipientType; // Alıcı Tipi (Örn: 'pet_owner' veya 'clinic')
  final String
  type; // Bildirim Türü (Örn: 'vaccination', 'appointment', 'system')
  final String title; // Bildirim Başlığı (Örn: "Aşı Hatırlatması")
  final String
  content; // Bildirim İçeriği (Örn: "Buddy'nin Karma aşısı yarın.")
  final DateTime scheduledAt; // Bildirimin gönderileceği/gösterüleceği zaman
  final bool sent; // Bildirim başarıyla iletildi mi?

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    required this.type,
    required this.title,
    required this.content,
    required this.scheduledAt,
    required this.sent,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory NotificationModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return NotificationModel(
      id: documentId,
      recipientId: json['recipient_id'] as String? ?? '',
      recipientType: json['recipient_type'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Yeni Bildirim',
      content: json['content'] as String? ?? '',

      // Firebase Timestamp nesnesini Dart DateTime'a çeviriyoruz
      scheduledAt: json['scheduled_at'] != null
          ? (json['scheduled_at'] as dynamic).toDate()
          : DateTime.now(),

      sent: json['sent'] as bool? ?? false,
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'recipient_type': recipientType,
      'type': type,
      'title': title,
      'content': content,
      'scheduled_at': scheduledAt,
      'sent': sent,
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? recipientType,
    String? type,
    String? title,
    String? content,
    DateTime? scheduledAt,
    bool? sent,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sent: sent ?? this.sent,
    );
  }
}
