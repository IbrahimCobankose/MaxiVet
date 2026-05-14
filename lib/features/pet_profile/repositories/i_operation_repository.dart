import '../models/operation_model.dart';

abstract class IOperationRepository {
  Future<void> addOperation(Operation operation);
  Future<Operation?> getOperationById(String id);

  // Dijital karne için hastanın geçirdiği tüm operasyonları getiren fonksiyon
  Future<List<Operation>> getOperationsByPetId(String petId);

  // Kliniğin gerçekleştirdiği tüm operasyonları getiren fonksiyon
  Future<List<Operation>> getOperationsByClinicId(String clinicId);

  Future<void> updateOperation(Operation operation);
  Future<void> deleteOperation(String id);
}
