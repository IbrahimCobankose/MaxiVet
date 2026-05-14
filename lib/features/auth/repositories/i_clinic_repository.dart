import '../models/clinic_model.dart';

abstract class IClinicRepository {
  Future<void> createClinic(Clinic clinic);
  Future<Clinic?> getClinicById(String id);

  // Hasta sahiplerinin klinikleri koduyla bulabilmesi için özel fonksiyon
  Future<Clinic?> getClinicByCode(String clinicCode);

  Future<void> updateClinic(Clinic clinic);
  Future<void> deleteClinic(String id);
}
