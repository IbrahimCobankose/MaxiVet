import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../models/med_reminder_model.dart';

/// Artık State olarak sadece List<MedReminder> değil,
/// Map<String, List<MedReminder>> (Yani {PetId: [Ilaçlar]}) tutuyoruz.
class MedReminderController
    extends AsyncNotifier<Map<String, List<MedReminder>>> {
  @override
  FutureOr<Map<String, List<MedReminder>>> build() {
    return {}; // Başlangıçta boş bir sözlük
  }

  /// Belirli bir hayvanın ilaçlarını çeker ve sözlüğe (Cache'e) ekler
  Future<void> fetchAllMedReminders(String petId) async {
    // Eğer o hayvanın verisi RAM'de (state sözlüğümüzde) varsa HİÇBİR ŞEY YAPMA, dön!
    if (state.hasValue && state.value!.containsKey(petId)) {
      return;
    }

    // Yüklenme ekranı sadece ilk kez veri çekiliyorsa çıksın
    if (!state.hasValue || state.value!.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      final repository = ref.read(medReminderRepositoryProvider);
      final reminders = await repository.getMedRemindersByPetId(petId);

      final currentMap = state.value ?? {};
      // Çekilen listeyi ilgili hayvanın ID'si ile sözlüğe kaydediyoruz
      currentMap[petId] = reminders;

      state = AsyncValue.data(
        Map.from(currentMap),
      ); // Map'i güncelleyerek UI'ı tetikle
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> fetchActiveMedReminders(String petId) async {
    try {
      final repository = ref.read(medReminderRepositoryProvider);
      final activeReminders = await repository.getActiveMedRemindersByPetId(
        petId,
      );

      final currentMap = state.value ?? {};
      currentMap[petId] = activeReminders;

      state = AsyncValue.data(Map.from(currentMap));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addMedReminder(MedReminder reminder) async {
    try {
      final repository = ref.read(medReminderRepositoryProvider);
      await repository.addMedReminder(reminder);

      if (state.hasValue) {
        final currentMap = Map<String, List<MedReminder>>.from(state.value!);
        final petList = currentMap[reminder.petId] ?? [];

        // Yeni ilacı o hayvanın listesine ekle
        currentMap[reminder.petId] = [reminder, ...petList];
        state = AsyncValue.data(currentMap);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMedReminder(MedReminder reminder) async {
    try {
      final repository = ref.read(medReminderRepositoryProvider);
      await repository.updateMedReminder(reminder);

      if (state.hasValue) {
        final currentMap = Map<String, List<MedReminder>>.from(state.value!);
        final petList = List<MedReminder>.from(
          currentMap[reminder.petId] ?? [],
        );

        final index = petList.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          petList[index] = reminder;
          currentMap[reminder.petId] = petList;
          state = AsyncValue.data(currentMap);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleReminderStatus(
    String id,
    String petId,
    bool isActive,
  ) async {
    try {
      if (!state.hasValue) return;

      final currentMap = Map<String, List<MedReminder>>.from(state.value!);
      final petList = List<MedReminder>.from(currentMap[petId] ?? []);

      // İlgili alarmı bul
      final reminderIndex = petList.indexWhere((r) => r.id == id);
      if (reminderIndex == -1) return;

      final updatedReminder = petList[reminderIndex].copyWith(active: isActive);

      // Firebase'i güncelle
      final repository = ref.read(medReminderRepositoryProvider);
      await repository.updateMedReminder(updatedReminder);

      // UI Listesini (Sözlüğü) güncelle
      petList[reminderIndex] = updatedReminder;
      currentMap[petId] = petList;
      state = AsyncValue.data(currentMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMedReminder(String id, String petId) async {
    try {
      final repository = ref.read(medReminderRepositoryProvider);
      await repository.deleteMedReminder(id);

      if (state.hasValue) {
        final currentMap = Map<String, List<MedReminder>>.from(state.value!);
        final petList = currentMap[petId] ?? [];

        currentMap[petId] = petList.where((r) => r.id != id).toList();
        state = AsyncValue.data(currentMap);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// İŞTE HATAYA SEBEP OLAN, DÜZELTİLMİŞ EN ALT KISIM BURASI 👇
final medReminderControllerProvider =
    AsyncNotifierProvider<
      MedReminderController,
      Map<String, List<MedReminder>>
    >(() {
      return MedReminderController();
    });
