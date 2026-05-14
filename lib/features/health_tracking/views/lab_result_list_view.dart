import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/lab_result_controller.dart';
import '../models/lab_result_model.dart';
import '../../../core/providers/app_state_providers.dart';

class LabResultListView extends ConsumerStatefulWidget {
  const LabResultListView({super.key});

  @override
  ConsumerState<LabResultListView> createState() => _LabResultListViewState();
}

class _LabResultListViewState extends ConsumerState<LabResultListView> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final petId = ref.read(selectedPetIdProvider);
      if (petId != null) {
        // Hafızada yoksa getir
        final currentLabs = ref.read(labResultControllerProvider).value;
        if (currentLabs == null ||
            currentLabs.isEmpty ||
            currentLabs.first.petId != petId) {
          ref
              .read(labResultControllerProvider.notifier)
              .fetchLabResultsByPet(petId);
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'yüksek':
        return Colors.red.shade600;
      case 'low':
      case 'düşük':
        return Colors.orange.shade600;
      case 'normal':
      default:
        return const Color(0xFF006D33);
    }
  }

  // 1. KÜÇÜK PENCERE: Tek bir değer/parametre ekleme
  void _showAddParameterDialog(
    BuildContext context,
    Function(LabValue) onValueAdded,
  ) {
    final paramController = TextEditingController();
    final valueController = TextEditingController();
    final unitController = TextEditingController();
    final minController = TextEditingController();
    final maxController = TextEditingController();
    String selectedStatus = 'Normal';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Değer Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: paramController,
                decoration: const InputDecoration(
                  labelText: 'Parametre (Örn: WBC)',
                ),
              ),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Değer'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Birim (Örn: mg/dL)',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      decoration: const InputDecoration(labelText: 'Min'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      decoration: const InputDecoration(labelText: 'Max'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: ['Normal', 'High', 'Low']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => selectedStatus = v!,
                decoration: const InputDecoration(labelText: 'Durum'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (paramController.text.isEmpty || valueController.text.isEmpty)
                return;

              final newValue = LabValue(
                parameter: paramController.text.trim(),
                value: double.tryParse(valueController.text) ?? 0.0,
                unit: unitController.text.trim(),
                refMin: double.tryParse(minController.text) ?? 0.0,
                refMax: double.tryParse(maxController.text) ?? 0.0,
                status: selectedStatus,
              );
              onValueAdded(newValue);
              context.pop();
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  // 2. BÜYÜK PENCERE: Ana Tahlil Formu
  void _showAddLabResultDialog(
    BuildContext context,
    String petId,
    String clinicId,
  ) {
    final panelTypeController = TextEditingController();
    DateTime resultDate = DateTime.now();
    List<LabValue> tempValues = [];

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
                    'Yeni Tahlil Sonucu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: panelTypeController,
                    decoration: InputDecoration(
                      labelText: 'Tahlil Paneli (Örn: Hemogram)',
                      prefixIcon: const Icon(Icons.analytics),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: resultDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => resultDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tarih',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(DateFormat('dd.MM.yyyy').format(resultDate)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Tahlil Değerleri',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ...tempValues.map(
                    (v) => ListTile(
                      title: Text(v.parameter),
                      trailing: Text('${v.value} ${v.unit}'),
                      subtitle: Text('Durum: ${v.status}'),
                    ),
                  ),

                  TextButton.icon(
                    onPressed: () {
                      _showAddParameterDialog(context, (newLabValue) {
                        setState(() {
                          tempValues.add(newLabValue);
                        });
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Yeni Değer/Parametre Ekle'),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (panelTypeController.text.isEmpty) return;

                      final newResult = LabResult(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        petId: petId,
                        clinicId: clinicId,
                        panelType: panelTypeController.text.trim(),
                        resultDate: resultDate,
                        values: tempValues,
                      );

                      try {
                        await ref
                            .read(labResultControllerProvider.notifier)
                            .addLabResult(newResult);
                        if (context.mounted) context.pop();
                      } catch (e) {
                        // Hata
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D33),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Tahlili Kaydet',
                      style: TextStyle(
                        color: Colors.white,
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
    final labResultState = ref.watch(labResultControllerProvider);
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
          'Tahlil Sonuçları',
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
          : labResultState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D33)),
              ),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (results) {
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Henüz laboratuvar sonucu bulunmuyor.',
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
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: ExpansionTile(
                        shape: const Border(),
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF006D33,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.biotech,
                            color: Color(0xFF006D33),
                          ),
                        ),
                        title: Text(
                          result.panelType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'dd MMMM yyyy',
                            'tr_TR',
                          ).format(result.resultDate),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        children: [
                          const Divider(height: 1),
                          if (result.values.isNotEmpty)
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: result.values.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (context, valIndex) {
                                final labValue = result.values[valIndex];
                                final statusColor = _getStatusColor(
                                  labValue.status,
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              labValue.parameter,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Ref: ${labValue.refMin} - ${labValue.refMax}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${labValue.value} ${labValue.unit}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        labValue.status.toLowerCase() ==
                                                    'high' ||
                                                labValue.status.toLowerCase() ==
                                                    'yüksek'
                                            ? Icons.arrow_upward
                                            : labValue.status.toLowerCase() ==
                                                      'low' ||
                                                  labValue.status
                                                          .toLowerCase() ==
                                                      'düşük'
                                            ? Icons.arrow_downward
                                            : Icons.check_circle,
                                        color: statusColor,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      // 3. SADECE HEKİMLERİN GÖRECEĞİ BUTON
      floatingActionButton: (_userRole == 'clinic' && petId != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                final user = ref.read(authControllerProvider).value;
                _showAddLabResultDialog(context, petId, user?.uid ?? '');
              },
              backgroundColor: const Color(0xFF006D33),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Tahlil Ekle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
