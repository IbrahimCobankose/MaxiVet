import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/examination_model.dart';

/// Hastaya ait muayene kayıtlarını ve arayüzdeki muayene geçmişi durumunu (state) yöneten Controller
class ExaminationController extends AsyncNotifier<List<Examination>> {
  @override
  FutureOr<List<Examination>> build() {
    // Controller ilk ayağa kalktığında boş bir liste döndürüyoruz.
    return [];
  }

  /// Hasta sahibinin dijital karnesinde hastanın geçmiş muayenelerini listelemek için kullanılır.
  Future<void> fetchExaminationsByPet(String petId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(examinationRepositoryProvider);
      final examinations = await repository.getExaminationsByPetId(petId);
      state = AsyncValue.data(examinations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Kliniğin panelinde kliniğe ait tüm muayene geçmişini (raporlama/takip için) listelemek için kullanılır.
  Future<void> fetchExaminationsByClinic(String clinicId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(examinationRepositoryProvider);
      final examinations = await repository.getExaminationsByClinicId(clinicId);
      state = AsyncValue.data(examinations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Hekim tarafından yeni bir muayene kaydı oluşturulduğunda çalışır ve listeyi günceller.
  Future<void> addExamination(Examination examination) async {
    try {
      final repository = ref.read(examinationRepositoryProvider);
      await repository.addExamination(examination);

      // Yeni eklenen muayeneyi kronolojik olarak listenin en üstüne ekliyoruz
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data([examination, ...currentList]);
      }
    } catch (e) {
      rethrow; // UI katmanında Snackbar ile hata mesajı göstermek için hatayı iletiyoruz
    }
  }

  /// Mevcut bir muayene kaydı (Örn: Hekim sonradan tedavi notu eklediğinde) güncellendiğinde çalışır.
  Future<void> updateExamination(Examination examination) async {
    try {
      final repository = ref.read(examinationRepositoryProvider);
      await repository.updateExamination(examination);

      // Arayüzdeki listeyi backend'i beklemeden anında güncelliyoruz
      if (state.hasValue) {
        final updatedList = state.value!.map((exam) {
          if (exam.id == examination.id) {
            return examination; // Güncellenmiş veri ile değiştiriyoruz
          }
          return exam;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Hatalı girilmiş bir muayene kaydını tamamen siler.
  Future<void> deleteExamination(String id) async {
    try {
      final repository = ref.read(examinationRepositoryProvider);
      await repository.deleteExamination(id);

      // Silinen muayeneyi state listesinden anlık olarak çıkartıyoruz
      if (state.hasValue) {
        final updatedList = state.value!
            .where((exam) => exam.id != id)
            .toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve fonksiyonlarına erişmek için Provider
final examinationControllerProvider =
    AsyncNotifierProvider<ExaminationController, List<Examination>>(() {
      return ExaminationController();
    });
