//import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxivet/features/pet_profile/views/allergy_list_view.dart';

// İlgili sayfaları ve controller'ı içeri aktarıyoruz

import '../../features/home/views/find_clinic_view.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../../features/pet_profile/views/add_pet_view.dart';
import '../../features/auth/views/role_check_view.dart';
import '../../features/pet_profile/views/pet_detail_view.dart';
import '../../features/health_tracking/views/weight_log_view.dart';
import '../../features/health_tracking/views/vaccination_list_view.dart';
import '../../features/health_tracking/views/lab_result_list_view.dart';
import '../../features/pet_profile/views/operation_list_view.dart';
import '../../features/pet_profile/views/examination_list_view.dart';
import '../../features/appointments/views/appointment_list_view.dart';
import '../../features/health_tracking/views/med_reminder_list_view.dart';
import '../../features/home/views/home_view.dart';
import '../../features/pet_profile/views/pet_list_view.dart';
import '../../features/home/views/clinic_home_view.dart';
import '../../features/appointments/views/book_appointment_view.dart';
import '../../features/pet_profile/views/clinic_patient_list_view.dart';
import '../../features/appointments/views/clinic_calendar_view.dart';
import '../../features/messaging/views/message_view.dart'; // Mesajlar eklendi
import '../../features/messaging/views/pet_owner_inbox_view.dart';
import '../../features/messaging/views/clinic_inbox_view.dart';
import '../../features/notifications/views/notification_view.dart';

/// Uygulamanın tüm sayfa yönlendirmelerini ve güvenlik duvarını (Auth Guard) yöneten Provider
final routerProvider = Provider<GoRouter>((ref) {
  // Kullanıcının anlık giriş durumunu dinliyoruz
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login', // Uygulama ilk açıldığında gideceği yer
    // REDIRECT (YÖNLENDİRME) MANTIĞI: Her sayfa geçişinde burası çalışır
    redirect: (context, state) {
      if (authState is AsyncLoading) return null;

      final user = authState.value;
      final isLoggedIn = user != null;

      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      // DEĞİŞEN KISIM BURASI: Artık direkt /home'a değil, karar ekranına atıyoruz
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/role-check';
      }

      return null;
    },

    // UYGULAMADAKİ TÜM SAYFALAR (ROTALAR)
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationView(),
      ),
      GoRoute(
        path: '/allergies',
        builder: (context, state) =>
            const AllergyListView(), // Henüz bu sayfayı oluşturmadık
      ),
      GoRoute(
        path: '/owner-messages',
        builder: (context, state) => const PetOwnerInboxView(),
      ), // YENİ ROTA BURADA!
      GoRoute(
        path: '/clinic-messages',
        builder: (context, state) => const ClinicInboxView(),
      ),
      GoRoute(
        path: '/find-clinic',
        builder: (context, state) => const FindClinicView(),
      ),
      GoRoute(
        path: '/role-check',
        builder: (context, state) => const RoleCheckView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeView(),
      ), // Çift home temizlendi
      GoRoute(
        path: '/add-pet',
        builder: (context, state) => const AddPetView(),
      ),
      GoRoute(
        path: '/pet-detail',
        builder: (context, state) => const PetDetailView(),
      ),
      GoRoute(
        path: '/weight-log',
        builder: (context, state) => const WeightLogView(),
      ),
      GoRoute(
        path: '/vaccinations',
        builder: (context, state) => const VaccinationListView(),
      ),
      GoRoute(
        path: '/lab-results',
        builder: (context, state) => const LabResultListView(),
      ),
      GoRoute(
        path: '/operations',
        builder: (context, state) => const OperationListView(),
      ),
      GoRoute(
        path: '/examinations',
        builder: (context, state) => const ExaminationListView(),
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentListView(),
      ),
      GoRoute(
        path: '/med-reminders',
        builder: (context, state) => const MedReminderListView(),
      ),
      GoRoute(path: '/pets', builder: (context, state) => const PetListView()),
      GoRoute(
        path: '/clinic-home',
        builder: (context, state) => const ClinicHomeView(),
      ),
      GoRoute(
        path: '/book-appointment',
        builder: (context, state) => const BookAppointmentView(),
      ),
      GoRoute(
        path: '/clinic-patients',
        builder: (context, state) => const ClinicPatientListView(),
      ),
      GoRoute(
        path: '/clinic-calendar',
        builder: (context, state) => const ClinicCalendarView(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessageView(),
      ), // Mesajlar rotası eklendi
    ],
  );
});
