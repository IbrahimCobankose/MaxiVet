import '../models/notification_model.dart';

abstract class INotificationRepository {
  // Sistemin veya kliniğin yeni bir bildirim oluşturması
  Future<void> addNotification(NotificationModel notification);

  // Kullanıcının (Klinik veya Hasta Sahibi) bildirimlerini gerçek zamanlı dinleyen fonksiyon
  Stream<List<NotificationModel>> getNotificationStreamByRecipientId(
    String recipientId,
  );

  // Bildirim başarıyla gönderildiğinde (veya kullanıcı okuduğunda) durumu güncellemek için
  Future<void> markNotificationAsSent(String id);

  // Kullanıcının bildirimi silmesi durumu
  Future<void> deleteNotification(String id);
}
