import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lab_result_model.dart';
import 'i_lab_result_repository.dart';

class FirebaseLabResultRepository implements ILabResultRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'lab_results';

  @override
  Future<void> addLabResult(LabResult labResult) async {
    try {
      // Klinik tarafından yeni bir tahlil sonucu yüklendiğinde çalışacak
      await _firestore
          .collection(_collectionName)
          .doc(labResult.id)
          .set(labResult.toJson());
    } catch (e) {
      throw Exception(
        'Laboratuvar sonucu eklenirken bir hata meydana geldi: $e',
      );
    }
  }

  @override
  Future<LabResult?> getLabResultById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        return LabResult.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Laboratuvar sonucu detayı getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<LabResult>> getLabResultsByPetId(String petId) async {
    try {
      // Hasta sahibi "Laboratuvar" sekmesine girdiğinde verileri tarihe göre yeniden eskiye çekiyoruz
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .orderBy('result_date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return LabResult.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(
        'Hastaya ait laboratuvar sonuçları getirilirken hata oluştu: $e',
      );
    }
  }

  @override
  Future<void> updateLabResult(LabResult labResult) async {
    try {
      // Tahlil parametrelerinde veya PDF linkinde bir düzeltme yapılırsa
      await _firestore
          .collection(_collectionName)
          .doc(labResult.id)
          .update(labResult.toJson());
    } catch (e) {
      throw Exception('Laboratuvar sonucu güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteLabResult(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Laboratuvar sonucu silinirken hata oluştu: $e');
    }
  }
}
