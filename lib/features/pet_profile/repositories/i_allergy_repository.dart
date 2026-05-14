import '../models/allergy_model.dart';

abstract class IAllergyRepository {
  Future<void> addAllergy(Allergy allergy);
  Future<Allergy?> getAllergyById(String id);

  // Hastanın sahip olduğu tüm alerjileri getiren fonksiyon
  Future<List<Allergy>> getAllergiesByPetId(String petId);

  Future<void> updateAllergy(Allergy allergy);
  Future<void> deleteAllergy(String id);
}
