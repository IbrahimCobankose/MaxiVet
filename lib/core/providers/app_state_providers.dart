import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uygulama içinde o an seçili olan (karnesi incelenen) hayvanın ID'sini tutan Notifier.
class SelectedPetIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Başlangıçta hiçbir hayvan seçili değil
    return null;
  }

  /// Hasta sahibi "Dostlarım" ekranında bir karta tıkladığında bu metot çağrılır
  void setPetId(String? id) {
    state = id;
  }
}

// UI tarafında bu durumu dinlemek ve değiştirmek için Provider
final selectedPetIdProvider = NotifierProvider<SelectedPetIdNotifier, String?>(
  () {
    return SelectedPetIdNotifier();
  },
);
