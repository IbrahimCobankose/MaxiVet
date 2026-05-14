import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/controllers/auth_controller.dart';
// ve muhtemelen 'vaccineNameController' falan için form lazım olacağından material'in altına:
import '../models/vaccination_model.dart';
import '../controllers/vaccination_controller.dart';
import '../../../core/providers/app_state_providers.dart';

class VaccinationListView extends ConsumerStatefulWidget {
  const VaccinationListView({super.key});

  @override
  ConsumerState<VaccinationListView> createState() =>
      _VaccinationListViewState();
}

class _VaccinationListViewState extends ConsumerState<VaccinationListView> {
  // YENİ: Kullanıcının rolünü tutacağımız değişken
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final petId = ref.read(selectedPetIdProvider);
      if (petId != null) {
        // Hafızada yoksa getir
        final currentVacs = ref.read(vaccinationControllerProvider).value;
        if (currentVacs == null ||
            currentVacs.isEmpty ||
            currentVacs.first.petId != petId) {
          ref
              .read(vaccinationControllerProvider.notifier)
              .fetchVaccinationsByPet(petId);
        }
      }

      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        final role = await ref
            .read(authControllerProvider.notifier)
            .getUserRole(user.uid);
        if (mounted) {
          setState(() {
            _userRole = role;
          });
        }
      }
    });
  }

  // Veteriner Hekimler İçin Yeni Aşı Ekleme Menüsü
  void _showAddVaccineDialog(
    BuildContext context,
    String petId,
    String clinicId,
  ) {
    final vaccineNameController = TextEditingController();

    // Tarihleri tutacağımız değişkenler
    DateTime appliedDate = DateTime.now(); // Varsayılan: Bugün
    DateTime? nextDueDate; // Opsiyonel (Null olabilir)

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavyenin formu yukarı itmesi için gerekli
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
            // Form uzarsa kaydırılabilmesi için ScrollView ekledik
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Yeni Aşı Kaydı',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Aşı Adı Alanı
                  TextFormField(
                    controller: vaccineNameController,
                    decoration: InputDecoration(
                      labelText: 'Aşı Adı (Örn: Karma Aşı)',
                      prefixIcon: const Icon(
                        Icons.vaccines_outlined,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF006D33),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Uygulama Tarihi Seçici (Geçmiş veya Bugün seçilebilir)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: appliedDate,
                        firstDate: DateTime(
                          2000,
                        ), // En eski 2000 yılına gidebilir
                        lastDate:
                            DateTime.now(), // Gelecek bir tarihte aşı yapılmış olamaz
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF006D33),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => appliedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Uygulama Tarihi',
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(appliedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Bir Sonraki Doz Tarihi Seçici (Sadece Gelecek zaman seçilebilir)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            nextDueDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(), // Geçmiş seçilemez
                        lastDate: DateTime(2035),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.orange,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => nextDueDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Gelecek Doz Tarihi (Opsiyonel)',
                        prefixIcon: const Icon(
                          Icons.update,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        // Tarih seçildiyse iptal etmek için (X) butonu göster
                        suffixIcon: nextDueDate != null
                            ? IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    setState(() => nextDueDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        nextDueDate != null
                            ? DateFormat('dd.MM.yyyy').format(nextDueDate!)
                            : 'Seçilmedi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: nextDueDate != null
                              ? Colors.orange.shade700
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kaydet Butonu
                  ElevatedButton(
                    onPressed: () async {
                      // Eğer aşı adı boşsa kaydetmeyi engelle
                      if (vaccineNameController.text.trim().isEmpty) return;

                      // Modeli oluştur
                      final newVaccine = Vaccination(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        petId: petId,
                        clinicId: clinicId, // Hekimin kendi ID'si
                        vaccineName: vaccineNameController.text.trim(),
                        appliedAt: appliedDate,
                        nextDueDate: nextDueDate, // Null olabilir, sorun yok
                      );

                      try {
                        await ref
                            .read(vaccinationControllerProvider.notifier)
                            .addVaccination(newVaccine);
                        if (context.mounted) context.pop(); // Formu kapat
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D33),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Aşıyı Kaydet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final vaccinationState = ref.watch(vaccinationControllerProvider);
    final petId = ref.watch(selectedPetIdProvider);
    final currentUser = ref.watch(authControllerProvider).value;
    // Sistemine göre rol tespiti değişebilir, basitçe veritabanından rolünü kontrol ettiğimizi varsayalım.
    // Şimdilik test için manuel bir değişken koyuyorum:
    final isClinic = true; // Gerçekte bunu AuthController'dan çekmelisin
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
          'Aşı Geçmişi',
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
          : vaccinationState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D33)),
              ),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (vaccinations) {
                if (vaccinations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vaccines_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Henüz aşı kaydı bulunmuyor.',
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
                  itemCount: vaccinations.length,
                  itemBuilder: (context, index) {
                    final vaccine = vaccinations[index];

                    // Aşının yapılıp yapılmadığını (tarihin geçip geçmediğini) kontrol ediyoruz
                    final isCompleted = vaccine.appliedAt.isBefore(
                      DateTime.now(),
                    );

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(
                                        0xFF006D33,
                                      ).withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.vaccines,
                                color: isCompleted
                                    ? const Color(0xFF006D33)
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vaccine.vaccineName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF191C1E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Uygulama: ${DateFormat('dd MMM yyyy', 'tr_TR').format(vaccine.appliedAt)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (vaccine.nextDueDate != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.update,
                                          size: 14,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Gelecek Doz: ${DateFormat('dd MMM yyyy', 'tr_TR').format(vaccine.nextDueDate!)}',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
      floatingActionButton: (_userRole == 'clinic' && petId != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                final user = ref.read(authControllerProvider).value;
                _showAddVaccineDialog(context, petId, user?.uid ?? '');
              },
              backgroundColor: const Color(0xFF006D33),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Aşı Ekle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null, // Eğer müşteri (pet_owner) girdiyse null döner, buton gizlenir.
    );
  }
}
