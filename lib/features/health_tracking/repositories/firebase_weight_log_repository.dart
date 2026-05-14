import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weight_log_model.dart';
import 'i_weight_log_repository.dart';

class FirebaseWeightLogRepository implements IWeightLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'weight_logs';

  @override
  Future<void> addWeightLog(WeightLog weightLog) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(weightLog.id)
          .set(weightLog.toJson());
    } catch (e) {
      throw Exception('Kilo kaydı eklenirken bir hata meydana geldi: $e');
    }
  }

  @override
  Future<List<WeightLog>> getWeightLogsByPetId(String petId) async {
    try {
      // Grafik ve liste çizimleri için verileri tarihe göre en yeniden en eskiye doğru (descending) sıralı çekiyoruz.
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .orderBy('measured_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return WeightLog.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Hastaya ait kilo geçmişi getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateWeightLog(WeightLog weightLog) async {
    try {
      // Yanlış girilen bir kilo verisi düzeltilmek istendiğinde
      await _firestore
          .collection(_collectionName)
          .doc(weightLog.id)
          .update(weightLog.toJson());
    } catch (e) {
      throw Exception('Kilo kaydı güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteWeightLog(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Kilo kaydı silinirken hata oluştu: $e');
    }
  }
}
