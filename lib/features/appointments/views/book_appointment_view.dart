import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../controllers/appointment_controller.dart';
import '../models/appointment_model.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../pet_profile/models/pet_model.dart';
import '../../pet_profile/controllers/clinic_enrollment_controller.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/controllers/auth_controller.dart';

class BookAppointmentView extends ConsumerStatefulWidget {
  const BookAppointmentView({super.key});

  @override
  ConsumerState<BookAppointmentView> createState() =>
      _BookAppointmentViewState();
}

class _BookAppointmentViewState extends ConsumerState<BookAppointmentView> {
  // Seçim Durumları
  String? _selectedPetId;
  String? _selectedClinicId;
  String _selectedService = 'Genel Muayene';
  String _selectedDoctor = 'Herhangi Biri';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  final TextEditingController _notesController = TextEditingController();

  // Saatleri kontrol etmek için yerel durumlar
  bool _isLoadingSlots = false;
  List<Appointment> _bookedAppointments = [];

  // YENİ: Klinikleri yavaşlatan FutureBuilder yerine basit bir önbellek (Cache) kullanıyoruz
  final Map<String, String> _clinicNamesCache = {};

  // Seçenek Listeleri
  final List<String> _services = [
    'Genel Muayene',
    'Aşı Takvimi',
    'Diş Bakımı',
    'Cerrahi İşlem',
  ];
  final List<String> _doctors = [
    'Dr. Elif Yılmaz',
    'Dr. Can Demir',
    'Herhangi Biri',
  ];

  late final List<DateTime> _upcomingDays;

  final List<TimeOfDay> _timeSlots = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 9, minute: 30),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 10, minute: 30),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 11, minute: 30),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 14, minute: 30),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 15, minute: 30),
  ];

  @override
  void initState() {
    super.initState();
    _upcomingDays = List.generate(
      14,
      (index) => DateTime.now().add(Duration(days: index)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;

      if (user != null) {
        // ÇÖZÜM: Hafızada hayvanlar varsa tekrar çekme!
        final currentPets = ref.read(petControllerProvider).value;
        if (currentPets == null || currentPets.isEmpty) {
          ref.read(petControllerProvider.notifier).fetchPetsByOwner(user.uid);
        }

        _selectedPetId = ref.read(selectedPetIdProvider);
        if (_selectedPetId != null) {
          ref
              .read(clinicEnrollmentControllerProvider.notifier)
              .fetchEnrollmentsByPet(_selectedPetId!);
        }
      }
      setState(() {});
    });
  }

  // YENİ: Kliniğin adını hafızaya alan fonksiyon
  Future<void> _fetchClinicNameIfNeeded(String clinicId) async {
    if (!_clinicNamesCache.containsKey(clinicId)) {
      final clinic = await ref
          .read(clinicRepositoryProvider)
          .getClinicById(clinicId);
      if (mounted && clinic != null) {
        setState(() {
          _clinicNamesCache[clinicId] = clinic.name;
        });
      }
    }
  }

  // Seçili klinik ve tarihe göre dolu saatleri Firebase'den anlık çeker
  Future<void> _fetchBookedSlots() async {
    if (_selectedClinicId == null) return;

    setState(() => _isLoadingSlots = true);
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final apps = await repo.getAppointmentsByClinicId(
        _selectedClinicId!,
        date: _selectedDate,
      );
      if (mounted) {
        setState(() {
          _bookedAppointments = apps;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Randevu Oluştur',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dostunuz için en uygun zamanı seçin.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(Icons.pets, 'Dostunuzu Seçin'),
            const SizedBox(height: 12),
            _buildPetSelection(),
            const SizedBox(height: 32),

            _buildSectionTitle(Icons.local_hospital, 'Klinik Seçin'),
            const SizedBox(height: 12),
            _buildClinicSelection(),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Hizmet Türü',
                    Icons.medical_services,
                    _services,
                    _selectedService,
                    (val) => setState(() => _selectedService = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Veteriner',
                    Icons.health_and_safety,
                    _doctors,
                    _selectedDoctor,
                    (val) => setState(() => _selectedDoctor = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Not ekleyin (opsiyonel)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'tr_TR').format(_selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _upcomingDays.length,
                      itemBuilder: (context, index) {
                        final date = _upcomingDays[index];
                        final isSelected =
                            date.day == _selectedDate.day &&
                            date.month == _selectedDate.month;
                        final dayName = DateFormat('E', 'tr_TR').format(date);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                              _selectedTime = null;
                            });
                            _fetchBookedSlots();
                          },
                          child: Container(
                            width: 50,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF006D33)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF191C1E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saat Seçimi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoadingSlots)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF006D33),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            _selectedClinicId == null
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Saatleri görmek için lütfen önce kayıtlı olduğunuz kliniği seçin.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final time = _timeSlots[index];

                      final isBooked = _bookedAppointments.any(
                        (appt) =>
                            appt.status != 'cancelled' &&
                            appt.startsAt.hour == time.hour &&
                            appt.startsAt.minute == time.minute,
                      );

                      final now = DateTime.now();
                      final isPast =
                          _selectedDate.year == now.year &&
                          _selectedDate.month == now.month &&
                          _selectedDate.day == now.day &&
                          (time.hour < now.hour ||
                              (time.hour == now.hour &&
                                  time.minute < now.minute));

                      final isDisabled = isBooked || isPast;
                      final isSelected = _selectedTime == time;

                      return GestureDetector(
                        onTap: isDisabled
                            ? null
                            : () => setState(() => _selectedTime = time),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? Colors.grey.shade200
                                : isSelected
                                ? const Color(0xFF00FF7F).withValues(alpha: 0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDisabled
                                  ? Colors.grey.shade300
                                  : isSelected
                                  ? const Color(0xFF006D33)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            time.format(context),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isDisabled
                                  ? Colors.grey.shade400
                                  : isSelected
                                  ? const Color(0xFF006D33)
                                  : const Color(0xFF191C1E),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 40),

            if (_selectedPetId != null &&
                _selectedTime != null &&
                _selectedClinicId != null)
              _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF006D33), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildPetSelection() {
    final petsState = ref.watch(petControllerProvider);

    return SizedBox(
      height: 120,
      child: petsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF006D33)),
        ),
        error: (err, stack) => const Text('Hayvanlar yüklenemedi.'),
        data: (pets) {
          if (pets.isEmpty) {
            return const Text('Sisteme kayıtlı hayvan bulunmuyor.');
          }

          // ÇÖZÜM: İlk hayvanın kliniklerini hemen çek
          if (_selectedPetId == null && pets.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedPetId = pets.first.id);
              ref
                  .read(clinicEnrollmentControllerProvider.notifier)
                  .fetchEnrollmentsByPet(pets.first.id);
            });
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final isSelected = _selectedPetId == pet.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPetId = pet.id;
                    _selectedClinicId = null;
                    _selectedTime = null;
                    _bookedAppointments = [];
                  });
                  ref
                      .read(clinicEnrollmentControllerProvider.notifier)
                      .fetchEnrollmentsByPet(pet.id);
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF006D33)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isSelected
                            ? const Color(0xFF006D33).withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        child: Text(
                          pet.name[0],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF006D33)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF191C1E)
                              : Colors.grey.shade600,
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

  Widget _buildClinicSelection() {
    final enrollmentState = ref.watch(clinicEnrollmentControllerProvider);

    return enrollmentState.when(
      loading: () => const LinearProgressIndicator(color: Color(0xFF006D33)),
      error: (e, s) => const Text('Klinikler yüklenemedi.'),
      data: (enrollments) {
        if (enrollments.isEmpty) {
          return const Text(
            'Bu dostunuz henüz bir kliniğe kayıtlı değil.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          );
        }

        final uniqueClinicIds = enrollments
            .map((e) => e.clinicId)
            .toSet()
            .toList();

        if (_selectedClinicId == null && uniqueClinicIds.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedClinicId = uniqueClinicIds.first);
            _fetchBookedSlots();
          });
        }

        final bool isValidSelection = uniqueClinicIds.contains(
          _selectedClinicId,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: isValidSelection ? _selectedClinicId : null,
              hint: const Text('Lütfen Kayıtlı Kliniğinizi Seçin'),

              // ÇÖZÜM: Yavaşlatan FutureBuilder yerine Hafızadan (Cache) okuma
              items: uniqueClinicIds.map((clinicId) {
                // Hafızada yoksa arkadan sessizce çek
                _fetchClinicNameIfNeeded(clinicId);
                // Anında hafızadakini (veya yükleniyor yazısını) göster
                final clinicName =
                    _clinicNamesCache[clinicId] ?? 'Yükleniyor...';

                return DropdownMenuItem<String>(
                  value: clinicId,
                  child: Text(
                    clinicName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),

              onChanged: (val) {
                setState(() {
                  _selectedClinicId = val;
                  _selectedTime = null;
                });
                _fetchBookedSlots();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006D33),
              letterSpacing: 1,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.expand_more, size: 20),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
              ),
              onChanged: onChanged,
              items: items
                  .map(
                    (String item) =>
                        DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final pets = ref.read(petControllerProvider).value ?? [];
    final selectedPetName = pets
        .firstWhere(
          (p) => p.id == _selectedPetId,
          orElse: () => Pet(
            id: '',
            ownerId: '',
            name: 'Bilinmiyor',
            species: '',
            breed: '',
            birthDate: DateTime.now(),
            neutered: false,
          ),
        )
        .name;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF006D33),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006D33).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÖZET',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$selectedPetName • $_selectedService',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate)}, ${_selectedTime!.format(context)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitAppointment,
              icon: const Icon(Icons.check_circle, color: Color(0xFF006D33)),
              label: const Text(
                'Randevuyu Onayla',
                style: TextStyle(
                  color: Color(0xFF006D33),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAppointment() async {
    if (_selectedPetId == null ||
        _selectedTime == null ||
        _selectedClinicId == null)
      return;

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final endDateTime = startDateTime.add(const Duration(minutes: 30));

    final newAppointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      petId: _selectedPetId!,
      clinicId: _selectedClinicId!,
      type: _selectedService,
      startsAt: startDateTime,
      endsAt: endDateTime,
      status: 'pending',
      reason: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await ref
          .read(appointmentControllerProvider.notifier)
          .createAppointment(newAppointment);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
