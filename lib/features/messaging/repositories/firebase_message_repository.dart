import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'i_message_repository.dart';

class FirebaseMessageRepository implements IMessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'messages';

  @override
  Future<void> sendMessage(Message message) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      throw Exception('Mesaj gönderilirken bir hata meydana geldi: $e');
    }
  }

  @override
  Stream<List<Message>> getMessageStreamByPetId(String petId) {
    return _firestore
        .collection(_collectionName)
        .where('pet_id', isEqualTo: petId)
        // DİKKAT: Çökmeyi (ANR) önlemek için orderBy('sent_at') buradan KALDIRILDI!
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => Message.fromJson(doc.data(), doc.id))
              .toList();

          // ÇÖZÜM: Sıralamayı Firebase yerine doğrudan uygulamanın içinde Dart ile yapıyoruz.
          // Bu sayede Firebase İndeks hatası vermez ve uygulama asla donmaz.
          messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

          return messages;
        });
  }

  @override
  Stream<List<Message>> getClinicInboxStream(String clinicId) {
    return _firestore
        .collection(_collectionName)
        // Sadece Kliniğin gönderdiği veya aldığı mesajları filtrele
        .where(
          Filter.or(
            Filter('sender_id', isEqualTo: clinicId),
            Filter('receiver_id', isEqualTo: clinicId),
          ),
        )
        // DİKKAT: orderBy buradan da KALDIRILDI!
        .snapshots()
        .map((snapshot) {
          final allMessages = snapshot.docs
              .map((doc) => Message.fromJson(doc.data(), doc.id))
              .toList();

          // 1. Dart tarafında tarihe göre en yeniden en eskiye sırala
          allMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

          // 2. Her hasta için sadece EN SON mesajı Inbox'ta göstermek için grupla
          final Map<String, Message> inboxMap = {};
          for (var msg in allMessages) {
            if (!inboxMap.containsKey(msg.petId)) {
              inboxMap[msg.petId] =
                  msg; // Liste zaten sıralı olduğu için ilk gördüğü mesaj en yenisidir
            }
          }
          return inboxMap.values.toList();
        });
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection(_collectionName).doc(messageId).update({
        'is_read': true,
      });
    } catch (e) {
      throw Exception('Mesaj okundu olarak işaretlenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteMessage(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Mesaj silinirken hata oluştu: $e');
    }
  }

  @override
  Stream<List<Message>> getPetOwnerInboxStream(String ownerId) {
    return _firestore
        .collection(_collectionName)
        // Müşterinin gönderdiği veya aldığı tüm mesajları çek
        .where(
          Filter.or(
            Filter('sender_id', isEqualTo: ownerId),
            Filter('receiver_id', isEqualTo: ownerId),
          ),
        )
        .snapshots()
        .map((snapshot) {
          final allMessages = snapshot.docs
              .map((doc) => Message.fromJson(doc.data(), doc.id))
              .toList();
          allMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

          final Map<String, Message> inboxMap = {};
          for (var msg in allMessages) {
            if (!inboxMap.containsKey(msg.petId)) {
              inboxMap[msg.petId] =
                  msg; // Her hayvan için sadece son mesajı sakla
            }
          }
          return inboxMap.values.toList();
        });
  }
}
