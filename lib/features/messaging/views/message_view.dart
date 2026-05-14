import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/controllers/auth_controller.dart';
// ÇÖZÜM İÇİN REPOSITORY EKLENDİ
import '../../../core/providers/repository_providers.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../pet_profile/models/pet_model.dart';
import '../controllers/message_controller.dart';
import '../models/message_model.dart';
import '../../../core/providers/app_state_providers.dart';

class MessageView extends ConsumerStatefulWidget {
  const MessageView({super.key});

  @override
  ConsumerState<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends ConsumerState<MessageView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petId = ref.read(selectedPetIdProvider);
      if (petId != null) {
        ref.read(messageControllerProvider.notifier).watchMessages(petId);
        // ÇÖZÜM: Burada clinicEnrollmentController'ı tetikleyip global state'i (Hastalar listesini) BOZMUYORUZ.
        // O kod bloğu tamamen silindi!
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final petId = ref.read(selectedPetIdProvider);
    if (petId == null) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final pet = await ref
        .read(petControllerProvider.notifier)
        .getPetDetails(petId);
    if (pet == null) return;

    final isPetOwner = user.uid == pet.ownerId;

    String receiverId;

    if (isPetOwner) {
      // ÇÖZÜM: Global state'i bozmak yerine, kliniği doğrudan veritabanından (repository) sessizce okuyoruz.
      final enrollmentRepo = ref.read(clinicEnrollmentRepositoryProvider);
      final enrollments = await enrollmentRepo.getEnrollmentsByPetId(petId);

      if (enrollments.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bu dostunuz henüz bir kliniğe kayıtlı değil. Mesaj atmak için önce klinik kaydı yapmalısınız.',
              ),
            ),
          );
        }
        return;
      }
      receiverId = enrollments.first.clinicId;
    } else {
      receiverId = pet.ownerId;
    }

    _messageController.clear();

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.uid,
      senderType: isPetOwner ? 'pet_owner' : 'clinic',
      receiverId: receiverId,
      receiverType: isPetOwner ? 'clinic' : 'pet_owner',
      petId: petId,
      content: text,
      sentAt: DateTime.now(),
      isRead: false,
    );

    try {
      await ref
          .read(messageControllerProvider.notifier)
          .sendMessage(newMessage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).value;

    ref.listen<AsyncValue<List<Message>>>(messageControllerProvider, (
      previous,
      next,
    ) {
      next.whenData((messages) {
        if (currentUser != null) {
          for (final msg in messages) {
            if (msg.senderId != currentUser.uid && !msg.isRead) {
              ref
                  .read(messageControllerProvider.notifier)
                  .markMessageAsRead(msg.id);
            }
          }
        }
      });
    });

    final messagesState = ref.watch(messageControllerProvider);
    final petId = ref.watch(selectedPetIdProvider);
    final petsState = ref.watch(petControllerProvider);

    final myPets =
        petsState.value?.where((p) => p.ownerId == currentUser?.uid).toList() ??
        [];
    final isPetOwner = myPets.isNotEmpty;

    if (isPetOwner && petId == null && myPets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final firstPetId = myPets.first.id;
        ref.read(selectedPetIdProvider.notifier).setPetId(firstPetId);
        ref.read(messageControllerProvider.notifier).watchMessages(firstPetId);
        // ÇÖZÜM: Buradaki enrollment çekme kodunu da sildik.
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF191C1E)),
          onPressed: () => context.pop(),
        ),
        title: FutureBuilder<Pet?>(
          future: petId != null
              ? ref.read(petControllerProvider.notifier).getPetDetails(petId)
              : Future.value(null),
          builder: (context, snapshot) {
            final petName = snapshot.hasData
                ? snapshot.data!.name
                : 'Sohbet...';
            final initial = petName != 'Sohbet...' && petName.isNotEmpty
                ? petName[0].toUpperCase()
                : '?';
            final isOwner = currentUser?.uid == snapshot.data?.ownerId;

            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D33).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF006D33),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petName,
                      style: const TextStyle(
                        color: Color(0xFF191C1E),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isOwner ? 'Klinik ile Sohbet' : 'Hasta Sahibi ile Sohbet',
                      style: const TextStyle(
                        color: Color(0xFF006D33),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text('Yükleniyor...'))
          : Column(
              children: [
                if (isPetOwner && myPets.isNotEmpty)
                  Container(
                    height: 60,
                    color: Colors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: myPets.length,
                      itemBuilder: (context, index) {
                        final pet = myPets[index];
                        final isSelected = pet.id == petId;
                        return GestureDetector(
                          onTap: () {
                            if (!isSelected) {
                              ref
                                  .read(selectedPetIdProvider.notifier)
                                  .setPetId(pet.id);
                              ref
                                  .read(messageControllerProvider.notifier)
                                  .watchMessages(pet.id);
                              // ÇÖZÜM: Buradaki enrollment çekme kodunu da sildik.
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF006D33)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF006D33)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              pet.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                if (petId == null)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Lütfen bir dostunuzu seçin.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: messagesState.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF006D33),
                        ),
                      ),
                      error: (err, stack) =>
                          Center(child: Text('Bir hata oluştu: $err')),
                      data: (messages) {
                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Henüz bir mesaj bulunmuyor.',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId == currentUser.uid;
                            return _buildChatBubble(msg, isMe);
                          },
                        );
                      },
                    ),
                  ),

                if (petId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.attach_file,
                              color: Colors.grey,
                            ),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9FB),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _messageController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                minLines: 1,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Mesajınızı yazın...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF006D33),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _handleSendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildChatBubble(Message msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF006D33).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF006D33),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF006D33) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe ? null : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  if (!isMe)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF191C1E),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.sentAt),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: msg.isRead
                              ? const Color(0xFF00FF7F)
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
