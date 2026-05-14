import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../models/clinic_enrollment_model.dart';
import 'pet_controller.dart';

/// Hasta ve klinik arasındaki kayıt bağlantılarını (state) yöneten Controller
class ClinicEnrollmentController extends AsyncNotifier<List<ClinicEnrollment>> {
  @override
  FutureOr<List<ClinicEnrollment>> build() {
    return [];
  }

  Future<void> fetchEnrollmentsByPet(String petId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(clinicEnrollmentRepositoryProvider);
      final enrollments = await repository.getEnrollmentsByPetId(petId);
      state = AsyncValue.data(enrollments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // ÇÖZÜM: Kliniğin kayıtlı hastalarını bulup RAM'e (petController) atıyoruz
  Future<void> fetchEnrollmentsByClinic(String clinicId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(clinicEnrollmentRepositoryProvider);
      final enrollments = await repository.getEnrollmentsByClinicId(clinicId);

      final petNotifier = ref.read(petControllerProvider.notifier);

      for (var enrollment in enrollments) {
        final currentPets = ref.read(petControllerProvider).value ?? [];
        final isPetAlreadyFetched = currentPets.any(
          (p) => p.id == enrollment.petId,
        );

        // Eğer hayvan zaten RAM'de yoksa, detayını çekip listeye ekle
        if (!isPetAlreadyFetched) {
          await petNotifier.getPetDetails(enrollment.petId);
        }
      }

      state = AsyncValue.data(enrollments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> enrollPet(ClinicEnrollment enrollment) async {
    try {
      final repository = ref.read(clinicEnrollmentRepositoryProvider);
      await repository.enrollPet(enrollment);

      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data([enrollment, ...currentList]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeEnrollment(String id) async {
    try {
      final repository = ref.read(clinicEnrollmentRepositoryProvider);
      await repository.removeEnrollment(id);

      if (state.hasValue) {
        final updatedList = state.value!.where((e) => e.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek için Provider
final clinicEnrollmentControllerProvider =
    AsyncNotifierProvider<ClinicEnrollmentController, List<ClinicEnrollment>>(
      () {
        return ClinicEnrollmentController();
      },
    );
