import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_owner_model.dart';
import 'i_pet_owner_repository.dart';

class FirebasePetOwnerRepository implements IPetOwnerRepository {
  // Veritabanı bağlantımızı kapsüllüyoruz
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Koleksiyon adımız
  final String _collectionName = 'pet_owners';

  @override
  Future<void> createPetOwner(PetOwner petOwner) async {
    try {
      // Yeni bir kullanıcı kayıt olduğunda çalışacak fonksiyon.
      // Firebase Authentication'dan aldığımız UID'yi document ID olarak kullanacağız.
      await _firestore
          .collection(_collectionName)
          .doc(petOwner.id)
          .set(petOwner.toJson());
    } catch (e) {
      throw Exception(
        'Hasta sahibi profili oluşturulurken bir hata meydana geldi: $e',
      );
    }
  }

  @override
  Future<PetOwner?> getPetOwnerById(String id) async {
    try {
      // Kullanıcı sisteme giriş (Login) yaptığında profil verilerini getiren fonksiyon
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return PetOwner.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception(
        'Hasta sahibi bilgileri getirilirken bir hata oluştu: $e',
      );
    }
  }

  @override
  Future<void> updatePetOwner(PetOwner petOwner) async {
    try {
      // Profil sayfasında telefon numarası vb. güncellendiğinde çalışacak
      await _firestore
          .collection(_collectionName)
          .doc(petOwner.id)
          .update(petOwner.toJson());
    } catch (e) {
      throw Exception('Hasta sahibi bilgileri güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deletePetOwner(String id) async {
    try {
      // Hesap silme talebi için
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Hasta sahibi hesabı silinirken bir hata oluştu: $e');
    }
  }
}
