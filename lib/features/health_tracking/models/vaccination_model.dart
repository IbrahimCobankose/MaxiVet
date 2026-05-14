class Vaccination {
  final String id;
  final String petId; // Aşısı yapılan hayvanın ID'si (Foreign Key)
  final String clinicId; // Aşıyı uygulayan kliniğin ID'si (Foreign Key)
  final String vaccineName; // Aşının Adı (Örn: Karma Aşı, Kuduz)
  final DateTime appliedAt; // Aşının yapıldığı tarih
  final DateTime?
  nextDueDate; // Bir sonraki doz/tekrar tarihi (Opsiyonel olabilir)

  Vaccination({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.vaccineName,
    required this.appliedAt,
    this.nextDueDate,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory Vaccination.fromJson(Map<String, dynamic> json, String documentId) {
    return Vaccination(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',
      clinicId: json['clinic_id'] as String? ?? '',
      vaccineName: json['vaccine_name'] as String? ?? 'Bilinmeyen Aşı',

      // Firebase Timestamp nesnelerini Dart DateTime'a çeviriyoruz
      appliedAt: json['applied_at'] != null
          ? (json['applied_at'] as dynamic).toDate()
          : DateTime.now(),

      nextDueDate: json['next_due_date'] != null
          ? (json['next_due_date'] as dynamic).toDate()
          : null,
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'clinic_id': clinicId,
      'vaccine_name': vaccineName,
      'applied_at': appliedAt,
      'next_due_date': nextDueDate,
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  Vaccination copyWith({
    String? id,
    String? petId,
    String? clinicId,
    String? vaccineName,
    DateTime? appliedAt,
    DateTime? nextDueDate,
  }) {
    return Vaccination(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      vaccineName: vaccineName ?? this.vaccineName,
      appliedAt: appliedAt ?? this.appliedAt,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }
}
