import '../models/vaccination_model.dart';

abstract class IVaccinationRepository {
  Future<void> addVaccination(Vaccination vaccination);
  Future<Vaccination?> getVaccinationById(String id);

  // Dijital karne için hastaya yapılan tüm aşıları geçmişten bugüne getiren fonksiyon
  Future<List<Vaccination>> getVaccinationsByPetId(String petId);

  // Otomatik bildirim sistemi için: Tarihi yaklaşan aşıları getiren özel fonksiyon
  Future<List<Vaccination>> getUpcomingVaccinations(String petId);

  Future<void> updateVaccination(Vaccination vaccination);
  Future<void> deleteVaccination(String id);
}
