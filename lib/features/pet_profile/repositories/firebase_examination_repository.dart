import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/examination_model.dart';
import 'i_examination_repository.dart';

class FirebaseExaminationRepository implements IExaminationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'examinations';

  @override
  Future<void> addExamination(Examination examination) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(examination.id)
          .set(examination.toJson());
    } catch (e) {
      throw Exception('Muayene kaydı eklenirken bir hata meydana geldi: $e');
    }
  }

  @override
  Future<Examination?> getExaminationById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        return Examination.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Muayene detayı getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<Examination>> getExaminationsByPetId(String petId) async {
    try {
      // Dijital karne ekranı için verileri tarihe göre yeniden eskiye doğru (descending) çekiyoruz.
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .orderBy('examined_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Examination.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(
        'Hastaya ait muayene geçmişi getirilirken hata oluştu: $e',
      );
    }
  }

  @override
  Future<List<Examination>> getExaminationsByClinicId(String clinicId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('clinic_id', isEqualTo: clinicId)
          .orderBy('examined_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Examination.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Kliniğe ait muayeneler getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateExamination(Examination examination) async {
    try {
      // Hekim teşhis veya tedavi planında bir güncelleme yaptığında
      await _firestore
          .collection(_collectionName)
          .doc(examination.id)
          .update(examination.toJson());
    } catch (e) {
      throw Exception('Muayene kaydı güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteExamination(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Muayene kaydı silinirken hata oluştu: $e');
    }
  }
}
