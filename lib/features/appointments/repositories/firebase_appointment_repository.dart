import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import 'i_appointment_repository.dart';

class FirebaseAppointmentRepository implements IAppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'appointments';

  @override
  Future<void> createAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(appointment.id)
          .set(appointment.toJson());
    } catch (e) {
      throw Exception('Randevu oluşturulurken bir hata meydana geldi: $e');
    }
  }

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        return Appointment.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Randevu detayı getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsByClinicId(
    String clinicId, {
    DateTime? date,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('clinic_id', isEqualTo: clinicId);

      // ÇÖZÜM: Eğer tarih verildiyse (müşteri ekranı), sadece o günü getir.
      // Tarih verilmediyse (klinik ekranı), tüm randevuları getir!
      if (date != null) {
        DateTime startOfDay = DateTime(date.year, date.month, date.day);
        DateTime endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .where('starts_at', isGreaterThanOrEqualTo: startOfDay)
            .where('starts_at', isLessThan: endOfDay);
      }

      query = query.orderBy('starts_at');
      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        return Appointment.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Klinik randevuları getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsByPetIds(List<String> petIds) async {
    try {
      if (petIds.isEmpty) return [];

      final queryIds = petIds
          .take(10)
          .toList(); // Firebase whereIn limiti 10'dur

      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('pet_id', whereIn: queryIds)
          .get();

      final allAppointments = querySnapshot.docs.map((doc) {
        return Appointment.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      allAppointments.sort((a, b) => b.startsAt.compareTo(a.startsAt));
      return allAppointments;
    } catch (e) {
      throw Exception('Hastaya ait randevular getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateAppointmentStatus(String id, String status) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Randevu durumu güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteAppointment(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Randevu silinirken hata oluştu: $e');
    }
  }
}
