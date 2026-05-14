// 1. Alt Model: Tahlildeki her bir parametre satırını temsil eder (Örn: WBC, RBC, Glikoz)
class LabValue {
  final String parameter; // Parametre adı (Örn: Hemoglobin)
  final double value; // Ölçülen değer
  final String unit; // Birim (Örn: g/dL, mg/dL)
  final double refMin; // Referans alt sınırı
  final double refMax; // Referans üst sınırı
  final String status; // Durum (Örn: Low, Normal, High)

  LabValue({
    required this.parameter,
    required this.value,
    required this.unit,
    required this.refMin,
    required this.refMax,
    required this.status,
  });

  factory LabValue.fromJson(Map<String, dynamic> json) {
    return LabValue(
      parameter: json['parameter'] as String? ?? 'Bilinmiyor',
      // Firebase'den gelen sayısal verileri çökme olmaması için num üzerinden double'a çeviriyoruz
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      refMin: (json['ref_min'] as num?)?.toDouble() ?? 0.0,
      refMax: (json['ref_max'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameter': parameter,
      'value': value,
      'unit': unit,
      'ref_min': refMin,
      'ref_max': refMax,
      'status': status,
    };
  }
}

// 2. Ana Model: Tahlil raporunun bütününü temsil eder
class LabResult {
  final String id;
  final String petId; // Tahlili yapılan hayvanın ID'si
  final String clinicId; // Tahlili yükleyen kliniğin ID'si
  final String panelType; // Tahlil Türü (Örn: Hemogram, Biyokimya)
  final DateTime resultDate; // Sonuç Tarihi
  final String? fileUrl; // Eğer PDF yüklenmişse Firebase Storage linki
  final List<LabValue> values; // Tahlil parametrelerinin listesi

  LabResult({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.panelType,
    required this.resultDate,
    this.fileUrl,
    this.values = const [], // Varsayılan olarak boş liste
  });

  // Firebase'den gelen JSON'ı Dart nesnesine çeviren metot
  factory LabResult.fromJson(Map<String, dynamic> json, String documentId) {
    // İç içe geçmiş (embedded) LabValue listesini ayrıştırıyoruz
    var valuesList = json['values'] as List<dynamic>? ?? [];
    List<LabValue> parsedValues = valuesList
        .map((v) => LabValue.fromJson(v as Map<String, dynamic>))
        .toList();

    return LabResult(
      id: documentId,
      petId: json['pet_id'] as String? ?? '',
      clinicId: json['clinic_id'] as String? ?? '',
      panelType: json['panel_type'] as String? ?? 'Genel Tahlil',

      resultDate: json['result_date'] != null
          ? (json['result_date'] as dynamic).toDate()
          : DateTime.now(),

      fileUrl: json['file_url'] as String?,
      values: parsedValues,
    );
  }

  // Dart nesnesini Firebase'e yazmak için JSON'a çeviren metot
  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'clinic_id': clinicId,
      'panel_type': panelType,
      'result_date': resultDate,
      'file_url': fileUrl,
      // LabValue nesnelerini tekrar JSON formatına (Map) çevirerek listeye ekliyoruz
      'values': values.map((v) => v.toJson()).toList(),
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  LabResult copyWith({
    String? id,
    String? petId,
    String? clinicId,
    String? panelType,
    DateTime? resultDate,
    String? fileUrl,
    List<LabValue>? values,
  }) {
    return LabResult(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      panelType: panelType ?? this.panelType,
      resultDate: resultDate ?? this.resultDate,
      fileUrl: fileUrl ?? this.fileUrl,
      values: values ?? this.values,
    );
  }
}
