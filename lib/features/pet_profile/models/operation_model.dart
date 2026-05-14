class Operation {
  final String id;
  final String petId; // Operasyon geçiren hayvanın ID'si (Foreign Key)
  final String clinicId; // Operasyonu yapan kliniğin ID'si (Foreign Key)
  final String name; // Operasyon Adı (Örn: Kısırlaştırma, Dental Scaling)
  final String? notes; // Hekim notları veya operasyon detayları
  final DateTime operatedAt; // Operasyon Tarihi

  Operation({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.name,
    this.notes,
    required this.operatedAt,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory Operation.fromJson(Map<String, dynamic> json, String documentId) {
    return Operation(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',
      clinicId: json['clinic_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Bilinmeyen Operasyon',
      notes: json['notes'] as String?,

      // Firebase Timestamp nesnesini Dart DateTime'a çeviriyoruz
      operatedAt: json['operated_at'] != null
          ? (json['operated_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'clinic_id': clinicId,
      'name': name,
      'notes': notes,
      'operated_at': operatedAt,
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  Operation copyWith({
    String? id,
    String? petId,
    String? clinicId,
    String? name,
    String? notes,
    DateTime? operatedAt,
  }) {
    return Operation(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      operatedAt: operatedAt ?? this.operatedAt,
    );
  }
}
