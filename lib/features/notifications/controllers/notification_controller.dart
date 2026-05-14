import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/notification_model.dart';

/// Bildirimleri gerçek zamanlı dinleyen ve yöneten Controller
class NotificationController extends AsyncNotifier<List<NotificationModel>> {
  // Stream'i dinlemek ve bellek sızıntısını önlemek için abonelik (subscription) nesnesi
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;

  @override
  FutureOr<List<NotificationModel>> build() {
    // Uygulama kapandığında veya kullanıcı oturumu kapattığında dinlemeyi iptal ediyoruz
    ref.onDispose(() {
      _notificationSubscription?.cancel();
    });

    return [];
  }

  /// Kullanıcıya (Klinik veya Hasta Sahibi) ait bildirimleri anlık olarak dinlemeye başlar
  void watchNotifications(String recipientId) {
    // Veri yüklenene kadar UI'da loading (örneğin zil ikonunda bir yüklenme işareti) göstermek için
    state = const AsyncValue.loading();

    // Eğer hali hazırda çalışan bir dinleyici varsa kapatılır
    _notificationSubscription?.cancel();

    final repository = ref.read(notificationRepositoryProvider);

    // Firestore koleksiyonunu canlı dinlemeye başlıyoruz
    _notificationSubscription = repository
        .getNotificationStreamByRecipientId(recipientId)
        .listen(
          (notifications) {
            // Yeni bir bildirim geldiğinde (veya okunduğunda) state anında güncellenir
            state = AsyncValue.data(notifications);
          },
          onError: (error, stackTrace) {
            state = AsyncValue.error(error, stackTrace);
          },
        );
  }

  /// Yeni bildirim oluşturur (Genelde sistem, Cloud Functions veya klinik tarafından tetiklenir)
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.addNotification(notification);

      // DİKKAT: Stream (watchNotifications) aktif olduğu için state'e manuel ekleme yapmıyoruz.
      // Firebase'e veri yazıldığı an Stream bunu algılayıp listeyi otomatik güncelleyecektir.
    } catch (e) {
      rethrow;
    }
  }

  /// Bildirim başarıyla iletildiğinde veya kullanıcı bildirime tıkladığında çalışır
  Future<void> markNotificationAsSent(String id) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.markNotificationAsSent(id);
      // Stream sayesinde bildirimin durumu arayüzde anında güncellenecek.
    } catch (e) {
      rethrow;
    }
  }

  /// Kullanıcı bildirimi sildiğinde (Örn: yana kaydırarak silme işlemi) çalışır
  Future<void> deleteNotification(String id) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.deleteNotification(id);
      // Silinen bildirim Stream üzerinden anında arayüzden kaybolacak.
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve bildirim sayısını (badge) göstermek için Provider
final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<NotificationModel>>(() {
      return NotificationController();
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationControllerProvider).value ?? [];
  return notifications.where((n) => !n.sent).length;
});
