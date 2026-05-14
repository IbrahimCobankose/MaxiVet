import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'i_notification_repository.dart';

class FirebaseNotificationRepository implements INotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'notifications';

  @override
  Future<void> addNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(notification.id)
          .set(notification.toJson());
    } catch (e) {
      throw Exception('Bildirim oluşturulurken bir hata meydana geldi: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> getNotificationStreamByRecipientId(
    String recipientId,
  ) {
    // Kullanıcıya ait bildirimleri tarihe göre en yeniden en eskiye doğru anlık olarak dinliyoruz
    return _firestore
        .collection(_collectionName)
        .where('recipient_id', isEqualTo: recipientId)
        .orderBy('scheduled_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromJson(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> markNotificationAsSent(String id) async {
    try {
      // Cloud Functions veya arka plan servisi bildirimi ilettiğinde 'sent' alanını günceller
      await _firestore.collection(_collectionName).doc(id).update({
        'sent': true,
      });
    } catch (e) {
      throw Exception('Bildirim durumu güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Bildirim silinirken hata oluştu: $e');
    }
  }
}
