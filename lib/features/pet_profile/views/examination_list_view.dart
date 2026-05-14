import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/examination_model.dart';
import '../controllers/examination_controller.dart';
import '../../../core/providers/app_state_providers.dart';

class ExaminationListView extends ConsumerStatefulWidget {
  const ExaminationListView({super.key});

  @override
  ConsumerState<ExaminationListView> createState() =>
      _ExaminationListViewState();
}

class _ExaminationListViewState extends ConsumerState<ExaminationListView> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final petId = ref.read(selectedPetIdProvider);
      if (petId != null) {
        // Hafızada yoksa getir
        final currentExams = ref.read(examinationControllerProvider).value;
        if (currentExams == null ||
            currentExams.isEmpty ||
            currentExams.first.petId != petId) {
          ref
              .read(examinationControllerProvider.notifier)
              .fetchExaminationsByPet(petId);
        }
      }

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

  void _showAddExaminationDialog(
    BuildContext context,
    String petId,
    String clinicId,
  ) {
    final typeController = TextEditingController();
    final diagnosisController = TextEditingController();
    final treatmentPlanController = TextEditingController();
    DateTime examinedDate = DateTime.now();

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
                    'Yeni Muayene Kaydı',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: 'Muayene Türü (Örn: Genel Kontrol)',
                      prefixIcon: const Icon(Icons.medical_services_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: diagnosisController,
                    decoration: InputDecoration(
                      labelText: 'Teşhis (Opsiyonel)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: treatmentPlanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Tedavi Planı / Hekim Notları',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: examinedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => examinedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd.MM.yyyy').format(examinedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (typeController.text.trim().isEmpty) return;

                      final newExam = Examination(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        petId: petId,
                        clinicId: clinicId,
                        type: typeController.text.trim(),
                        diagnosis: diagnosisController.text.trim().isEmpty
                            ? null
                            : diagnosisController.text.trim(),
                        treatmentPlan:
                            treatmentPlanController.text.trim().isEmpty
                            ? null
                            : treatmentPlanController.text.trim(),
                        examinedAt: examinedDate,
                      );

                      try {
                        await ref
                            .read(examinationControllerProvider.notifier)
                            .addExamination(newExam);
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

  @override
  Widget build(BuildContext context) {
    final examinationState = ref.watch(examinationControllerProvider);
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
          'Muayene Geçmişi',
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
          : examinationState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D33)),
              ),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (examinations) {
                if (examinations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Henüz muayene kaydı bulunmuyor.',
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
                  itemCount: examinations.length,
                  itemBuilder: (context, index) {
                    final exam = examinations[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.medical_information,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exam.type,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF191C1E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat(
                                              'dd MMMM yyyy',
                                              'tr_TR',
                                            ).format(exam.examinedAt),
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (exam.diagnosis != null &&
                                exam.diagnosis!.isNotEmpty) ...[
                              Text(
                                'Teşhis',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                exam.diagnosis!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (exam.treatmentPlan != null &&
                                exam.treatmentPlan!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.healing,
                                          size: 16,
                                          color: Colors.grey.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Tedavi Planı:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      exam.treatmentPlan!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

      // GÜNCELLEME: Test edebilmen için rol kısıtlamasını "petId != null" olarak değiştirdim.
      // Her iki hesap türünde de görünecektir. Canlıya alırken yeniden _userRole == 'clinic' yapabiliriz.
      // YENİ (GÜVENLİ) HALİ: Sadece clinic rolü görebilir
      floatingActionButton: (_userRole == 'clinic' && petId != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                final user = ref.read(authControllerProvider).value;
                _showAddExaminationDialog(context, petId, user?.uid ?? '');
              },
              backgroundColor: const Color(0xFF006D33),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Muayene Ekle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
