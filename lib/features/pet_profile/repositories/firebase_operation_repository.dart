import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/operation_model.dart';
import 'i_operation_repository.dart';

class FirebaseOperationRepository implements IOperationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'operations';

  @override
  Future<void> addOperation(Operation operation) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(operation.id)
          .set(operation.toJson());
    } catch (e) {
      throw Exception('Operasyon kaydı eklenirken bir hata meydana geldi: $e');
    }
  }

  @override
  Future<Operation?> getOperationById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        return Operation.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Operasyon detayı getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<Operation>> getOperationsByPetId(String petId) async {
    try {
      // Dijital karne için operasyonları tarihe göre yeniden eskiye doğru (descending) çekiyoruz.
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .orderBy('operated_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Operation.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(
        'Hastaya ait operasyon geçmişi getirilirken hata oluştu: $e',
      );
    }
  }

  @override
  Future<List<Operation>> getOperationsByClinicId(String clinicId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('clinic_id', isEqualTo: clinicId)
          .orderBy('operated_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Operation.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(
        'Kliniğe ait operasyon kayıtları getirilirken hata oluştu: $e',
      );
    }
  }

  @override
  Future<void> updateOperation(Operation operation) async {
    try {
      // Hekim operasyon raporunda veya notlarında güncelleme yaptığında
      await _firestore
          .collection(_collectionName)
          .doc(operation.id)
          .update(operation.toJson());
    } catch (e) {
      throw Exception('Operasyon kaydı güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteOperation(String id) async {
    try {
      // Hatalı girilen bir operasyon kaydını silmek için
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Operasyon kaydı silinirken hata oluştu: $e');
    }
  }
}
