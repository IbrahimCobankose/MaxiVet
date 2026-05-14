import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/notification_controller.dart';

class NotificationView extends ConsumerWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controller'daki bildirim listesini anlık dinliyoruz
    final notificationState = ref.watch(notificationControllerProvider);

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
          'Bildirimler',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: notificationState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF006D33)),
        ),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz bir bildiriminiz yok.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              // Bildirim tipine göre ikon ve renk belirliyoruz
              IconData icon;
              Color iconColor;

              switch (notification.type) {
                case 'vaccination':
                  icon = Icons.vaccines;
                  iconColor = Colors.blue;
                  break;
                case 'appointment':
                  icon = Icons.calendar_month;
                  iconColor = Colors.orange;
                  break;
                default:
                  icon = Icons.info_outline;
                  iconColor = const Color(0xFF006D33);
              }

              // Modeldeki 'sent' alanı bizim için 'okundu' (isRead) anlamına gelecek
              final isUnread = !notification.sent;

              return GestureDetector(
                onTap: () {
                  // Eğer okunmadıysa, tıklandığında okundu olarak işaretle
                  if (isUnread) {
                    ref
                        .read(notificationControllerProvider.notifier)
                        .markNotificationAsSent(notification.id);
                  }
                  // Gelecekte: Bildirim tipine göre detay sayfasına da yönlendirebiliriz.
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnread ? Colors.white : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUnread
                          ? const Color(0xFF006D33).withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1.5,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: isUnread
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 16,
                                      color: const Color(0xFF191C1E),
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification.content,
                              style: TextStyle(
                                fontSize: 13,
                                color: isUnread
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'dd MMM HH:mm',
                                'tr_TR',
                              ).format(notification.scheduledAt),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
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
    );
  }
}
