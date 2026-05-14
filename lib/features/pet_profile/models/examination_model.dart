class Examination {
  final String id;
  final String petId; // Muayene edilen hayvanın ID'si (Foreign Key)
  final String
  clinicId; // Muayeneyi gerçekleştiren kliniğin ID'si (Foreign Key)
  final String type; // Muayene Türü (Örn: Genel Kontrol, Göz Muayenesi)
  final String? diagnosis; // Teşhis (Her zaman kesin bir teşhis olmayabilir)
  final String? treatmentPlan; // Tedavi Planı / Hekim Notları
  final DateTime examinedAt; // Muayene Tarihi

  Examination({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.type,
    this.diagnosis,
    this.treatmentPlan,
    required this.examinedAt,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory Examination.fromJson(Map<String, dynamic> json, String documentId) {
    return Examination(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',
      clinicId: json['clinic_id'] as String? ?? '',
      type: json['type'] as String? ?? 'Genel Kontrol',
      diagnosis: json['diagnosis'] as String?,
      treatmentPlan: json['treatment_plan'] as String?,

      // Firebase Timestamp nesnesini Dart DateTime'a çeviriyoruz
      examinedAt: json['examined_at'] != null
          ? (json['examined_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'clinic_id': clinicId,
      'type': type,
      'diagnosis': diagnosis,
      'treatment_plan': treatmentPlan,
      'examined_at': examinedAt,
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  Examination copyWith({
    String? id,
    String? petId,
    String? clinicId,
    String? type,
    String? diagnosis,
    String? treatmentPlan,
    DateTime? examinedAt,
  }) {
    return Examination(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      type: type ?? this.type,
      diagnosis: diagnosis ?? this.diagnosis,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      examinedAt: examinedAt ?? this.examinedAt,
    );
  }
}
