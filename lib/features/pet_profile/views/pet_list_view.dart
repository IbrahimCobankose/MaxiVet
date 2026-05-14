import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../messaging/controllers/message_controller.dart';
// İlgili controller ve modelleri içeri aktarıyoruz
import '../../auth/controllers/auth_controller.dart'; // Eğer eksikse ekle
import '../controllers/pet_controller.dart';
import '../models/pet_model.dart';
import '../../../core/providers/app_state_providers.dart';

class PetListView extends ConsumerStatefulWidget {
  const PetListView({super.key});

  @override
  ConsumerState<PetListView> createState() => _PetListViewState();
}

class _PetListViewState extends ConsumerState<PetListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        // Eğer hafızada hayvanlar zaten varsa tekrar çekme!
        final currentPets = ref.read(petControllerProvider).value;
        if (currentPets == null || currentPets.isEmpty) {
          ref.read(petControllerProvider.notifier).fetchPetsByOwner(user.uid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petsState = ref.watch(petControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB), // surface-bright rengi
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Dostlarım',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Gelecekte bildirimler sayfasına yönlendirecek
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF191C1E),
            ),
          ),
        ],
      ),
      // Altta havada duran navigasyon barını engellememesi için listeyi biraz yukarıda bitiriyoruz
      extendBody: true,
      body: petsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF006D33)),
        ),
        error: (error, stack) => Center(
          child: Text('Bir hata oluştu:\n$error', textAlign: TextAlign.center),
        ),
        data: (pets) {
          if (pets.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildPetList(pets);
        },
      ),
      bottomNavigationBar: _buildGlassBottomNav(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Firebase bağlandığında GoRouter ile hayvan ekleme sayfasına yönlendireceğiz
          context.push('/add-pet');
        },
        backgroundColor: const Color(0xFF006D33),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Yeni Dost Ekle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // Butonu navigasyon barının üstüne hizalıyoruz
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Hayvan yoksa gösterilecek boş durum tasarımı
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF006D33).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, size: 64, color: Color(0xFF006D33)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz bir dost eklemediniz.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sağ alt köşedeki butona tıklayarak ilk tüylü dostunuzun profilini oluşturabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Hayvanlar varsa gösterilecek liste
  Widget _buildPetList(List<Pet> pets) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100,
      ), // Alt boşluk nav bar için
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Tıklanan hayvanı global state'e (Notifier) kaydediyoruz
              ref.read(selectedPetIdProvider.notifier).setPetId(pet.id);
              // Seçilen hayvanın detay (Dijital Karne) sayfasına yönlendirme yapılacak
              context.push('/pet-detail');
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(
                      0xFF006D33,
                    ).withValues(alpha: 0.1),
                    child: Text(
                      pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006D33),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pet.species} • ${pet.breed}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassBottomNav(BuildContext context) {
    // Rozet için sayacı dinliyoruz
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
          // DOSTLARIM SAYFASINDA OLDUĞUMUZ İÇİN BURASI TRUE!
          _buildNavItem(
            context,
            Icons.pets,
            'Dostlarım',
            '/pets',
            isActive: true,
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
