import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/vaccination_model.dart';

/// Aşı kayıtlarını ve arayüzdeki aşı geçmişi durumunu (state) yöneten Controller
class VaccinationController extends AsyncNotifier<List<Vaccination>> {
  @override
  FutureOr<List<Vaccination>> build() {
    // Controller ilk ayağa kalktığında boş bir liste döndürüyoruz.
    return [];
  }

  /// Dijital karne için hastaya ait tüm aşıları geçmişten bugüne getirir.
  Future<void> fetchVaccinationsByPet(String petId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(vaccinationRepositoryProvider);
      final vaccinations = await repository.getVaccinationsByPetId(petId);
      state = AsyncValue.data(vaccinations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Otomatik bildirimler (FR4.1) veya özel hatırlatıcı arayüzleri için
  /// sadece tarihi yaklaşan (gelecekteki) aşıları getirir.
  Future<void> fetchUpcomingVaccinations(String petId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(vaccinationRepositoryProvider);
      final upcomingVaccinations = await repository.getUpcomingVaccinations(
        petId,
      );
      state = AsyncValue.data(upcomingVaccinations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Kliniğin yeni bir aşı kaydı girmesini sağlar ve listeyi günceller.
  Future<void> addVaccination(Vaccination vaccination) async {
    try {
      final repository = ref.read(vaccinationRepositoryProvider);
      await repository.addVaccination(vaccination);

      // Yeni eklenen aşıyı listenin en üstüne (en güncel olarak) yerleştiriyoruz
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data([vaccination, ...currentList]);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mevcut bir aşı kaydını günceller (Örn: Yanlış girilen bir tarihi düzeltmek için).
  Future<void> updateVaccination(Vaccination vaccination) async {
    try {
      final repository = ref.read(vaccinationRepositoryProvider);
      await repository.updateVaccination(vaccination);

      // Arayüzdeki listeyi backend'i beklemeden anında güncelliyoruz
      if (state.hasValue) {
        final updatedList = state.value!.map((v) {
          if (v.id == vaccination.id) {
            return vaccination;
          }
          return v;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Hatalı girilen bir aşı kaydını tamamen siler.
  Future<void> deleteVaccination(String id) async {
    try {
      final repository = ref.read(vaccinationRepositoryProvider);
      await repository.deleteVaccination(id);

      if (state.hasValue) {
        final updatedList = state.value!.where((v) => v.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve fonksiyonlarına erişmek için Provider
final vaccinationControllerProvider =
    AsyncNotifierProvider<VaccinationController, List<Vaccination>>(() {
      return VaccinationController();
    });
