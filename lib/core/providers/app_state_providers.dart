import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedPetIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void setPetId(String? id) {
    state = id;
  }
}

final selectedPetIdProvider = NotifierProvider<SelectedPetIdNotifier, String?>(
  () {
    return SelectedPetIdNotifier();
  },
);
