import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../messaging/controllers/message_controller.dart';
// Klasör yapına uygun import yollarını teyit et
import '../../auth/controllers/auth_controller.dart'; // Çıkış işlemi için gerekli
import '../controllers/clinic_enrollment_controller.dart';
import '../controllers/pet_controller.dart';
import '../models/pet_model.dart';
import '../../../core/providers/app_state_providers.dart';

class ClinicPatientListView extends ConsumerStatefulWidget {
  const ClinicPatientListView({super.key});

  @override
  ConsumerState<ClinicPatientListView> createState() =>
      _ClinicPatientListViewState();
}

class _ClinicPatientListViewState extends ConsumerState<ClinicPatientListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, Pet> _petDetailsCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        // ÇÖZÜM: Hafızada kayıtlı hastalar zaten varsa tekrar Firebase'i yorma
        final currentEnrollments = ref
            .read(clinicEnrollmentControllerProvider)
            .value;
        if (currentEnrollments == null || currentEnrollments.isEmpty) {
          ref
              .read(clinicEnrollmentControllerProvider.notifier)
              .fetchEnrollmentsByClinic(user.uid);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentState = ref.watch(clinicEnrollmentControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D33),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Kayıtlı Hastalar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Arama Çubuğu (Search Bar)
          Container(
            color: const Color(0xFF006D33),
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 24,
              top: 8,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Hasta adı veya çip no ara...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF006D33),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Hastalar Listesi
          Expanded(
            child: enrollmentState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D33)),
              ),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (enrollments) {
                if (enrollments.isEmpty) {
                  return _buildEmptyState();
                }

                // Müşteri tarafındaki petController'ı buradan okuyoruz
                final allPets = ref.watch(petControllerProvider).value ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 120,
                  ),
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
                    final petId = enrollments[index].petId;

                    // MÜŞTERİ TARAFI GİBİ: Veriyi hafızadaki listeden anında bul
                    final pet = allPets.firstWhere(
                      (p) => p.id == petId,
                      orElse: () => Pet(
                        id: '',
                        ownerId: '',
                        name: 'Yükleniyor...',
                        species: '',
                        breed: '',
                        birthDate: DateTime.now(),
                        neutered: false,
                      ),
                    );

                    // Veri henüz gelmediyse veya arama kriterine uymuyorsa gösterme
                    if (pet.id.isEmpty) return const SizedBox.shrink();

                    if (_searchQuery.isNotEmpty &&
                        !pet.name.toLowerCase().contains(_searchQuery) &&
                        !(pet.microchipNo?.toLowerCase().contains(
                              _searchQuery,
                            ) ??
                            false)) {
                      return const SizedBox.shrink();
                    }

                    return _buildPatientCard(context, pet);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Klinik alt menüsü
      bottomNavigationBar: _buildGlassBottomNav(context),
    );
  }

  // Hasta Kartı Tasarımı
  Widget _buildPatientCard(BuildContext context, Pet pet) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Hekim hastaya tıkladığında global state'i güncelliyoruz
          ref.read(selectedPetIdProvider.notifier).setPetId(pet.id);
          // Hastanın Dijital Karnesine yönlendiriyoruz
          context.push('/pet-detail');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF006D33).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006D33),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        if (pet.microchipNo != null &&
                            pet.microchipNo!.isNotEmpty)
                          const Icon(
                            Icons.memory,
                            size: 16,
                            color: Colors.blueGrey,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.species} • ${pet.breed}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Kısırlaştırma veya Kan Grubu gibi küçük bir etiket
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pet.neutered ? 'Kısırlaştırılmış' : 'Kısır Değil',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Kliniğe kayıtlı hasta bulunmuyor.',
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
          // HASTALAR SAYFASINDA OLDUĞUMUZ İÇİN BURASI TRUE!
          _buildNavItem(
            context,
            Icons.people_alt,
            'Hastalar',
            '/clinic-patients',
            isActive: true,
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
