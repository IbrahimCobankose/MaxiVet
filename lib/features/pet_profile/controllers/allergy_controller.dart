import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/allergy_model.dart';

/// Hastaya ait alerjileri ve arayüzdeki alerji listesi durumunu (state) yöneten Controller
class AllergyController extends AsyncNotifier<List<Allergy>> {
  @override
  FutureOr<List<Allergy>> build() {
    // Controller ilk ayağa kalktığında boş bir liste döndürüyoruz.
    return [];
  }

  /// Hayvana ait tüm alerjileri getirir ve state'i günceller.
  Future<void> fetchAllergiesByPet(String petId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(allergyRepositoryProvider);
      final allergies = await repository.getAllergiesByPetId(petId);
      state = AsyncValue.data(allergies);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Klinik veya hasta sahibi tarafından yeni bir alerji kaydı girilmesini sağlar.
  Future<void> addAllergy(Allergy allergy) async {
    try {
      final repository = ref.read(allergyRepositoryProvider);
      await repository.addAllergy(allergy);

      // Yeni eklenen alerjiyi mevcut listeye ekliyoruz
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data([...currentList, allergy]);
      }
    } catch (e) {
      rethrow; // UI'da Snackbar vb. ile hata göstermek için
    }
  }

  /// Mevcut bir alerji kaydını günceller (Örn: Şiddeti 'Orta'dan 'Kritik' seviyesine çıktığında).
  Future<void> updateAllergy(Allergy allergy) async {
    try {
      final repository = ref.read(allergyRepositoryProvider);
      await repository.updateAllergy(allergy);

      // Arayüzdeki listeyi backend'i beklemeden anında güncelliyoruz
      if (state.hasValue) {
        final updatedList = state.value!.map((a) {
          if (a.id == allergy.id) {
            return allergy;
          }
          return a;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Hatalı girilen veya geçerliliğini yitiren bir alerji kaydını siler.
  Future<void> deleteAllergy(String id) async {
    try {
      final repository = ref.read(allergyRepositoryProvider);
      await repository.deleteAllergy(id);

      // Silinen kaydı mevcut listeden filtreleyip UI'ı güncelliyoruz
      if (state.hasValue) {
        final updatedList = state.value!.where((a) => a.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve fonksiyonlarına erişmek için Provider
final allergyControllerProvider =
    AsyncNotifierProvider<AllergyController, List<Allergy>>(() {
      return AllergyController();
    });
