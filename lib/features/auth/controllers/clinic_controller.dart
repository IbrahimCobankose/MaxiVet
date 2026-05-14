import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mevcut mimarine göre ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/clinic_model.dart';

/// Kliniğin kendi oturumunu ve profil durumunu (state) yöneten Controller.
/// State olarak giriş yapmış olan [Clinic] nesnesini (veya null) tutar.
class ClinicController extends AsyncNotifier<Clinic?> {
  @override
  FutureOr<Clinic?> build() {
    // Uygulama ilk açıldığında henüz giriş yapmış bir klinik olmadığı için null döndürüyoruz.
    // Auth mekanizmasından dönen kullanıcı ID'sine göre fetchClinicById tetiklenecek.
    return null;
  }

  /// ID'si verilen kliniğin bilgilerini getirir ve state'i (arayüzü) günceller.
  /// (Kliniğin kendi profiline başarıyla giriş yaptığı senaryo)
  Future<void> fetchClinicById(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(clinicRepositoryProvider);
      final clinic = await repository.getClinicById(id);
      state = AsyncValue.data(clinic);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Yeni bir klinik profili oluşturur ve başarılı olursa oluşturulan kliniği state'e atar.
  Future<void> createClinic(Clinic clinic) async {
    try {
      final repository = ref.read(clinicRepositoryProvider);
      await repository.createClinic(clinic);

      // Oluşturma işlemi başarılı olduktan sonra state'i anında güncelliyoruz
      state = AsyncValue.data(clinic);
    } catch (e) {
      rethrow;
    }
  }

  /// Klinik profil bilgilerini günceller (adres, telefon vb.) ve arayüze anında yansıtır.
  Future<void> updateClinic(Clinic clinic) async {
    try {
      final repository = ref.read(clinicRepositoryProvider);
      await repository.updateClinic(clinic);

      // Güncelleme başarılıysa, state'i backend'e gidip gelmeyi beklemeden yeni verilerle eziyoruz
      state = AsyncValue.data(clinic);
    } catch (e) {
      rethrow;
    }
  }

  /// Klinik hesabını siler ve state'i temizler.
  Future<void> deleteClinic(String id) async {
    try {
      final repository = ref.read(clinicRepositoryProvider);
      await repository.deleteClinic(id);

      // Silme işlemi başarılıysa hesaptan çıkış yapmış gibi state'i null'a çekiyoruz
      state = const AsyncValue.data(null);
    } catch (e) {
      rethrow;
    }
  }

  /// Hasta sahibinin (Pet Owner) klinik koduyla arama yapması için kullanılır.
  /// DİKKAT: Bu metot ana state'i GÜNCELLEMEZ. Sadece sonucu UI'a döndürür.
  Future<Clinic?> searchClinicByCode(String clinicCode) async {
    try {
      final repository = ref.read(clinicRepositoryProvider);
      return await repository.getClinicByCode(clinicCode);
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve fonksiyonlarına erişmek için Provider
final clinicControllerProvider =
    AsyncNotifierProvider<ClinicController, Clinic?>(() {
      return ClinicController();
    });
