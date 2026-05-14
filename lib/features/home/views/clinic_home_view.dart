import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../messaging/controllers/message_controller.dart';
import '../../appointments/models/appointment_model.dart';
import '../../appointments/controllers/appointment_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/clinic_controller.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../pet_profile/models/pet_model.dart';
import '../../notifications/controllers/notification_controller.dart';

class ClinicHomeView extends ConsumerStatefulWidget {
  const ClinicHomeView({super.key});

  @override
  ConsumerState<ClinicHomeView> createState() => _ClinicHomeViewState();
}

class _ClinicHomeViewState extends ConsumerState<ClinicHomeView> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final appointmentState = ref.watch(appointmentControllerProvider);
    final clinicState = ref.watch(clinicControllerProvider);
    // Artık hayvanları çeken RAM (state) listesini doğrudan dinliyoruz
    final petsState = ref.watch(petControllerProvider);
    final petsList = petsState.value ?? [];

    final clinicName = clinicState.maybeWhen(
      data: (clinic) => clinic?.name ?? 'Klinik',
      orElse: () => 'Klinik',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      extendBody: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 120,
          top: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Klinik Paneli',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF006D33),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Merhaba $clinicName, bugünkü randevularınız aşağıdadır.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatusCards(appointmentState, petsList),
            const SizedBox(height: 24),
            _buildCalendarStrip(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, color: Color(0xFF006D33)),
                    const SizedBox(width: 8),
                    const Text(
                      'Randevu Listesi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/clinic-calendar'),
                  child: const Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      color: Color(0xFF006D33),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAppointmentList(appointmentState, petsList),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildGlassBottomNav(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
            child: const Icon(Icons.local_hospital, color: Colors.grey),
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
              onPressed: () => context.push('/notifications'),
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
    );
  }

  Widget _buildStatusCards(
    AsyncValue<List<Appointment>> state,
    List<Pet> petsList,
  ) {
    int total = 0;
    int cancelled = 0;
    Appointment? nextPatient;

    if (state.hasValue && state.value != null) {
      final now = DateTime.now(); // ŞU ANKİ ZAMANI AL

      final apps = state.value!
          .where(
            (a) =>
                a.startsAt.year == _selectedDate.year &&
                a.startsAt.month == _selectedDate.month &&
                a.startsAt.day == _selectedDate.day,
          )
          .toList();
      total = apps.length;
      cancelled = apps.where((a) => a.status == 'cancelled').length;

      // ÇÖZÜM: Sadece durumu uygun olanları değil, SAATİ DE ŞU ANDAN İLERİ OLANLARI filtrele!
      final pendingApps = apps
          .where(
            (a) =>
                (a.status == 'pending' || a.status == 'confirmed') &&
                a.startsAt.isAfter(now), // Sadece gelecekteki randevular
          )
          .toList();

      pendingApps.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      if (pendingApps.isNotEmpty) {
        nextPatient = pendingApps.first;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          Container(
            width: 250,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF006D33),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF006D33).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SIRADAKİ HASTA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Doğrudan global listeden okuyor, henüz inmemişse Yükleniyor diyor
                    nextPatient != null
                        ? Text(
                            petsList
                                .firstWhere(
                                  (p) => p.id == nextPatient!.petId,
                                  orElse: () => Pet(
                                    id: '',
                                    ownerId: '',
                                    name: 'Yükleniyor...',
                                    species: '',
                                    breed: '',
                                    birthDate: DateTime.now(),
                                    neutered: false,
                                  ),
                                )
                                .name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : const Text(
                            'Randevu Yok',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      nextPatient != null
                          ? '${nextPatient.type} • ${DateFormat('HH:mm').format(nextPatient.startsAt)}'
                          : '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    Icons.pets,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildSmallStatCard(
            total.toString(),
            'RANDEVU',
            const Color(0xFF006D33),
          ),
          const SizedBox(width: 16),
          _buildSmallStatCard(
            cancelled.toString(),
            'İPTAL',
            Colors.red.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String count, String label, Color countColor) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: countColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    final monthYear = DateFormat('MMMM yyyy', 'tr_TR').format(_selectedDate);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthYear,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () => setState(
                      () => _selectedDate = _selectedDate.subtract(
                        const Duration(days: 7),
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () => setState(
                      () => _selectedDate = _selectedDate.add(
                        const Duration(days: 7),
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final firstDayOfWeek = _selectedDate.subtract(
                Duration(days: _selectedDate.weekday - 1),
              );
              final currentDate = firstDayOfWeek.add(Duration(days: index));
              final isSelected =
                  currentDate.day == _selectedDate.day &&
                  currentDate.month == _selectedDate.month;
              final dayNames = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = currentDate),
                child: Column(
                  children: [
                    Text(
                      dayNames[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00FF7F)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: const Color(
                                  0xFF006D33,
                                ).withValues(alpha: 0.2),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          currentDate.day.toString(),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF007134)
                                : const Color(0xFF191C1E),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(
    AsyncValue<List<Appointment>> state,
    List<Pet> petsList,
  ) {
    return state.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Color(0xFF006D33)),
        ),
      ),
      error: (err, stack) => Center(child: Text('Hata: $err')),
      data: (allAppointments) {
        final appointments = allAppointments
            .where(
              (a) =>
                  a.startsAt.year == _selectedDate.year &&
                  a.startsAt.month == _selectedDate.month &&
                  a.startsAt.day == _selectedDate.day,
            )
            .toList();
        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                'Bu tarihte randevu bulunmuyor.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }
        final sortedApps = List<Appointment>.from(appointments)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

        return Column(
          children: sortedApps.map((appt) {
            final isCancelled = appt.status == 'cancelled';
            final isNext =
                appt.status == 'pending' && sortedApps.indexOf(appt) == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCancelled ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCancelled
                      ? Colors.grey.shade300
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(appt.startsAt),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isCancelled
                                ? Colors.grey.shade400
                                : const Color(0xFF191C1E),
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (isNext && !isCancelled) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'SIRADA',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006D33),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              petsList
                                  .firstWhere(
                                    (p) => p.id == appt.petId,
                                    orElse: () => Pet(
                                      id: '',
                                      ownerId: '',
                                      name: 'Yükleniyor...',
                                      species: '',
                                      breed: '',
                                      birthDate: DateTime.now(),
                                      neutered: false,
                                    ),
                                  )
                                  .name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: isCancelled
                                    ? Colors.grey.shade400
                                    : const Color(0xFF191C1E),
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (appt.type == 'Acil') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ACİL',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appt.type,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (String newStatus) => ref
                        .read(appointmentControllerProvider.notifier)
                        .updateAppointmentStatus(appt.id, newStatus),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'confirmed',
                        child: ListTile(
                          leading: Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          title: Text('Onayla'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'completed',
                        child: ListTile(
                          leading: Icon(Icons.done_all, color: Colors.blue),
                          title: Text('Tamamlandı İşaretle'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cancelled',
                        child: ListTile(
                          leading: Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                          title: Text('İptal Et'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
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
            '/clinic-home',
            isActive: true,
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
          _buildNavItem(
            context,
            Icons.chat_bubble_outline,
            'Mesajlar',
            '/clinic-messages',
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
