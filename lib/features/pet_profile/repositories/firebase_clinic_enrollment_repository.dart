import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clinic_enrollment_model.dart';
import 'i_clinic_enrollment_repository.dart';

class FirebaseClinicEnrollmentRepository
    implements IClinicEnrollmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'clinic_enrollments';

  @override
  Future<void> enrollPet(ClinicEnrollment enrollment) async {
    try {
      // 1. ÖN KONTROL: Bu hayvan (pet_id) bu kliniğe (clinic_id) daha önce eklenmiş mi?
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: enrollment.petId)
          .where('clinic_id', isEqualTo: enrollment.clinicId)
          .get();

      // 2. KONTROL SONUCU: Eğer sorgu boş dönmediyse (yani kayıt varsa) işlemi durdur ve hata fırlat
      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('Bu dostunuz zaten bu kliniğe kayıtlı!');
      }

      // 3. KAYIT İŞLEMİ: Eğer eşleşme yoksa, yeni kaydı güvenle veritabanına ekle
      await _firestore
          .collection(_collectionName)
          .doc(enrollment.id)
          .set(enrollment.toJson());
    } catch (e) {
      // Yukarıda fırlattığımız özel hata mesajını bozmadan doğrudan UI'a iletiyoruz
      if (e.toString().contains('zaten bu kliniğe kayıtlı')) {
        rethrow;
      }
      throw Exception(
        'Kliniğe kayıt oluşturulurken bir hata meydana geldi: $e',
      );
    }
  }

  @override
  Future<List<ClinicEnrollment>> getEnrollmentsByPetId(String petId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', isEqualTo: petId)
          .get();

      return querySnapshot.docs.map((doc) {
        return ClinicEnrollment.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception(
        'Hayvanın kayıtlı olduğu klinikler getirilirken hata oluştu: $e',
      );
    }
  }

  @override
  Future<List<ClinicEnrollment>> getEnrollmentsByClinicId(
    String clinicId,
  ) async {
    try {
      // Kliniğin panelinde "Kayıtlı Hastalarım" listesini oluşturmak için kullanılacak sorgu
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('clinic_id', isEqualTo: clinicId)
          .orderBy(
            'enrolled_at',
            descending: true,
          ) // En son kayıt olanlar en üstte
          .get();

      return querySnapshot.docs.map((doc) {
        return ClinicEnrollment.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Kliniğe kayıtlı hastalar getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<void> removeEnrollment(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Klinik kaydı silinirken hata oluştu: $e');
    }
  }
}
