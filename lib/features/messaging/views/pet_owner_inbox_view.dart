import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/message_controller.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../../core/providers/app_state_providers.dart';

class PetOwnerInboxView extends ConsumerStatefulWidget {
  const PetOwnerInboxView({super.key});

  @override
  ConsumerState<PetOwnerInboxView> createState() => _PetOwnerInboxViewState();
}

class _PetOwnerInboxViewState extends ConsumerState<PetOwnerInboxView> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final petsState = ref.watch(petControllerProvider);

    // Sadece bu kullanıcıya ait hayvanları al
    final myPets =
        petsState.value?.where((p) => p.ownerId == user?.uid).toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF191C1E)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Mesajlarım',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF006D33)),
            )
          : myPets.isEmpty
          ? _buildEmptyState('Sisteme kayıtlı bir dostunuz bulunmuyor.')
          : ref
                .watch(petOwnerInboxProvider(user.uid))
                .when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF006D33)),
                  ),
                  error: (e, s) => Center(child: Text('Hata: $e')),
                  data: (inboxMessages) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 120,
                      ),
                      itemCount: myPets.length,
                      itemBuilder: (context, index) {
                        final pet = myPets[index];

                        // Bu hayvana ait inbox'ta bir mesaj var mı bulalım
                        final lastMsgIndex = inboxMessages.indexWhere(
                          (m) => m.petId == pet.id,
                        );
                        final lastMsg = lastMsgIndex != -1
                            ? inboxMessages[lastMsgIndex]
                            : null;

                        // Karşıdan gelmiş ve okunmamış mesaj mı?
                        final isUnread =
                            lastMsg != null &&
                            !lastMsg.isRead &&
                            lastMsg.senderType == 'clinic';

                        return GestureDetector(
                          onTap: () {
                            // Tıklandığında o hayvanın sohbetine zıplıyoruz
                            ref
                                .read(selectedPetIdProvider.notifier)
                                .setPetId(pet.id);
                            context.push('/messages');
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? Colors.white
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isUnread
                                    ? const Color(
                                        0xFF006D33,
                                      ).withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                              ),
                              boxShadow: isUnread
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF006D33,
                                        ).withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                // Hayvan Avatarı
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isUnread
                                        ? const Color(0xFF006D33)
                                        : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      pet.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: isUnread
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Mesaj Özeti
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pet.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isUnread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: const Color(0xFF191C1E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMsg != null
                                            ? (lastMsg.senderType == 'pet_owner'
                                                  ? 'Siz: ${lastMsg.content}'
                                                  : lastMsg.content)
                                            : 'Henüz mesaj yok. Kliniğe danışın.',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isUnread
                                              ? const Color(0xFF191C1E)
                                              : Colors.grey.shade600,
                                          fontWeight: isUnread
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontStyle: lastMsg == null
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Saat ve Okunmamış Bildirimi
                                if (lastMsg != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'HH:mm',
                                        ).format(lastMsg.sentAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isUnread
                                              ? const Color(0xFF006D33)
                                              : Colors.grey.shade500,
                                          fontWeight: isUnread
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (isUnread)
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF00FF7F),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      bottomNavigationBar: _buildGlassBottomNav(context),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006D33).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            Icons.dashboard,
            'Panel',
            '/home',
            isActive: false,
          ),
          _buildNavItem(
            context,
            Icons.pets,
            'Dostlarım',
            '/pets',
            isActive: false,
          ),
          _buildNavItem(
            context,
            Icons.calendar_today_outlined,
            'Randevu',
            '/appointments',
            isActive: false,
          ),
          // MESAJLAR SAYFASINDA OLDUĞUMUZ İÇİN BURASI TRUE!
          _buildNavItem(
            context,
            Icons.chat_bubble, // İkonun içi dolu olsun
            'Mesajlar',
            '/owner-messages',
            isActive: true,
            unreadCount: unreadCount,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String route, {
    required bool isActive,
    int unreadCount = 0,
  }) {
    final color = isActive ? const Color(0xFF006D33) : Colors.grey.shade500;

    return GestureDetector(
      onTap: () {
        if (!isActive) context.push(route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 8)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF006D33) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF006D33).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isActive ? Colors.white : color, size: 24),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF7F),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Color(0xFF006D33),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
