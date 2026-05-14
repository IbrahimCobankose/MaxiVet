import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/appointment_controller.dart';
import '../../messaging/controllers/message_controller.dart';
import '../models/appointment_model.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../pet_profile/models/pet_model.dart';

class ClinicCalendarView extends ConsumerStatefulWidget {
  const ClinicCalendarView({super.key});

  @override
  ConsumerState<ClinicCalendarView> createState() => _ClinicCalendarViewState();
}

class _ClinicCalendarViewState extends ConsumerState<ClinicCalendarView> {
  DateTime _selectedDate = DateTime.now();
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _generateWeekDays(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        // ÇÖZÜM: Tüm randevuları (tarih kısıtlaması olmadan) SADECE BİR KERE çek
        final currentApps = ref.read(appointmentControllerProvider).value;
        if (currentApps == null || currentApps.isEmpty) {
          ref
              .read(appointmentControllerProvider.notifier)
              .fetchAppointmentsByClinic(user.uid);
        }
      }
    });
  }

  void _generateWeekDays(DateTime date) {
    int currentWeekday = date.weekday;
    DateTime firstDayOfWeek = date.subtract(Duration(days: currentWeekday - 1));
    _weekDays = List.generate(
      7,
      (index) => firstDayOfWeek.add(Duration(days: index)),
    );
  }

  void _changeDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _generateWeekDays(_selectedDate);
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green.shade600;
      case 'completed':
        return Colors.blue.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      case 'pending':
      default:
        return Colors.orange.shade600;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Onaylandı';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      case 'pending':
      default:
        return 'Bekliyor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentState = ref.watch(appointmentControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D33),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Klinik Takvimi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // ÜST TAKVİM ŞERİDİ
          Container(
            color: const Color(0xFF006D33),
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => _changeDate(
                        _selectedDate.subtract(const Duration(days: 7)),
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMMM yyyy',
                        'tr_TR',
                      ).format(_selectedDate).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: () => _changeDate(
                        _selectedDate.add(const Duration(days: 7)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekDays.map((date) {
                    final isSelected =
                        date.day == _selectedDate.day &&
                        date.month == _selectedDate.month;
                    final dayName = DateFormat('E', 'tr_TR').format(date);

                    return GestureDetector(
                      onTap: () => _changeDate(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00FF7F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00FF7F,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF006D33)
                                    : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? const Color(0xFF006D33)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // RANDEVULAR LİSTESİ
          Expanded(
            child: appointmentState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D33)),
              ),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              // ÇÖZÜM: 'allAppointments' olarak isimlendirdik ki aşağıdaki filtrelemede çakışmasın
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
                  return _buildEmptyState();
                }

                final sortedApps = List<Appointment>.from(appointments)
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 120,
                  ),
                  itemCount: sortedApps.length,
                  itemBuilder: (context, index) {
                    final appt = sortedApps[index];
                    final statusColor = _getStatusColor(appt.status);
                    final isCancelled = appt.status == 'cancelled';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(width: 6, color: statusColor),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'HH:mm',
                                          ).format(appt.startsAt),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF191C1E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getStatusText(
                                            appt.status,
                                          ).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      width: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // KUSURSUZ GEÇİŞ: Doğrudan Global State'ten oku
                                          Text(
                                            (ref
                                                        .watch(
                                                          petControllerProvider,
                                                        )
                                                        .value ??
                                                    [])
                                                .firstWhere(
                                                  (p) => p.id == appt.petId,
                                                  orElse: () => Pet(
                                                    id: '',
                                                    ownerId: '',
                                                    name: 'Hasta',
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
                                          const SizedBox(height: 4),
                                          Text(
                                            appt.type,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (appt.reason != null &&
                                              appt.reason!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Not: ${appt.reason}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.grey,
                                      ),
                                      onSelected: (String newStatus) {
                                        ref
                                            .read(
                                              appointmentControllerProvider
                                                  .notifier,
                                            )
                                            .updateAppointmentStatus(
                                              appt.id,
                                              newStatus,
                                            );
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
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
                                            const PopupMenuItem<String>(
                                              value: 'completed',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.done_all,
                                                  color: Colors.blue,
                                                ),
                                                title: Text(
                                                  'Tamamlandı İşaretle',
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Bu tarihte planlı bir randevu bulunmuyor.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
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
            Icons.calendar_month,
            'Takvim',
            '/clinic-calendar',
            isActive: true,
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
