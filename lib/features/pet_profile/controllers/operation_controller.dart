import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/operation_model.dart';

/// Hastaya ait operasyon kayıtlarını ve arayüzdeki operasyon geçmişi durumunu (state) yöneten Controller
class OperationController extends AsyncNotifier<List<Operation>> {
  @override
  FutureOr<List<Operation>> build() {
    // Controller ilk ayağa kalktığında boş bir liste döndürüyoruz.
    return [];
  }

  /// Hasta sahibinin dijital karnesinde hastanın geçmiş operasyonlarını listelemek için kullanılır.
  Future<void> fetchOperationsByPet(String petId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(operationRepositoryProvider);
      final operations = await repository.getOperationsByPetId(petId);
      state = AsyncValue.data(operations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Kliniğin panelinde kliniğe ait tüm operasyon geçmişini (raporlama/takip için) listelemek için kullanılır.
  Future<void> fetchOperationsByClinic(String clinicId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(operationRepositoryProvider);
      final operations = await repository.getOperationsByClinicId(clinicId);
      state = AsyncValue.data(operations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Hekim tarafından yeni bir operasyon kaydı girildiğinde çalışır ve listeyi günceller.
  Future<void> addOperation(Operation operation) async {
    try {
      final repository = ref.read(operationRepositoryProvider);
      await repository.addOperation(operation);

      // Yeni eklenen operasyonu kronolojik olarak listenin en üstüne (en yeni olarak) ekliyoruz
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data([operation, ...currentList]);
      }
    } catch (e) {
      rethrow; // UI katmanında Snackbar ile hata mesajı göstermek için hatayı iletiyoruz
    }
  }

  /// Mevcut bir operasyon kaydı (Örn: Hekim sonradan detaylı bir operasyon notu eklediğinde) güncellendiğinde çalışır.
  Future<void> updateOperation(Operation operation) async {
    try {
      final repository = ref.read(operationRepositoryProvider);
      await repository.updateOperation(operation);

      // Arayüzdeki listeyi backend'i beklemeden anında güncelliyoruz
      if (state.hasValue) {
        final updatedList = state.value!.map((op) {
          if (op.id == operation.id) {
            return operation; // Güncellenmiş veri ile değiştiriyoruz
          }
          return op;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Hatalı girilmiş bir operasyon kaydını tamamen siler.
  Future<void> deleteOperation(String id) async {
    try {
      final repository = ref.read(operationRepositoryProvider);
      await repository.deleteOperation(id);

      // Silinen operasyonu state listesinden anlık olarak çıkartıyoruz
      if (state.hasValue) {
        final updatedList = state.value!.where((op) => op.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve fonksiyonlarına erişmek için Provider
final operationControllerProvider =
    AsyncNotifierProvider<OperationController, List<Operation>>(() {
      return OperationController();
    });
