import 'package:flutter_riverpod/flutter_riverpod.dart';

// Appointment Modülü
import '../../features/appointments/repositories/i_appointment_repository.dart';
import '../../features/appointments/repositories/firebase_appointment_repository.dart';

// Auth Modülü
import '../../features/auth/repositories/i_pet_owner_repository.dart';
import '../../features/auth/repositories/firebase_pet_owner_repository.dart';
import '../../features/auth/repositories/i_clinic_repository.dart';
import '../../features/auth/repositories/firebase_clinic_repository.dart';
import '../../features/auth/repositories/i_auth_repository.dart';
import '../../features/auth/repositories/firebase_auth_repository.dart';

// Health Tracking Modülü
import '../../features/health_tracking/repositories/i_vaccination_repository.dart';
import '../../features/health_tracking/repositories/firebase_vaccination_repository.dart';
import '../../features/health_tracking/repositories/i_lab_result_repository.dart';
import '../../features/health_tracking/repositories/firebase_lab_result_repository.dart';
import '../../features/health_tracking/repositories/i_weight_log_repository.dart';
import '../../features/health_tracking/repositories/firebase_weight_log_repository.dart';
import '../../features/health_tracking/repositories/i_med_reminder_repository.dart';
import '../../features/health_tracking/repositories/firebase_med_reminder_repository.dart';

// Messaging Modülü
import '../../features/messaging/repositories/i_message_repository.dart';
import '../../features/messaging/repositories/firebase_message_repository.dart';

// Notifications Modülü
import '../../features/notifications/repositories/i_notification_repository.dart';
import '../../features/notifications/repositories/firebase_notification_repository.dart';

// Pet Profile Modülü
import '../../features/pet_profile/repositories/i_pet_repository.dart';
import '../../features/pet_profile/repositories/firebase_pet_repository.dart';
import '../../features/pet_profile/repositories/i_allergy_repository.dart';
import '../../features/pet_profile/repositories/firebase_allergy_repository.dart';
import '../../features/pet_profile/repositories/i_operation_repository.dart';
import '../../features/pet_profile/repositories/firebase_operation_repository.dart';
import '../../features/pet_profile/repositories/i_examination_repository.dart';
import '../../features/pet_profile/repositories/firebase_examination_repository.dart';
import '../../features/pet_profile/repositories/i_clinic_enrollment_repository.dart';
import '../../features/pet_profile/repositories/firebase_clinic_enrollment_repository.dart';

/// --- APPOINTMENT REPOSITORIES ---
final appointmentRepositoryProvider = Provider<IAppointmentRepository>((ref) {
  return FirebaseAppointmentRepository();
});

/// --- AUTH REPOSITORIES ---
final petOwnerRepositoryProvider = Provider<IPetOwnerRepository>((ref) {
  return FirebasePetOwnerRepository();
});

final clinicRepositoryProvider = Provider<IClinicRepository>((ref) {
  return FirebaseClinicRepository();
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// --- HEALTH TRACKING REPOSITORIES ---
final vaccinationRepositoryProvider = Provider<IVaccinationRepository>((ref) {
  return FirebaseVaccinationRepository();
});

final labResultRepositoryProvider = Provider<ILabResultRepository>((ref) {
  return FirebaseLabResultRepository();
});

final weightLogRepositoryProvider = Provider<IWeightLogRepository>((ref) {
  return FirebaseWeightLogRepository();
});

final medReminderRepositoryProvider = Provider<IMedReminderRepository>((ref) {
  return FirebaseMedReminderRepository();
});

/// --- MESSAGING REPOSITORIES ---
final messageRepositoryProvider = Provider<IMessageRepository>((ref) {
  return FirebaseMessageRepository();
});

/// --- NOTIFICATIONS REPOSITORIES ---
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return FirebaseNotificationRepository();
});

/// --- PET PROFILE REPOSITORIES ---
final petRepositoryProvider = Provider<IPetRepository>((ref) {
  return FirebasePetRepository();
});

final allergyRepositoryProvider = Provider<IAllergyRepository>((ref) {
  return FirebaseAllergyRepository();
});

final operationRepositoryProvider = Provider<IOperationRepository>((ref) {
  return FirebaseOperationRepository();
});

final examinationRepositoryProvider = Provider<IExaminationRepository>((ref) {
  return FirebaseExaminationRepository();
});

final clinicEnrollmentRepositoryProvider =
    Provider<IClinicEnrollmentRepository>((ref) {
      return FirebaseClinicEnrollmentRepository();
    });
