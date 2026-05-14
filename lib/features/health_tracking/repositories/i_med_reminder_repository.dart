import '../models/med_reminder_model.dart';

abstract class IMedReminderRepository {
  Future<void> addMedReminder(MedReminder medReminder);
  Future<MedReminder?> getMedReminderById(String id);

  // Hastaya ait tüm ilaç hatırlatıcılarını getiren fonksiyon
  Future<List<MedReminder>> getMedRemindersByPetId(String petId);

  // Sadece aktif (kullanımı devam eden) hatırlatıcıları getiren özel fonksiyon
  Future<List<MedReminder>> getActiveMedRemindersByPetId(String petId);

  Future<void> updateMedReminder(MedReminder medReminder);
  Future<void> deleteMedReminder(String id);
}
