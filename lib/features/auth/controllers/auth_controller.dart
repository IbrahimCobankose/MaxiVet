import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/pet_owner_model.dart';
import '../../auth/controllers/pet_owner_controller.dart';
import '../../auth/controllers/clinic_controller.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../appointments/controllers/appointment_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../pet_profile/controllers/clinic_enrollment_controller.dart';

/// Kullanıcının kimlik doğrulama durumunu (Giriş yaptı mı?, Kim?, Rolü ne?) yöneten Controller
class AuthController extends AsyncNotifier<User?> {
  // Firebase Auth durumunu dinlemek için abonelik nesnesi
  StreamSubscription<User?>? _authStateChangesSubscription;

  @override
  FutureOr<User?> build() {
    // Uygulama kapandığında dinleyiciyi kapatıyoruz (Bellek tasarrufu)
    ref.onDispose(() {
      _authStateChangesSubscription?.cancel();
    });

    final authRepository = ref.read(authRepositoryProvider);

    // Firebase Auth'un anlık durumunu dinliyoruz
    _authStateChangesSubscription = authRepository.authStateChanges.listen((
      user,
    ) async {
      state = AsyncValue.data(user);

      // ÇÖZÜM: Kullanıcı Firebase'e bağlandığı/oturum açtığı an verilerini ÇEK!
      if (user != null) {
        await _fetchInitialDataForUser(user.uid);
      }
    });

    // Uygulama ilk açıldığında mevcut kullanıcıyı döndürür
    final currentUser = authRepository.currentUser;
    if (currentUser != null) {
      _fetchInitialDataForUser(currentUser.uid); // İlk açılışta verileri çek
    }
    return currentUser;
  }

  /// Uygulama ayağa kalktığında kullanıcının rolüne göre (Clinic veya Owner) verileri hazırlar
  Future<void> _fetchInitialDataForUser(String uid) async {
    try {
      final role = await getUserRole(uid);

      if (role == 'pet_owner') {
        // --- HASTA SAHİBİ GİRİŞ YAPTI ---
        ref.read(petOwnerControllerProvider.notifier).fetchPetOwnerById(uid);
        ref.read(petControllerProvider.notifier).fetchPetsByOwner(uid);
        ref
            .read(appointmentControllerProvider.notifier)
            .fetchAppointmentsForOwner(uid);
        ref
            .read(notificationControllerProvider.notifier)
            .watchNotifications(uid);
      } else if (role == 'clinic') {
        // --- KLİNİK GİRİŞ YAPTI ---
        ref.read(clinicControllerProvider.notifier).fetchClinicById(uid);

        // 1. Kliniğin tüm randevularını çek (ve içindeki hayvan bilgilerini cache'e al)
        await ref
            .read(appointmentControllerProvider.notifier)
            .fetchAppointmentsByClinic(uid);

        // 2. ÇÖZÜM: Kliniğe kayıtlı olan "TÜM HASTALARI" çek ki Hastalar sayfası boş kalmasın!
        ref
            .read(clinicEnrollmentControllerProvider.notifier)
            .fetchEnrollmentsByClinic(uid); // <-- İSİM DÜZELTİLDİ

        // 3. Bildirimleri dinle
        ref
            .read(notificationControllerProvider.notifier)
            .watchNotifications(uid);
      }
    } catch (e) {
      // Rol bulunamazsa veya hata olursa sessizce geç
      print("Veri yükleme hatası: $e");
    }
  }

  /// Email ve şifre ile giriş yapma işlemi
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithEmailAndPassword(email, password);
      // Başarılı olursa, yukarıdaki listener (authStateChanges) state'i ve verileri otomatik güncelleyecek
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final petOwnerRepository = ref.read(petOwnerRepositoryProvider);

      // 1. Önce Firebase Auth hesabı oluşturulur
      final credential = await authRepository.registerWithEmailAndPassword(
        email,
        password,
      );
      final String uid = credential.user!.uid;

      // 2. PetOwner dökümanı hazırlanır
      final newOwner = PetOwner(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        createdAt: DateTime.now(),
      );

      // 3. İsim ve diğer bilgiler Firestore'a kaydedilir
      await petOwnerRepository.createPetOwner(newOwner);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Hesaptan çıkış yapma işlemi
  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();

      // Çıkış yapıldığında RAM'deki eski verileri temizle (Güvenlik ve stabilite için)
      ref.invalidate(petControllerProvider);
      ref.invalidate(appointmentControllerProvider);
      ref.invalidate(notificationControllerProvider);
      ref.invalidate(clinicControllerProvider);
      ref.invalidate(petOwnerControllerProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Giriş yapan kullanıcının Klinik mi yoksa Hasta Sahibi mi olduğunu kontrol eder
  Future<String?> getUserRole(String uid) async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      return await authRepository.getUserRole(uid);
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında oturum durumunu dinlemek için Provider
final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(() {
  return AuthController();
});
