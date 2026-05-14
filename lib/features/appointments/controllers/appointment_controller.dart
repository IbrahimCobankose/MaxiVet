import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Tarih formatı için eklendi

// İçe aktarma yolları taslak mimarine göre ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/appointment_model.dart';
import '../../pet_profile/controllers/pet_controller.dart';

// YENİ EKLENEN IMPORTLAR
import '../../notifications/models/notification_model.dart';
import '../../auth/controllers/auth_controller.dart';

/// Randevu işlemlerini ve arayüzdeki randevu listesi durumunu (state) yöneten Controller
class AppointmentController extends AsyncNotifier<List<Appointment>> {
  @override
  FutureOr<List<Appointment>> build() {
    return [];
  }

  /// Kliniğe ait randevuları getirir ve state'i günceller
  Future<void> fetchAppointmentsByClinic(
    String clinicId, {
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final appointments = await repository.getAppointmentsByClinicId(
        clinicId,
        date: date,
      );

      final petNotifier = ref.read(petControllerProvider.notifier);
      for (var appt in appointments) {
        final currentPets = ref.read(petControllerProvider).value ?? [];
        final isPetAlreadyFetched = currentPets.any((p) => p.id == appt.petId);

        if (!isPetAlreadyFetched) {
          await petNotifier.getPetDetails(appt.petId);
        }
      }

      state = AsyncValue.data(appointments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Hasta sahibinin TÜM hayvanlarına ait randevuları getirir ve state'i günceller
  Future<void> fetchAppointmentsForOwner(String ownerId) async {
    state = const AsyncValue.loading();
    try {
      final petRepository = ref.read(petRepositoryProvider);
      final pets = await petRepository.getPetsByOwnerId(ownerId);

      final petIds = pets.map((pet) => pet.id).toList();

      if (petIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final repository = ref.read(appointmentRepositoryProvider);
      final appointments = await repository.getAppointmentsByPetIds(petIds);

      state = AsyncValue.data(appointments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Yeni randevu oluşturur ve BİLDİRİMLERİ TETİKLER
  Future<void> createAppointment(Appointment appointment) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.createAppointment(appointment);

      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data([...currentList, appointment]);
      }

      // -----------------------------------------------------
      // BİLDİRİM TETİKLEYİCİSİ 1: Yeni Randevu Alındığında
      // -----------------------------------------------------
      final notifRepo = ref.read(notificationRepositoryProvider);
      final timeStr = DateFormat(
        'dd MMM HH:mm',
        'tr_TR',
      ).format(appointment.startsAt);

      // 1A. Kliniğe gidecek bildirim
      final clinicNotif = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_c',
        recipientId: appointment.clinicId,
        recipientType: 'clinic',
        type: 'appointment',
        title: 'Yeni Randevu Talebi',
        content: '${appointment.type} için yeni bir talep var. ($timeStr)',
        scheduledAt: DateTime.now(),
        sent: false,
      );
      await notifRepo.addNotification(clinicNotif);

      // 1B. Müşteriye (Kendisine) gidecek onay bekleme bildirimi
      final currentUser = ref.read(authControllerProvider).value;
      if (currentUser != null) {
        final ownerNotif = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_o',
          recipientId: currentUser.uid,
          recipientType: 'pet_owner',
          type: 'appointment',
          title: 'Randevu Talebiniz İletildi',
          content: '$timeStr tarihindeki randevunuz kliniğin onayını bekliyor.',
          scheduledAt: DateTime.now(),
          sent: false,
        );
        await notifRepo.addNotification(ownerNotif);
      }
      // -----------------------------------------------------
    } catch (e) {
      rethrow;
    }
  }

  /// Randevu durumunu günceller ve MÜŞTERİYE BİLDİRİM ATAR
  Future<void> updateAppointmentStatus(String id, String newStatus) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.updateAppointmentStatus(id, newStatus);

      Appointment? updatedAppt;

      if (state.hasValue) {
        final updatedList = state.value!.map((app) {
          if (app.id == id) {
            updatedAppt = app.copyWith(status: newStatus);
            return updatedAppt!;
          }
          return app;
        }).toList();
        state = AsyncValue.data(updatedList);
      }

      // -----------------------------------------------------
      // BİLDİRİM TETİKLEYİCİSİ 2: Klinik Randevu Durumunu Değiştirdiğinde
      // -----------------------------------------------------
      if (updatedAppt != null) {
        // Sahibinin UID'sini bulmak için hayvan bilgisini çekiyoruz
        final petRepo = ref.read(petRepositoryProvider);
        final pet = await petRepo.getPetById(updatedAppt!.petId);

        if (pet != null) {
          String statusTr = newStatus == 'confirmed'
              ? 'Onaylandı'
              : newStatus == 'cancelled'
              ? 'İptal Edildi'
              : 'Tamamlandı';

          final ownerNotif = NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            recipientId: pet.ownerId,
            recipientType: 'pet_owner',
            type: 'appointment',
            title: 'Randevunuz $statusTr',
            content:
                '${pet.name} için talep ettiğiniz randevu klinik tarafından $statusTr.',
            scheduledAt: DateTime.now(),
            sent: false,
          );

          await ref
              .read(notificationRepositoryProvider)
              .addNotification(ownerNotif);
        }
      }
      // -----------------------------------------------------
    } catch (e) {
      rethrow;
    }
  }

  /// Randevuyu siler ve state'i günceller
  Future<void> deleteAppointment(String id) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.deleteAppointment(id);

      if (state.hasValue) {
        final updatedList = state.value!.where((app) => app.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve fonksiyonlarına erişmek için Provider
final appointmentControllerProvider =
    AsyncNotifierProvider<AppointmentController, List<Appointment>>(() {
      return AppointmentController();
    });
