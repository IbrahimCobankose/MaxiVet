import '../models/pet_model.dart';

// Veri katmanı ile UI arasındaki sözleşmemiz (Interface)
abstract class IPetRepository {
  Future<void> addPet(Pet pet);
  Future<Pet?> getPetById(String id);
  Future<List<Pet>> getPetsByOwnerId(String ownerId);
  Future<void> updatePet(Pet pet);
  Future<void> deletePet(String id);
}
