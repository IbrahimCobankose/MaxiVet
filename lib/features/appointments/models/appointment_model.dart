class Appointment {
  final String id;
  final String petId; // Randevunun ait olduğu hayvan (Foreign Key)
  final String clinicId; // Randevunun alındığı klinik (Foreign Key)
  final DateTime startsAt; // Randevu başlangıç saati
  final DateTime endsAt; // Randevu bitiş saati
  final String type; // Randevu türü (Örn: Genel Muayene, Aşı)
  final String status; // Durumu (Örn: pending, confirmed, cancelled, completed)

  // YENİ EKLENEN ALAN: Hasta sahibinin randevu alırken gireceği şikayet veya not
  final String? reason;

  Appointment({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.startsAt,
    required this.endsAt,
    required this.type,
    required this.status,
    this.reason, // Constructor'a eklendi
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory Appointment.fromJson(Map<String, dynamic> json, String documentId) {
    return Appointment(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',
      clinicId: json['clinic_id'] as String? ?? '',

      // Firebase Timestamp nesnelerini Dart DateTime'a çeviriyoruz
      startsAt: json['starts_at'] != null
          ? (json['starts_at'] as dynamic).toDate()
          : DateTime.now(),
      endsAt: json['ends_at'] != null
          ? (json['ends_at'] as dynamic).toDate()
          : DateTime.now().add(const Duration(minutes: 30)), // Varsayılan 30 dk

      type: json['type'] as String? ?? 'Belirtilmedi',
      status:
          json['status'] as String? ?? 'pending', // Varsayılan durum: Bekliyor
      reason: json['reason'] as String?, // JSON'dan okuma eklendi
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'clinic_id': clinicId,
      'starts_at': startsAt,
      'ends_at': endsAt,
      'type': type,
      'status': status,
      'reason': reason, // JSON'a yazma eklendi
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  Appointment copyWith({
    String? id,
    String? petId,
    String? clinicId,
    DateTime? startsAt,
    DateTime? endsAt,
    String? type,
    String? status,
    String? reason,
  }) {
    return Appointment(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason, // Kopyalamaya eklendi
    );
  }
}
