import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/pet_controller.dart';
import '../../../core/providers/app_state_providers.dart';
import '../models/pet_model.dart';

class PetDetailView extends ConsumerStatefulWidget {
  const PetDetailView({super.key});

  @override
  ConsumerState<PetDetailView> createState() => _PetDetailViewState();
}

class _PetDetailViewState extends ConsumerState<PetDetailView> {
  // Yaş hesaplama yardımcı metodu
  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    if (age <= 0) {
      final months = now.difference(birthDate).inDays ~/ 30;
      return '$months Aylık';
    }
    return '$age Yaşında';
  }

  @override
  Widget build(BuildContext context) {
    final selectedPetId = ref.watch(selectedPetIdProvider);

    // ÇÖZÜMÜN KALBİ: Önce uygulamanın o anki RAM'ine (State) bakıyoruz
    final petsList = ref.watch(petControllerProvider).value ?? [];

    // Seçili hayvan hafızada (müşterinin kendi listesinde) zaten var mı?
    Pet? existingPet;
    try {
      existingPet = petsList.firstWhere((p) => p.id == selectedPetId);
    } catch (e) {
      existingPet = null; // Listede bulamazsa null atar
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D33),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Dijital Sağlık Kartı',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: selectedPetId == null
          ? const Center(child: Text('Hayvan seçilmedi.'))
          : existingPet != null
          // 1. İHTİMAL (ŞİMŞEK HIZI): Hayvan hafızada varsa hiç beklemeden anında çiz!
          ? _buildProfileBody(existingPet)
          // 2. İHTİMAL (GÜVENLİ LİMAN): Hayvan hafızada yoksa (Klinik giriyorsa) Firebase'den çek!
          : FutureBuilder<Pet?>(
              future: ref
                  .read(petControllerProvider.notifier)
                  .getPetDetails(selectedPetId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF006D33)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata oluştu: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('Hayvan bilgisi bulunamadı.'),
                  );
                }
                return _buildProfileBody(snapshot.data!);
              },
            ),
    );
  }

  // Arayüz kalabalığını önlemek için detayları ayrı bir metoda (Gövde) çıkardık
  Widget _buildProfileBody(Pet pet) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ÜST BİLGİ KARTI
          Container(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 32,
              top: 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF006D33),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Text(
                    pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006D33),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pet.species} • ${pet.breed} • ${_calculateAge(pet.birthDate)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // KÜNYE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Çip No',
                    pet.microchipNo ?? 'Yok',
                    Icons.memory,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    'Kan Grubu',
                    pet.bloodType ?? 'Bilinmiyor',
                    Icons.bloodtype_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // MODÜLLER
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Sağlık Modülleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildModuleCard(
                context,
                title: 'Kilo Takibi',
                icon: Icons.monitor_weight_outlined,
                color: Colors.blue.shade400,
                onTap: () => context.push('/weight-log'),
              ),
              _buildModuleCard(
                context,
                title: 'Aşı Geçmişi',
                icon: Icons.vaccines_outlined,
                color: Colors.teal.shade400,
                onTap: () => context.push('/vaccinations'),
              ),
              _buildModuleCard(
                context,
                title: 'Tahliller',
                icon: Icons.science_outlined,
                color: Colors.purple.shade400,
                onTap: () => context.push('/lab-results'),
              ),
              _buildModuleCard(
                context,
                title: 'Muayeneler',
                icon: Icons.history_edu_outlined,
                color: Colors.orange.shade400,
                onTap: () => context.push('/examinations'),
              ),
              _buildModuleCard(
                context,
                title: 'Operasyonlar',
                icon: Icons.healing_outlined,
                color: Colors.red.shade400,
                onTap: () => context.push('/operations'),
              ),
              _buildModuleCard(
                context,
                title: 'Alerjiler',
                icon: Icons.warning_amber_rounded,
                color: Colors.amber.shade600,
                onTap: () => context.push('/allergies'),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191C1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
