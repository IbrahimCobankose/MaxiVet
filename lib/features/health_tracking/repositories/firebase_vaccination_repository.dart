import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vaccination_model.dart';
import 'i_vaccination_repository.dart';

class FirebaseVaccinationRepository implements IVaccinationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'vaccinations';

  @override
  Future<void> addVaccination(Vaccination vaccination) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(vaccination.id)
          .set(vaccination.toJson());
    } catch (e) {
      throw Exception('Aşı kaydı eklenirken bir hata meydana geldi: $e');
    }
  }

  @override
  Future<Vaccination?> getVaccinationById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        return Vaccination.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Aşı detayı getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<Vaccination>> getVaccinationsByPetId(String petId) async {
    try {
      // Dijital karne zaman çizelgesi (Timeline) için aşıları en yeniden en eskiye doğru çekiyoruz
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .orderBy('applied_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Vaccination.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Hastaya ait aşı geçmişi getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<Vaccination>> getUpcomingVaccinations(String petId) async {
    try {
      // Bildirim sistemi için: next_due_date alanı bugünden büyük olan (gelecekteki) aşıları çekiyoruz
      DateTime now = DateTime.now();
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .where('next_due_date', isGreaterThanOrEqualTo: now)
          .orderBy('next_due_date') // En yakın tarihli aşı en üstte gelsin
          .get();

      return querySnapshot.docs.map((doc) {
        return Vaccination.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Yaklaşan aşılar getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateVaccination(Vaccination vaccination) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(vaccination.id)
          .update(vaccination.toJson());
    } catch (e) {
      throw Exception('Aşı kaydı güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteVaccination(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Aşı kaydı silinirken hata oluştu: $e');
    }
  }
}
