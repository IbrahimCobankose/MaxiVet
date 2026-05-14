class PetOwner {
  // Sınıf özelliklerini final yaparak immutability (değiştirilemezlik) sağlıyoruz.
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime createdAt;

  // Constructor (Yapıcı Metot)
  PetOwner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  // 1. Firebase'den gelen JSON (Map) verisini Dart nesnesine dönüştüren Factory Metot
  factory PetOwner.fromJson(Map<String, dynamic> json, String documentId) {
    return PetOwner(
      id: documentId, // Firebase document ID'sini nesnemizin ID'si yapıyoruz
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      // Firebase Timestamp verisini Dart DateTime nesnesine çeviriyoruz
      createdAt: json['created_at'] != null
          ? (json['created_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // 2. Dart nesnesini Firebase'e kaydetmek için JSON'a dönüştüren Metot
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'created_at': createdAt,
      // 'id' alanını Firestore döküman adı yapacağımız için JSON içine yazmamıza gerek yok
    };
  }

  // 3. Mevcut nesnenin sadece belirli özelliklerini değiştirerek yeni bir nesne kopyası üreten Metot (State Management için çok faydalıdır)
  PetOwner copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? createdAt,
  }) {
    return PetOwner(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
