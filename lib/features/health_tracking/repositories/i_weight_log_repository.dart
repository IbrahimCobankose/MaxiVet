import '../models/weight_log_model.dart';

abstract class IWeightLogRepository {
  Future<void> addWeightLog(WeightLog weightLog);

  // Hayvana ait tüm kilo ölçümlerini tarih sırasına göre getiren fonksiyon
  Future<List<WeightLog>> getWeightLogsByPetId(String petId);

  Future<void> updateWeightLog(WeightLog weightLog);
  Future<void> deleteWeightLog(String id);
}
