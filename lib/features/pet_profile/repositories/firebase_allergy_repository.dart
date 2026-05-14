import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/allergy_model.dart';
import 'i_allergy_repository.dart';

class FirebaseAllergyRepository implements IAllergyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'allergies';

  @override
  Future<void> addAllergy(Allergy allergy) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(allergy.id)
          .set(allergy.toJson());
    } catch (e) {
      throw Exception('Alerji kaydı eklenirken bir hata meydana geldi: $e');
    }
  }

  @override
  Future<Allergy?> getAllergyById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        return Allergy.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Alerji detayı getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<Allergy>> getAllergiesByPetId(String petId) async {
    try {
      // Alerjileri pet_id'ye göre filtreliyoruz.
      // Not: Alerjilerde kronolojik bir sıradan ziyade risk teşkil eden bir liste olduğu için
      // ekstra bir tarih sıralamasına (orderBy) ihtiyaç duymuyoruz, alfabetik veya eklenme sırasına göre gelebilir.
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .get();

      return querySnapshot.docs.map((doc) {
        return Allergy.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Hastaya ait alerjiler getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateAllergy(Allergy allergy) async {
    try {
      // Alerjinin şiddeti (severity) zamanla değişirse güncellenmesi için
      await _firestore
          .collection(_collectionName)
          .doc(allergy.id)
          .update(allergy.toJson());
    } catch (e) {
      throw Exception('Alerji kaydı güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteAllergy(String id) async {
    try {
      // Yanlış konulan bir alerji teşhisini silmek için
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Alerji kaydı silinirken hata oluştu: $e');
    }
  }
}
