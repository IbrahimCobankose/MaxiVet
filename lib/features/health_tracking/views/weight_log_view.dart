import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// YENİ EKLENEN IMPORT
import '../../auth/controllers/auth_controller.dart';

import '../controllers/weight_log_controller.dart';
import '../models/weight_log_model.dart';
import '../../../core/providers/app_state_providers.dart';

class WeightLogView extends ConsumerStatefulWidget {
  const WeightLogView({super.key});

  @override
  ConsumerState<WeightLogView> createState() => _WeightLogViewState();
}

class _WeightLogViewState extends ConsumerState<WeightLogView> {
  // YENİ: Kullanıcı rolünü saklamak için değişken
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final petId = ref.read(selectedPetIdProvider);
      if (petId != null) {
        // Hafızada yoksa getir
        final currentWeights = ref.read(weightLogControllerProvider).value;
        if (currentWeights == null ||
            currentWeights.isEmpty ||
            currentWeights.first.petId != petId) {
          ref
              .read(weightLogControllerProvider.notifier)
              .fetchWeightLogsByPet(petId);
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

  // Yeni kilo eklemek için alttan açılan pencere (Bottom Sheet)
  void _showAddWeightDialog(BuildContext context, String petId) {
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavyenin pencereyi yukarı itmesi için
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Yeni Kilo Girişi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 24),

                // Kilo Input Alanı
                TextFormField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kilo (kg)',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
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

                // Tarih Seçimi
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
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
                      setState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tarih',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      DateFormat('dd.MM.yyyy').format(selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Kaydet Butonu
                ElevatedButton(
                  onPressed: () async {
                    if (weightController.text.isEmpty) return;

                    final double? weight = double.tryParse(
                      weightController.text.replaceAll(',', '.'),
                    );
                    if (weight == null) return;

                    final newLog = WeightLog(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      petId: petId,
                      weightKg: weight,
                      measuredAt: selectedDate,
                    );
                    try {
                      await ref
                          .read(weightLogControllerProvider.notifier)
                          .addWeightLog(newLog);
                      if (context.mounted) {
                        context.pop(); // Bottom sheet'i kapat
                      }
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
                    'Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weightState = ref.watch(weightLogControllerProvider);
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
          'Kilo Takibi',
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
          : weightState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D33)),
              ),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monitor_weight_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Henüz kilo kaydı bulunmuyor.',
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

                // En son eklenen en üstte olacak şekilde listede gösteriyoruz
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];

                    // Önceki ölçümle farkı bulmak için (Opsiyonel görselleştirme)
                    double? difference;
                    if (index < logs.length - 1) {
                      difference = log.weightKg - logs[index + 1].weightKg;
                    }

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
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF006D33,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monitor_weight,
                            color: Color(0xFF006D33),
                          ),
                        ),
                        title: Text(
                          '${log.weightKg.toStringAsFixed(2)} kg',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'dd MMMM yyyy',
                            'tr_TR',
                          ).format(log.measuredAt),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: difference != null && difference != 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    difference > 0
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: difference > 0
                                        ? Colors.red.shade400
                                        : Colors.green.shade400,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${difference.abs().toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      color: difference > 0
                                          ? Colors.red.shade400
                                          : Colors.green.shade400,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),

      // YENİ EKLENEN: Yalnızca 'clinic' rolündeki kullanıcılar için FloatingActionButton
      floatingActionButton: (_userRole == 'clinic' && petId != null)
          ? FloatingActionButton.extended(
              onPressed: () => _showAddWeightDialog(context, petId),
              backgroundColor: const Color(0xFF006D33),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Kilo Ekle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
