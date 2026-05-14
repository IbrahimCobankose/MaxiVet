import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../controllers/med_reminder_controller.dart';
import '../models/med_reminder_model.dart';
import '../../../core/providers/app_state_providers.dart';
// Hayvanları çekmek için ekledik
import '../../pet_profile/controllers/pet_controller.dart';

class MedReminderListView extends ConsumerStatefulWidget {
  const MedReminderListView({super.key});

  @override
  ConsumerState<MedReminderListView> createState() =>
      _MedReminderListViewState();
}

class _MedReminderListViewState extends ConsumerState<MedReminderListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petId = ref.read(selectedPetIdProvider);
      if (petId != null) {
        ref
            .read(medReminderControllerProvider.notifier)
            .fetchAllMedReminders(petId);
      }
    });
  }

  // Yeni İlaç Eklemek İçin Bottom Sheet Formu (Tarih Seçiciler Eklendi)
  void _showAddReminderDialog(BuildContext context, String petId) {
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();

    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

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
                    'Yeni İlaç Hatırlatıcısı',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: medicineController,
                    decoration: InputDecoration(
                      labelText: 'İlaç Adı (Örn: Synulox)',
                      prefixIcon: const Icon(Icons.medication_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dosageController,
                          decoration: InputDecoration(
                            labelText: 'Dozaj (Örn: 1 Tablet)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: frequencyController,
                          decoration: InputDecoration(
                            labelText: 'Sıklık (Örn: Günde 2 Kez)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // TARIH VE SAAT SEÇİCİLER (YENİ KISIM)
                  Row(
                    children: [
                      // Başlangıç Tarihi
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null)
                              setState(() => startDate = pickedDate);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Başlangıç',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              DateFormat(
                                'dd MMM yyyy',
                                'tr_TR',
                              ).format(startDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Bitiş Tarihi
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null)
                              setState(() => endDate = pickedDate);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Bitiş',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              DateFormat(
                                'dd MMM yyyy',
                                'tr_TR',
                              ).format(endDate),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() => selectedTime = pickedTime);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Alarm Saati',
                        prefixIcon: const Icon(Icons.alarm),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (medicineController.text.trim().isEmpty) return;

                      final newReminder = MedReminder(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        petId: petId,
                        medicine: medicineController.text.trim(),
                        dosage: dosageController.text.trim(),
                        frequency: frequencyController.text.trim(),
                        alarmTime:
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        active: true,
                        startDate: startDate,
                        endDate: endDate,
                      );

                      try {
                        await ref
                            .read(medReminderControllerProvider.notifier)
                            .addMedReminder(newReminder);
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
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Hatırlatıcı Oluştur',
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
    final reminderState = ref.watch(medReminderControllerProvider);
    var selectedPetId = ref.watch(selectedPetIdProvider);
    final petsState = ref.watch(petControllerProvider);

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
          'İlaç Hatırlatıcıları',
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
          // HAYVAN SEÇİM DROPDOWN'I (YENİ EKLENDİ)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: petsState.when(
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (err, stack) => Text('Hayvanlar yüklenemedi: $err'),
              data: (pets) {
                if (pets.isEmpty) {
                  return const Text('Henüz eklenmiş bir hayvanınız yok.');
                }

                // Eğer seçili bir pet yoksa, listedeki ilk peti varsayılan yap
                if (selectedPetId == null ||
                    !pets.any((p) => p.id == selectedPetId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(selectedPetIdProvider.notifier)
                        .setPetId(pets.first.id);
                    ref
                        .read(medReminderControllerProvider.notifier)
                        .fetchAllMedReminders(pets.first.id);
                  });
                  return const Center(child: CircularProgressIndicator());
                }

                return DropdownButtonFormField<String>(
                  value: selectedPetId,
                  decoration: InputDecoration(
                    labelText: 'İşlem Yapılacak Dostunuz',
                    prefixIcon: const Icon(
                      Icons.pets,
                      color: Color(0xFF006D33),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: pets.map((pet) {
                    return DropdownMenuItem(
                      value: pet.id,
                      child: Text(pet.name),
                    );
                  }).toList(),
                  onChanged: (String? newPetId) {
                    if (newPetId != null) {
                      ref
                          .read(selectedPetIdProvider.notifier)
                          .setPetId(newPetId);
                      ref
                          .read(medReminderControllerProvider.notifier)
                          .fetchAllMedReminders(newPetId);
                    }
                  },
                );
              },
            ),
          ),

          // İLAÇ LİSTESİ
          Expanded(
            child: selectedPetId == null
                ? const SizedBox.shrink()
                : reminderState.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006D33),
                      ),
                    ),
                    error: (err, stack) => Center(child: Text('Hata: $err')),
                    data: (reminderMap) {
                      // ÇÖZÜM: State artık bir Map. Seçili hayvanın listesini alıyoruz.
                      final reminders = reminderMap[selectedPetId] ?? [];

                      if (reminders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medication,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Aktif ilaç hatırlatıcısı bulunmuyor.',
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
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = reminders[index];

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
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
                                      color: reminder.active
                                          ? const Color(
                                              0xFF006D33,
                                            ).withValues(alpha: 0.1)
                                          : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.medication_liquid,
                                      color: reminder.active
                                          ? const Color(0xFF006D33)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              reminder.medicine,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: reminder.active
                                                    ? const Color(0xFF191C1E)
                                                    : Colors.grey.shade500,
                                              ),
                                            ),
                                            Switch(
                                              value: reminder.active,
                                              activeThumbColor: const Color(
                                                0xFF006D33,
                                              ),
                                              onChanged: (bool value) {
                                                ref
                                                    .read(
                                                      medReminderControllerProvider
                                                          .notifier,
                                                    )
                                                    // Yeni controller'da petId parametresi eklendi
                                                    .toggleReminderStatus(
                                                      reminder.id,
                                                      reminder.petId,
                                                      value,
                                                    );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${reminder.dosage} • ${reminder.frequency}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.alarm,
                                              size: 16,
                                              color: reminder.active
                                                  ? Colors.orange.shade600
                                                  : Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              reminder.alarmTime,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: reminder.active
                                                    ? Colors.orange.shade700
                                                    : Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Bitiş: ${DateFormat('dd MMM yyyy', 'tr_TR').format(reminder.endDate)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
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
          ),
        ],
      ),
      floatingActionButton: selectedPetId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddReminderDialog(context, selectedPetId),
              backgroundColor: const Color(0xFF006D33),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Yeni İlaç',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
