class Pet {
  final String id;
  final String
  ownerId; // Bu alan PetOwner (Hasta Sahibi) nesnesi ile bağlantıyı sağlar (Foreign Key)
  final String name;
  final String species; // Tür (Köpek, Kedi, vb.)
  final String breed; // Irk
  final DateTime birthDate;
  final String?
  microchipNo; // Nullable (?) yaptık çünkü hayvanın çipi olmayabilir
  final bool neutered; // Kısırlaştırma durumu
  final String?
  bloodType; // Nullable (?) yaptık çünkü kan grubu her zaman bilinmeyebilir

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.birthDate,
    this.microchipNo,
    required this.neutered,
    this.bloodType,
  });

  // Firebase'den veri okurken kullanılacak fonksiyon
  factory Pet.fromJson(Map<String, dynamic> json, String documentId) {
    return Pet(
      id: documentId,
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      // Tarih dönüşümünü güvenli yapıyoruz
      birthDate: json['birth_date'] != null
          ? (json['birth_date'] as dynamic).toDate()
          : DateTime.now(),
      microchipNo: json['microchip_no'] as String?,
      neutered: json['neutered'] as bool? ?? false,
      bloodType: json['blood_type'] as String?,
    );
  }

  // Firebase'e veri yazarken kullanılacak fonksiyon
  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'name': name,
      'species': species,
      'breed': breed,
      'birth_date': birthDate,
      'microchip_no': microchipNo,
      'neutered': neutered,
      'blood_type': bloodType,
    };
  }

  // State Management (Durum Yönetimi) için kopya oluşturucu
  Pet copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? species,
    String? breed,
    DateTime? birthDate,
    String? microchipNo,
    bool? neutered,
    String? bloodType,
  }) {
    return Pet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      microchipNo: microchipNo ?? this.microchipNo,
      neutered: neutered ?? this.neutered,
      bloodType: bloodType ?? this.bloodType,
    );
  }
}
