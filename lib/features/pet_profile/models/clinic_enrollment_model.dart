class ClinicEnrollment {
  final String id;
  final String petId; // Kaydı yapılan hayvanın ID'si (Foreign Key)
  final String clinicId; // Kayıt olunan kliniğin ID'si (Foreign Key)
  final DateTime enrolledAt; // Kayıt tarihi

  ClinicEnrollment({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.enrolledAt,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory ClinicEnrollment.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return ClinicEnrollment(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',
      clinicId: json['clinic_id'] as String? ?? '',
      // Firebase Timestamp nesnesini Dart DateTime'a çeviriyoruz
      enrolledAt: json['enrolled_at'] != null
          ? (json['enrolled_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {'pet_id': petId, 'clinic_id': clinicId, 'enrolled_at': enrolledAt};
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  ClinicEnrollment copyWith({
    String? id,
    String? petId,
    String? clinicId,
    DateTime? enrolledAt,
  }) {
    return ClinicEnrollment(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
    );
  }
}
