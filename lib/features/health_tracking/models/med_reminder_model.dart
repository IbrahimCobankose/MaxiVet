class MedReminder {
  final String id;
  final String petId; // İlacı kullanacak hayvanın ID'si (Foreign Key)
  final String?
  examinationId; // Hangi muayenede reçete edildiği (Opsiyonel Foreign Key)
  final String medicine; // İlaç Adı (Örn: Synulox)
  final String dosage; // Dozaj (Örn: 1 tablet, 5 ml)
  final String frequency; // Sıklık (Örn: Günde 2 kez, 12 saatte bir)
  final String
  alarmTime; // Alarm Saati (Örn: "08:30" - Saat ve dakika formatında)
  final bool active; // Alarmın açık/kapalı olma durumu
  final DateTime startDate; // Tedavi başlangıç tarihi
  final DateTime endDate; // Tedavi bitiş tarihi

  MedReminder({
    required this.id,
    required this.petId,
    this.examinationId,
    required this.medicine,
    required this.dosage,
    required this.frequency,
    required this.alarmTime,
    required this.active,
    required this.startDate,
    required this.endDate,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory MedReminder.fromJson(Map<String, dynamic> json, String documentId) {
    return MedReminder(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',
      examinationId: json['examination_id'] as String?,
      medicine: json['medicine'] as String? ?? 'Bilinmeyen İlaç',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      alarmTime: json['alarm_time'] as String? ?? '09:00',
      active: json['active'] as bool? ?? true,

      // Firebase Timestamp nesnelerini Dart DateTime'a çeviriyoruz
      startDate: json['start_date'] != null
          ? (json['start_date'] as dynamic).toDate()
          : DateTime.now(),

      endDate: json['end_date'] != null
          ? (json['end_date'] as dynamic).toDate()
          : DateTime.now().add(
              const Duration(days: 7),
            ), // Varsayılan 1 haftalık tedavi
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'examination_id': examinationId,
      'medicine': medicine,
      'dosage': dosage,
      'frequency': frequency,
      'alarm_time': alarmTime,
      'active': active,
      'start_date': startDate,
      'end_date': endDate,
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  MedReminder copyWith({
    String? id,
    String? petId,
    String? examinationId,
    String? medicine,
    String? dosage,
    String? frequency,
    String? alarmTime,
    bool? active,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return MedReminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      examinationId: examinationId ?? this.examinationId,
      medicine: medicine ?? this.medicine,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      alarmTime: alarmTime ?? this.alarmTime,
      active: active ?? this.active,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
