import '../models/appointment_model.dart';

abstract class IAppointmentRepository {
  Future<void> createAppointment(Appointment appointment);

  // Eksik olan getAppointmentById metodunu garantiye alıyoruz
  Future<Appointment?> getAppointmentById(String id);

  // Kliniğe ait randevular
  Future<List<Appointment>> getAppointmentsByClinicId(
    String clinicId, {
    DateTime? date,
  });

  // YENİ: Müşterinin TÜM hayvanlarına ait randevuları getiren fonksiyon
  Future<List<Appointment>> getAppointmentsByPetIds(List<String> petIds);

  Future<void> updateAppointmentStatus(String id, String status);
  Future<void> deleteAppointment(String id);
}
