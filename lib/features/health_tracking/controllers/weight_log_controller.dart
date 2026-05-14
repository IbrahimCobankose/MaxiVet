import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/weight_log_model.dart';

/// Hayvanların kilo kayıtlarını, arayüzdeki kilo listesini ve grafik verisini (state) yöneten Controller
class WeightLogController extends AsyncNotifier<List<WeightLog>> {
  @override
  FutureOr<List<WeightLog>> build() {
    // Controller ilk ayağa kalktığında boş bir liste döndürüyoruz.
    return [];
  }

  /// Hayvana ait tüm kilo kayıtlarını (grafik ve liste için) getirir.
  Future<void> fetchWeightLogsByPet(String petId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(weightLogRepositoryProvider);
      // Repository verileri tarihe göre yeniden eskiye (descending) sıralı getiriyor
      final logs = await repository.getWeightLogsByPetId(petId);
      state = AsyncValue.data(logs);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Yeni bir kilo ölçümü ekler ve listeyi anında günceller.
  Future<void> addWeightLog(WeightLog weightLog) async {
    try {
      final repository = ref.read(weightLogRepositoryProvider);
      await repository.addWeightLog(weightLog);

      // Yeni eklenen ölçümü kronolojik olarak listenin en üstüne (en yeni olarak) ekliyoruz
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data([weightLog, ...currentList]);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mevcut bir kilo kaydını günceller (Örn: Hatalı girilen bir değeri düzeltmek için).
  Future<void> updateWeightLog(WeightLog weightLog) async {
    try {
      final repository = ref.read(weightLogRepositoryProvider);
      await repository.updateWeightLog(weightLog);

      // Arayüzdeki listeyi backend'i beklemeden anında güncelliyoruz
      if (state.hasValue) {
        final updatedList = state.value!.map((log) {
          if (log.id == weightLog.id) {
            return weightLog; // Güncellenmiş nesne ile eziyoruz
          }
          return log;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Hatalı bir kilo ölçümünü tamamen siler.
  Future<void> deleteWeightLog(String id) async {
    try {
      final repository = ref.read(weightLogRepositoryProvider);
      await repository.deleteWeightLog(id);

      // Silinen kaydı mevcut listeden çıkarıp UI'ı güncelliyoruz
      if (state.hasValue) {
        final updatedList = state.value!.where((log) => log.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// UI ve Grafik (Chart) tarafında bu controller'ı dinlemek için Provider
final weightLogControllerProvider =
    AsyncNotifierProvider<WeightLogController, List<WeightLog>>(() {
      return WeightLogController();
    });
