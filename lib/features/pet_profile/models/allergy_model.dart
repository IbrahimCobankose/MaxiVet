class Allergy {
  final String id;
  final String petId; // Alerjisi olan hayvanın ID'si (Foreign Key)
  final String substance; // Alerjen madde (Örn: Polen, Tavuk, Penisilin)
  final String
  severity; // Alerjinin şiddeti (Örn: Hafif, Orta, Şiddetli / Kritik)

  Allergy({
    required this.id,
    required this.petId,
    required this.substance,
    required this.severity,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory Allergy.fromJson(Map<String, dynamic> json, String documentId) {
    return Allergy(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',
      substance: json['substance'] as String? ?? 'Bilinmeyen Madde',
      severity: json['severity'] as String? ?? 'Bilinmiyor',
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {'pet_id': petId, 'substance': substance, 'severity': severity};
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  Allergy copyWith({
    String? id,
    String? petId,
    String? substance,
    String? severity,
  }) {
    return Allergy(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      substance: substance ?? this.substance,
      severity: severity ?? this.severity,
    );
  }
}
