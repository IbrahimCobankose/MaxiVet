import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/lab_result_model.dart';

/// Laboratuvar sonuçlarını ve arayüzdeki tahlil listesi durumunu (state) yöneten Controller
class LabResultController extends AsyncNotifier<List<LabResult>> {
  @override
  FutureOr<List<LabResult>> build() {
    // Controller ilk ayağa kalktığında boş bir liste döndürüyoruz.
    return [];
  }

  /// Belirli bir hayvana (Pet) ait tüm laboratuvar sonuçlarını getirir ve state'i günceller.
  /// (Hasta sahibi "Laboratuvar" sekmesine girdiğinde tetiklenecek)
  Future<void> fetchLabResultsByPet(String petId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(labResultRepositoryProvider);
      final results = await repository.getLabResultsByPetId(petId);
      state = AsyncValue.data(results);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Kliniğin yeni bir laboratuvar sonucu (PDF veya parametre listesi) eklemesini sağlar.
  Future<void> addLabResult(LabResult labResult) async {
    try {
      final repository = ref.read(labResultRepositoryProvider);
      await repository.addLabResult(labResult);

      // Ekleme başarılı olduktan sonra mevcut listeye yeni sonucu ekliyoruz.
      // (Yeni eklenen sonucun en üstte görünmesi için listenin başına ekleyebiliriz)
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data([labResult, ...currentList]);
      }
    } catch (e) {
      rethrow; // UI'da Snackbar ile hata göstermek için
    }
  }

  /// Mevcut bir tahlil sonucunu (örneğin yanlış girilmiş bir parametreyi) günceller.
  Future<void> updateLabResult(LabResult labResult) async {
    try {
      final repository = ref.read(labResultRepositoryProvider);
      await repository.updateLabResult(labResult);

      // Veritabanı güncellendikten sonra, UI'daki listede ilgili öğeyi bulup güncelliyoruz
      if (state.hasValue) {
        final updatedList = state.value!.map((result) {
          if (result.id == labResult.id) {
            return labResult; // Güncellenmiş nesne ile değiştiriyoruz
          }
          return result;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Hatalı yüklenen bir laboratuvar sonucunu siler.
  Future<void> deleteLabResult(String id) async {
    try {
      final repository = ref.read(labResultRepositoryProvider);
      await repository.deleteLabResult(id);

      // Silinen sonucu mevcut listeden filtreleyerek çıkartıyoruz
      if (state.hasValue) {
        final updatedList = state.value!
            .where((result) => result.id != id)
            .toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve fonksiyonlarına erişmek için Provider
final labResultControllerProvider =
    AsyncNotifierProvider<LabResultController, List<LabResult>>(() {
      return LabResultController();
    });
