import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Klasör yollarını kendi projene göre teyit et
import '../../../core/providers/repository_providers.dart';
import '../../pet_profile/controllers/pet_controller.dart';
import '../../pet_profile/controllers/clinic_enrollment_controller.dart';
import '../../pet_profile/models/clinic_enrollment_model.dart';
import '../../auth/models/clinic_model.dart';

class FindClinicView extends ConsumerStatefulWidget {
  const FindClinicView({super.key});

  @override
  ConsumerState<FindClinicView> createState() => _FindClinicViewState();
}

class _FindClinicViewState extends ConsumerState<FindClinicView> {
  final _searchController = TextEditingController();

  bool _isLoading = false;
  Clinic? _foundClinic;
  String? _selectedPetId; // Hangi hayvanı kaydedeceğiz?
  bool _searchAttempted = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Klinik koduna göre arama yapıyoruz
  Future<void> _searchClinic() async {
    final code = _searchController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchAttempted = true;
      _foundClinic = null;
    });

    try {
      // Repository üzerinden kodu sorguluyoruz (FirebaseClinicRepository'de yazmıştın)
      final repo = ref.read(clinicRepositoryProvider);
      final clinic = await repo.getClinicByCode(code);

      if (mounted) {
        setState(() {
          _foundClinic = clinic;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Arama Hatası: $e')));
      }
    }
  }

  // Bulunan kliniğe seçili hayvanı kaydediyoruz
  Future<void> _enrollPetToClinic() async {
    if (_selectedPetId == null || _foundClinic == null) return;

    setState(() => _isLoading = true);

    try {
      final enrollment = ClinicEnrollment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: _selectedPetId!,
        clinicId: _foundClinic!.id,
        enrolledAt: DateTime.now(),
      );

      // Controller üzerinden veritabanına kayıt atıyoruz
      await ref
          .read(clinicEnrollmentControllerProvider.notifier)
          .enrollPet(enrollment);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Başarıyla kliniğe kayıt olundu! Artık randevu alabilirsiniz.',
            ),
            backgroundColor: Color(0xFF006D33),
          ),
        );
        context.pop(); // Anasayfaya dön
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt Hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcının hayvanlarını listelemek için state'i okuyoruz
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
          'Klinik Bul',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arama Kutusu
            const Text(
              'Veterinerinizin Kodunu Girin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Örn: K-12345',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF006D33),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchClinic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D33),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Ara',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Arama Sonucu Gösterimi
            if (_searchAttempted && _foundClinic == null && !_isLoading)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.orange.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Klinik bulunamadı.\nKodun doğruluğundan emin olun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            if (_foundClinic != null) ...[
              const Text(
                'Bulunan Klinik',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 12),
              // Klinik Kartı
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF006D33).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006D33).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF006D33,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: Color(0xFF006D33),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foundClinic!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _foundClinic!.address,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Hayvan Seçimi ve Kayıt İşlemi
                    const Text(
                      'Hangi dostunuzu kaydedeceksiniz?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    petsState.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => Text('Hayvanlarınız yüklenemedi: $e'),
                      data: (pets) {
                        if (pets.isEmpty) {
                          return const Text(
                            'Önce profilinize bir hayvan eklemelisiniz.',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        // Eğer hayvan seçilmemişse ve liste doluysa ilk hayvanı varsayılan seç
                        _selectedPetId ??= pets.first.id;

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedPetId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          items: pets.map((pet) {
                            return DropdownMenuItem(
                              value: pet.id,
                              child: Text(pet.name),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedPetId = val),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedPetId != null && !_isLoading)
                            ? _enrollPetToClinic
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006D33),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Kayıt Ol ve Bağlan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
  }
}
