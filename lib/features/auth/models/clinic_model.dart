class Clinic {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String
  clinicCode; // Kliniğe özel, sistem tarafından üretilen veya atanan kod

  Clinic({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.clinicCode,
  });

  // Firebase'den veriyi okuyup nesneye dönüştüren metot
  factory Clinic.fromJson(Map<String, dynamic> json, String documentId) {
    return Clinic(
      id: documentId,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      clinicCode: json['clinic_code'] as String? ?? '',
    );
  }

  // Nesneyi Firebase'e kaydetmek için JSON'a dönüştüren metot
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'clinic_code': clinicCode,
      // Şifre (password_hash) güvenlik gereği burada tutulmuyor, Firebase Auth yönetiyor.
    };
  }

  // Durum yönetimi (State Management) için kopyalama metodu
  Clinic copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? clinicCode,
  }) {
    return Clinic(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      clinicCode: clinicCode ?? this.clinicCode,
    );
  }
}
