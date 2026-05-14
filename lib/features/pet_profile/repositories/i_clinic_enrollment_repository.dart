import '../models/clinic_enrollment_model.dart';

abstract class IClinicEnrollmentRepository {
  // Yeni bir kayıt oluşturma
  Future<void> enrollPet(ClinicEnrollment enrollment);

  // Bir hayvanın kayıtlı olduğu tüm klinikleri getirme
  Future<List<ClinicEnrollment>> getEnrollmentsByPetId(String petId);

  // Bir kliniğe kayıtlı tüm hastaları (hayvanları) getirme
  Future<List<ClinicEnrollment>> getEnrollmentsByClinicId(String clinicId);

  // Kliniğin hastanın kaydını silmesi veya hastanın klinikten ayrılması durumu
  Future<void> removeEnrollment(String id);
}
