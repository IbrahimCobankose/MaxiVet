import '../models/examination_model.dart';

abstract class IExaminationRepository {
  Future<void> addExamination(Examination examination);
  Future<Examination?> getExaminationById(String id);

  // Dijital karne için hastanın tüm muayene geçmişini getiren fonksiyon
  Future<List<Examination>> getExaminationsByPetId(String petId);

  // Kliniğin yaptığı tüm muayeneleri getiren fonksiyon (Raporlama için faydalı olabilir)
  Future<List<Examination>> getExaminationsByClinicId(String clinicId);

  Future<void> updateExamination(Examination examination);
  Future<void> deleteExamination(String id);
}
