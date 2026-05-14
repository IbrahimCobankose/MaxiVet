import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/med_reminder_model.dart';
import 'i_med_reminder_repository.dart';

class FirebaseMedReminderRepository implements IMedReminderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'med_reminders';

  @override
  Future<void> addMedReminder(MedReminder medReminder) async {
    try {
      // Hasta sahibi yeni bir ilaç alarmı kurduğunda çalışacak
      await _firestore
          .collection(_collectionName)
          .doc(medReminder.id)
          .set(medReminder.toJson());
    } catch (e) {
      throw Exception(
        'İlaç hatırlatıcısı eklenirken bir hata meydana geldi: $e',
      );
    }
  }

  @override
  Future<MedReminder?> getMedReminderById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        return MedReminder.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('İlaç hatırlatıcı detayı getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<MedReminder>> getMedRemindersByPetId(String petId) async {
    try {
      // Geçmiş tedaviler dahil tüm hatırlatıcıları listelemek için
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .orderBy('start_date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return MedReminder.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(
        'Hastaya ait ilaç hatırlatıcıları getirilirken hata oluştu: $e',
      );
    }
  }

  @override
  Future<List<MedReminder>> getActiveMedRemindersByPetId(String petId) async {
    try {
      // UI tarafında sadece "Şu an aktif olan" alarmları göstermek ve cihazda kurmak için
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .where('active', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return MedReminder.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(
        'Aktif ilaç hatırlatıcıları getirilirken hata oluştu: $e',
      );
    }
  }

  @override
  Future<void> updateMedReminder(MedReminder medReminder) async {
    try {
      // Hasta sahibi alarmın saatini değiştirdiğinde veya ilacı bırakıp 'active' değerini false yaptığında
      await _firestore
          .collection(_collectionName)
          .doc(medReminder.id)
          .update(medReminder.toJson());
    } catch (e) {
      throw Exception('İlaç hatırlatıcısı güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteMedReminder(String id) async {
    try {
      // Alarm tamamen silinmek istendiğinde
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('İlaç hatırlatıcısı silinirken hata oluştu: $e');
    }
  }
}
