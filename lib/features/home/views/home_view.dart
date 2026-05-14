import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../messaging/controllers/message_controller.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../pet_profile/models/pet_model.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/pet_owner_controller.dart';
import '../../appointments/controllers/appointment_controller.dart';
import '../../appointments/models/appointment_model.dart';
import '../../notifications/controllers/notification_controller.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        final currentPets = ref.read(petControllerProvider).value;
        if (currentPets == null || currentPets.isEmpty) {
          ref.read(petControllerProvider.notifier).fetchPetsByOwner(user.uid);
        }

        final currentApps = ref.read(appointmentControllerProvider).value;
        if (currentApps == null || currentApps.isEmpty) {
          ref
              .read(appointmentControllerProvider.notifier)
              .fetchAppointmentsForOwner(user.uid);
        }

        final currentOwner = ref.read(petOwnerControllerProvider).value;
        if (currentOwner == null) {
          ref
              .read(petOwnerControllerProvider.notifier)
              .fetchPetOwnerById(user.uid);
        }

        ref
            .read(notificationControllerProvider.notifier)
            .watchNotifications(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petsState = ref.watch(petControllerProvider);
    final petOwnerState = ref.watch(petOwnerControllerProvider);
    final appointmentState = ref.watch(appointmentControllerProvider);
    Appointment? nextAppointment;

    if (appointmentState.value != null && appointmentState.value!.isNotEmpty) {
      final now = DateTime.now(); // GEÇMİŞ SAATLERİ GİZLEME ÇÖZÜMÜ

      final upcoming = appointmentState.value!
          .where(
            (app) =>
                (app.status == 'confirmed' || app.status == 'pending') &&
                app.startsAt.isAfter(now),
          )
          .toList();

      if (upcoming.isNotEmpty) {
        upcoming.sort((a, b) => a.startsAt.compareTo(b.startsAt));
        nextAppointment = upcoming.first;
      }
    }

    return petOwnerState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Hata: $err'))),
      data: (owner) {
        final userName = owner?.name ?? "Kullanıcı";
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          extendBody: true,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                context.go('/login');
              },
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                const Text(
                  'MaxiVet',
                  style: TextStyle(
                    color: Color(0xFF006D33),
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF006D33),
                      size: 28,
                    ),
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  if (ref.watch(unreadNotificationCountProvider) > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          ref.watch(unreadNotificationCountProvider).toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba $userName,',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tüylü dostlarınızın tüm sağlık kontrolleri güvende.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: nextAppointment != null
                            ? [Colors.orange.shade700, Colors.orange.shade400]
                            : [
                                const Color(0xFF006D33),
                                const Color(0xFF00A84F),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: nextAppointment != null
                              ? Colors.orange.withValues(alpha: 0.3)
                              : const Color(0xFF006D33).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            nextAppointment != null
                                ? Icons.access_time_filled
                                : Icons.verified_user_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextAppointment != null
                                    ? '${petsState.value?.firstWhere(
                                        (p) => p.id == nextAppointment!.petId,
                                        orElse: () => Pet(id: '', ownerId: '', name: 'Dostunuzun', species: '', breed: '', birthDate: DateTime.now(), neutered: false),
                                      ).name} Randevusu Var'
                                    : 'Bir Sıkıntı Yok',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextAppointment != null
                                    ? '${DateFormat('d MMMM EEEE, HH:mm', 'tr_TR').format(nextAppointment.startsAt)}\n${nextAppointment.type}'
                                    : 'Yaklaşan aşı veya acil bir randevunuz bulunmuyor.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // YENİ EKLENEN KISIM: DOSTLARIM BAŞLIĞI VE HEPSİNİ GÖR BUTONU
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dostlarım',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/pets'),
                        child: const Text(
                          'Hepsini Gör',
                          style: TextStyle(
                            color: Color(0xFF006D33),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 180,
                  child: petsState.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006D33),
                      ),
                    ),
                    error: (err, stack) => Center(child: Text('Hata: $err')),
                    data: (pets) {
                      if (pets.isEmpty) {
                        return Center(
                          child: Text(
                            'Henüz bir dost eklemediniz.',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        );
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return _buildPetCard(context, pet);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Hızlı İşlemler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/find-clinic'),
                          child: _buildQuickActionCard(
                            Icons.local_hospital_outlined,
                            'Klinik', // Ekrana daha iyi sığması için kısaltıldı
                            Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), // Boşluk 12'ye düşürüldü
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/book-appointment'),
                          child: _buildQuickActionCard(
                            Icons.calendar_month_outlined,
                            'Randevu', // Ekrana daha iyi sığması için kısaltıldı
                            Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), // Yeni eklendi
                      Expanded(
                        // İlaç Hatırlatıcısı Butonu
                        child: GestureDetector(
                          onTap: () => context.push('/med-reminders'),
                          child: _buildQuickActionCard(
                            Icons.alarm_add_outlined,
                            'Hatırlatıcı',
                            Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildGlassBottomNav(context),
        );
      },
    );
  }

  Widget _buildPetCard(BuildContext context, Pet pet) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedPetIdProvider.notifier).setPetId(pet.id);
        context.push('/pet-detail');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF006D33).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF006D33).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  pet.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006D33),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              pet.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${pet.species} • ${pet.breed}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    IconData icon,
    String title,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade600, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
            isActive: true,
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
          _buildNavItem(
            context,
            Icons.chat_bubble_outline,
            'Mesajlar',
            '/owner-messages',
            isActive: false,
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
