import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// İlgili controller ve modeli içeri aktarıyoruz
import '../controllers/pet_controller.dart';
import '../models/pet_model.dart';
import '../../auth/controllers/auth_controller.dart';

class AddPetView extends ConsumerStatefulWidget {
  const AddPetView({super.key});

  @override
  ConsumerState<AddPetView> createState() => _AddPetViewState();
}

class _AddPetViewState extends ConsumerState<AddPetView> {
  final _formKey = GlobalKey<FormState>();

  // Form Kontrolcüleri
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _microchipController = TextEditingController();
  final _bloodTypeController = TextEditingController();

  // Değişken Durumlar
  String _selectedSpecies = 'Köpek';
  DateTime _selectedDate = DateTime.now();
  bool _isNeutered = false;

  final List<String> _speciesList = ['Köpek', 'Kedi', 'Kuş', 'Tavşan', 'Diğer'];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _microchipController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  // Tarih seçici penceresi
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // En eski doğum tarihi
      lastDate: DateTime.now(), // Gelecekte doğmuş olamaz
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006D33), // Seçili tarih yeşil olsun
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Kaydetme İşlemi
  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      // O anki kullanıcının ID'sini alıyoruz
      final currentUser = ref.read(authControllerProvider).value;
      final ownerId =
          currentUser?.uid ??
          'test_owner_id'; // Firebase bağlı değilse test ID atar

      // Yeni bir ID üretiyoruz (Gerçekte UUID paketi veya Firebase Document ID kullanılır)
      final generatedId = DateTime.now().millisecondsSinceEpoch.toString();

      final newPet = Pet(
        id: generatedId,
        ownerId: ownerId,
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        breed: _breedController.text.trim(),
        birthDate: _selectedDate,
        microchipNo: _microchipController.text.trim().isEmpty
            ? null
            : _microchipController.text.trim(),
        neutered: _isNeutered,
        bloodType: _bloodTypeController.text.trim().isEmpty
            ? null
            : _bloodTypeController.text.trim(),
      );

      try {
        // Controller'ı çağırıp hayvanı listeye ekliyoruz
        await ref.read(petControllerProvider.notifier).addPet(newPet);

        if (mounted) {
          // Başarılı olursa önceki sayfaya (Dostlarım listesine) geri dön
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Yeni Dost Ekle',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF191C1E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Alanı (Temsili)
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D33).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF006D33).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Color(0xFF006D33),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // İsim Alanı
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('İsim', Icons.pets),
                validator: (value) =>
                    value!.isEmpty ? 'Lütfen bir isim girin' : null,
              ),
              const SizedBox(height: 16),

              // Tür ve Irk Yan Yana
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSpecies,
                      decoration: _buildInputDecoration(
                        'Tür',
                        Icons.category_outlined,
                      ),
                      items: _speciesList.map((String species) {
                        return DropdownMenuItem(
                          value: species,
                          child: Text(species),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSpecies = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _breedController,
                      decoration: _buildInputDecoration(
                        'Irk',
                        Icons.cruelty_free_outlined,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Lütfen ırk girin' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Doğum Tarihi (InkWell ile sahte input görünümü)
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _buildInputDecoration(
                    'Doğum Tarihi',
                    Icons.cake_outlined,
                  ),
                  child: Text(
                    DateFormat('dd.MM.yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Çip Numarası
              TextFormField(
                controller: _microchipController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(
                  'Çip Numarası (Opsiyonel)',
                  Icons.memory,
                ),
              ),
              const SizedBox(height: 16),

              // Kan Grubu
              TextFormField(
                controller: _bloodTypeController,
                decoration: _buildInputDecoration(
                  'Kan Grubu (Opsiyonel)',
                  Icons.bloodtype_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Kısırlaştırma Durumu
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Kısırlaştırılmış',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  activeThumbColor: const Color(0xFF006D33),
                  value: _isNeutered,
                  onChanged: (bool value) {
                    setState(() {
                      _isNeutered = value;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _savePet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D33),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Kaydet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 40), // Alt boşluk
            ],
          ),
        ),
      ),
    );
  }

  // Input alanları için ortak tasarım metodu
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF006D33), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
