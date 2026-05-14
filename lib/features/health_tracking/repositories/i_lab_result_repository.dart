import '../models/lab_result_model.dart';

abstract class ILabResultRepository {
  Future<void> addLabResult(LabResult labResult);
  Future<LabResult?> getLabResultById(String id);

  // Hasta sahibinin arayüzünde tüm laboratuvar sonuçlarını listelemek için kullanılacak
  Future<List<LabResult>> getLabResultsByPetId(String petId);

  Future<void> updateLabResult(LabResult labResult);
  Future<void> deleteLabResult(String id);
}
