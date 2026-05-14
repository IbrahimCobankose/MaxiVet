import '../models/message_model.dart';

abstract class IMessageRepository {
  // Yeni bir mesaj gönderme
  Future<void> sendMessage(Message message);

  // DİKKAT: Gerçek zamanlı sohbet için Future değil, Stream kullanıyoruz!
  // Bu sayede veritabanına yeni mesaj eklendiği an UI otomatik tetiklenecek.
  Stream<List<Message>> getMessageStreamByPetId(String petId);

  // Mesaj görüldüğünde okundu bilgisini (is_read: true) güncellemek için
  Future<void> markMessageAsRead(String messageId);

  // Gerekirse mesajı silmek için
  Future<void> deleteMessage(String id);
  Stream<List<Message>> getClinicInboxStream(String clinicId);
  Stream<List<Message>> getPetOwnerInboxStream(String ownerId);
}
