import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';
import 'i_pet_repository.dart';

class FirebasePetRepository implements IPetRepository {
  // Firebase Firestore instance'ını private (_) olarak tanımlıyoruz (Kapsülleme)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Koleksiyon adını bir sabitte tutmak, yazım hatalarını önler
  final String _collectionName = 'pets';

  @override
  Future<void> addPet(Pet pet) async {
    try {
      // Pet modelimizdeki toJson metodunu kullanarak veriyi Firebase'e yazıyoruz.
      // doc(pet.id) diyerek ID'yi Firestore'un kendi oluşturduğu ID yerine bizim verdiğimiz ID yapıyoruz.
      await _firestore
          .collection(_collectionName)
          .doc(pet.id)
          .set(pet.toJson());
    } catch (e) {
      // Gerçek bir projede burada custom bir hata fırlatılır (throw CustomException)
      throw Exception('Hayvan eklenirken bir hata oluştu: $e');
    }
  }

  @override
  Future<Pet?> getPetById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        // factory constructor'ımızı kullanarak JSON'ı Dart nesnesine çeviriyoruz
        return Pet.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null; // Eğer böyle bir hayvan yoksa null döner
    } catch (e) {
      throw Exception('Hayvan getirilirken bir hata oluştu: $e');
    }
  }

  @override
  Future<List<Pet>> getPetsByOwnerId(String ownerId) async {
    try {
      // Firebase'de "owner_id" alanına göre filtreleme (Query) yapıyoruz
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('owner_id', isEqualTo: ownerId)
          .get();

      // Gelen belgeleri (documents) Pet nesnelerine dönüştürüp bir listeye atıyoruz
      return querySnapshot.docs.map((doc) {
        return Pet.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(
        'Hasta sahibinin hayvanları getirilirken hata oluştu: $e',
      );
    }
  }

  @override
  Future<void> updatePet(Pet pet) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(pet.id)
          .update(pet.toJson());
    } catch (e) {
      throw Exception('Hayvan güncellenirken bir hata oluştu: $e');
    }
  }

  @override
  Future<void> deletePet(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Hayvan silinirken bir hata oluştu: $e');
    }
  }
}
