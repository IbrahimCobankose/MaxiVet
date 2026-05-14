class WeightLog {
  final String id;
  final String petId; // Kilosu ölçülen hayvanın ID'si (Foreign Key)
  final double weightKg; // Ondalıklı hesaplamalar için double kullanıyoruz
  final DateTime measuredAt; // Ölçüm Tarihi

  WeightLog({
    required this.id,
    required this.petId,
    required this.weightKg,
    required this.measuredAt,
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory WeightLog.fromJson(Map<String, dynamic> json, String documentId) {
    return WeightLog(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',

      // Kritik Nokta: Firebase, "5.0" değerini bazen tam sayı (int) "5" olarak döndürebilir.
      // Uygulamanın çökmemesi için önce 'num' olarak alıp sonra güvenlice 'double'a çeviriyoruz.
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,

      measuredAt: json['measured_at'] != null
          ? (json['measured_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {'pet_id': petId, 'weight_kg': weightKg, 'measured_at': measuredAt};
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  WeightLog copyWith({
    String? id,
    String? petId,
    double? weightKg,
    DateTime? measuredAt,
  }) {
    return WeightLog(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      weightKg: weightKg ?? this.weightKg,
      measuredAt: measuredAt ?? this.measuredAt,
    );
  }
}
