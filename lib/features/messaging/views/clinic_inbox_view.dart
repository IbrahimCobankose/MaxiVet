import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/message_controller.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../pet_profile/models/pet_model.dart';
import '../../../core/providers/app_state_providers.dart';

class ClinicInboxView extends ConsumerStatefulWidget {
  const ClinicInboxView({super.key});

  @override
  ConsumerState<ClinicInboxView> createState() => _ClinicInboxViewState();
}

class _ClinicInboxViewState extends ConsumerState<ClinicInboxView> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    // ÇÖZÜM: Tüm hastaların listesini direkt global RAM'den okuyoruz
    final allPets = ref.watch(petControllerProvider).value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF191C1E)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Gelen Kutusu',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ref
                .watch(clinicInboxProvider(user.uid))
                .when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF006D33)),
                  ),
                  error: (e, s) =>
                      const Center(child: Text('Mesajlar yüklenemedi.')),
                  data: (inboxMessages) {
                    if (inboxMessages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gelen kutunuz boş.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 120,
                      ),
                      itemCount: inboxMessages.length,
                      itemBuilder: (context, index) {
                        final msg = inboxMessages[index];
                        final isUnread =
                            !msg.isRead && msg.senderType == 'pet_owner';

                        // ÇÖZÜM: Hayvan detayını yavaş FutureBuilder yerine anında RAM'den buluyoruz!
                        final pet = allPets.firstWhere(
                          (p) => p.id == msg.petId,
                          orElse: () => Pet(
                            id: '',
                            ownerId: '',
                            name: 'Bilinmeyen',
                            species: '',
                            breed: '',
                            birthDate: DateTime.now(),
                            neutered: false,
                          ),
                        );

                        final petName = pet.name;
                        final initial = petName.isNotEmpty
                            ? petName[0].toUpperCase()
                            : '?';

                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(selectedPetIdProvider.notifier)
                                .setPetId(msg.petId);
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
                                // 1. Hayvan Avatarı
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
                                      initial,
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

                                // 2. İsim ve Son Mesaj
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        petName,
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
                                        msg.senderType == 'clinic'
                                            ? 'Siz: ${msg.content}'
                                            : msg.content,
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
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 3. Saat ve Okunmamış Bildirim Sayısı
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(msg.sentAt),
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

  Widget _buildGlassBottomNav(BuildContext context) {
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
            Icons.dashboard_outlined,
            'Panel',
            '/clinic-home',
            isActive: false,
          ),
          _buildNavItem(
            context,
            Icons.people_alt_outlined,
            'Hastalar',
            '/clinic-patients',
            isActive: false,
          ),
          _buildNavItem(
            context,
            Icons.calendar_month_outlined,
            'Takvim',
            '/clinic-calendar',
            isActive: false,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF006D33),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF006D33).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  'Mesajlar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
  }) {
    return GestureDetector(
      onTap: () {
        if (!isActive) context.push(route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
