import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clinic_model.dart';
import 'i_clinic_repository.dart';

class FirebaseClinicRepository implements IClinicRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'clinics';

  @override
  Future<void> createClinic(Clinic clinic) async {
    try {
      // Klinik ilk kayıt olduğunda çalışacak
      await _firestore
          .collection(_collectionName)
          .doc(clinic.id)
          .set(clinic.toJson());
    } catch (e) {
      throw Exception(
        'Klinik profili oluşturulurken bir hata meydana geldi: $e',
      );
    }
  }

  @override
  Future<Clinic?> getClinicById(String id) async {
    try {
      // Klinik paneline (Dashboard) giriş yapıldığında verileri getirecek
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return Clinic.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Klinik bilgileri getirilirken bir hata oluştu: $e');
    }
  }

  @override
  Future<Clinic?> getClinicByCode(String clinicCode) async {
    try {
      // Hasta sahibi "Yeni Klinik Ekle" dediğinde kod ile veritabanında arama yapacak sorgu (Query)
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('clinic_code', isEqualTo: clinicCode)
          .limit(1) // Kodlar benzersiz olacağı için sadece 1 sonuç bekliyoruz
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        return Clinic.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null; // Eğer bu koda sahip bir klinik yoksa null döner
    } catch (e) {
      throw Exception('Klinik kodu ile arama yaparken bir hata oluştu: $e');
    }
  }

  @override
  Future<void> updateClinic(Clinic clinic) async {
    try {
      // Kliniğin adres, telefon gibi bilgileri güncellendiğinde
      await _firestore
          .collection(_collectionName)
          .doc(clinic.id)
          .update(clinic.toJson());
    } catch (e) {
      throw Exception('Klinik bilgileri güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteClinic(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Klinik hesabı silinirken bir hata oluştu: $e');
    }
  }
}
