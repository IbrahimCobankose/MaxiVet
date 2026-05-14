import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/message_model.dart';
import '../../auth/controllers/auth_controller.dart'; // ÇÖZÜM 1: EKSİK İMPORT EKLENDİ

/// Mesajları gerçek zamanlı dinleyen ve sohbet işlemlerini yöneten Controller
class MessageController extends AsyncNotifier<List<Message>> {
  StreamSubscription<List<Message>>? _messageSubscription;

  @override
  FutureOr<List<Message>> build() {
    ref.onDispose(() {
      _messageSubscription?.cancel();
    });
    return [];
  }

  void watchMessages(String petId) {
    state = const AsyncValue.loading();
    _messageSubscription?.cancel();

    final repository = ref.read(messageRepositoryProvider);

    _messageSubscription = repository
        .getMessageStreamByPetId(petId)
        .listen(
          (messages) {
            state = AsyncValue.data(messages);
          },
          onError: (error, stackTrace) {
            state = AsyncValue.error(error, stackTrace);
          },
        );
  }

  Future<void> sendMessage(Message message) async {
    try {
      final repository = ref.read(messageRepositoryProvider);
      await repository.sendMessage(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      final repository = ref.read(messageRepositoryProvider);
      await repository.markMessageAsRead(messageId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage(String id) async {
    try {
      final repository = ref.read(messageRepositoryProvider);
      await repository.deleteMessage(id);
    } catch (e) {
      rethrow;
    }
  }
}

final messageControllerProvider =
    AsyncNotifierProvider<MessageController, List<Message>>(() {
      return MessageController();
    });

final clinicInboxProvider = StreamProvider.family<List<Message>, String>((
  ref,
  clinicId,
) {
  final repository = ref.read(messageRepositoryProvider);
  return repository.getClinicInboxStream(clinicId);
});

final petOwnerInboxProvider = StreamProvider.family<List<Message>, String>((
  ref,
  ownerId,
) {
  final repository = ref.read(messageRepositoryProvider);
  return repository.getPetOwnerInboxStream(ownerId);
});

// YENİ EKLENEN: OKUNMAMIŞ MESAJ SAYACI (ÇİFT SAYMA HATASI DÜZELTİLDİ)
final unreadCountProvider = Provider<int>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return 0;

  final clinicInbox = ref.watch(clinicInboxProvider(user.uid)).value ?? [];
  final ownerInbox = ref.watch(petOwnerInboxProvider(user.uid)).value ?? [];

  // ÇÖZÜM: Çift saymayı engellemek için sadece benzersiz mesaj ID'lerini tutan bir Set (Küme) kullanıyoruz.
  final uniqueUnreadMessageIds = <String>{};

  // Kliniğin kutusundaki okunmamışları kümeye ekle
  for (final msg in clinicInbox) {
    if (msg.senderId != user.uid && !msg.isRead) {
      uniqueUnreadMessageIds.add(msg.id);
    }
  }

  // Müşterinin kutusundaki okunmamışları kümeye ekle (Aynı mesajsa küme bunu reddeder ve çift saymaz)
  for (final msg in ownerInbox) {
    if (msg.senderId != user.uid && !msg.isRead) {
      uniqueUnreadMessageIds.add(msg.id);
    }
  }

  // Kümenin eleman sayısını döndür
  return uniqueUnreadMessageIds.length;
});
