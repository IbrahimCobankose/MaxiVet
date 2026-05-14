import '../models/pet_owner_model.dart';

// UI ve Auth katmanının Firestore ile haberleşeceği kuralları belirliyoruz
abstract class IPetOwnerRepository {
  Future<void> createPetOwner(PetOwner petOwner);
  Future<PetOwner?> getPetOwnerById(String id);
  Future<void> updatePetOwner(PetOwner petOwner);
  Future<void> deletePetOwner(String id);
}
