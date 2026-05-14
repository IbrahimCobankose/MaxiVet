import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Klasör yapına göre import yollarını teyit etmelisin
import '../../auth/controllers/auth_controller.dart';
import '../models/allergy_model.dart';
import '../controllers/allergy_controller.dart';
import '../../../core/providers/app_state_providers.dart';

class AllergyListView extends ConsumerStatefulWidget {
  const AllergyListView({super.key});

  @override
  ConsumerState<AllergyListView> createState() => _AllergyListViewState();
}

class _AllergyListViewState extends ConsumerState<AllergyListView> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Seçili hayvanın alerjilerini getir (Eğer hafızada yoksa)
      final petId = ref.read(selectedPetIdProvider);
      if (petId != null) {
        final currentAllergies = ref.read(allergyControllerProvider).value;
        if (currentAllergies == null ||
            currentAllergies.isEmpty ||
            currentAllergies.first.petId != petId) {
          ref
              .read(allergyControllerProvider.notifier)
              .fetchAllergiesByPet(petId);
        }
      }

      // 2. Kullanıcının rolünü sorgula
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        final role = await ref
            .read(authControllerProvider.notifier)
            .getUserRole(user.uid);
        if (mounted) {
          setState(() => _userRole = role);
        }
      }
    });
  }

  // Veteriner Hekimler İçin Yeni Alerji Ekleme Menüsü
  void _showAddAllergyDialog(BuildContext context, String petId) {
    final substanceController = TextEditingController();
    String selectedSeverity = 'Hafif'; // Varsayılan şiddet

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Yeni Alerji Kaydı',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Alerjen Madde
                  TextFormField(
                    controller: substanceController,
                    decoration: InputDecoration(
                      labelText: 'Alerjen Madde (Örn: Penisilin, Tavuk)',
                      prefixIcon: const Icon(Icons.warning_amber_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Şiddet Seviyesi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedSeverity,
                        icon: const Icon(Icons.expand_more),
                        items: ['Hafif', 'Orta', 'Şiddetli', 'Kritik'].map((
                          String level,
                        ) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: _getSeverityColor(level),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  level,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedSeverity = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kaydet Butonu
                  ElevatedButton(
                    onPressed: () async {
                      if (substanceController.text.trim().isEmpty) return;

                      final newAllergy = Allergy(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        petId: petId,
                        substance: substanceController.text.trim(),
                        severity: selectedSeverity,
                      );

                      try {
                        await ref
                            .read(allergyControllerProvider.notifier)
                            .addAllergy(newAllergy);
                        if (context.mounted) context.pop();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D33),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Alerjinin şiddetine göre renk döndüren metot
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'kritik':
      case 'şiddetli':
        return Colors.red.shade600;
      case 'orta':
        return Colors.orange.shade600;
      case 'hafif':
      default:
        return Colors.amber.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allergyState = ref.watch(allergyControllerProvider);
    final petId = ref.watch(selectedPetIdProvider);

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
          'Alerjiler',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: petId == null
          ? const Center(child: Text('Hayvan seçilmedi.'))
          : allergyState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D33)),
              ),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (allergies) {
                if (allergies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sisteme kayıtlı bir alerji bulunmuyor.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allergies.length,
                  itemBuilder: (context, index) {
                    final allergy = allergies[index];
                    final severityColor = _getSeverityColor(allergy.severity);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_rounded,
                            color: severityColor,
                          ),
                        ),
                        title: Text(
                          allergy.substance,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              'Şiddet: ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              allergy.severity.toUpperCase(),
                              style: TextStyle(
                                color: severityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        // Hekimlerin alerjiyi silmesi için buton eklenebilir (İlerleyen süreçte)
                      ),
                    );
                  },
                );
              },
            ),

      // Yalnızca 'clinic' rolündeki kullanıcılar için FloatingActionButton
      floatingActionButton: (_userRole == 'clinic' && petId != null)
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAllergyDialog(context, petId),
              backgroundColor: const Color(0xFF006D33),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Alerji Ekle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
