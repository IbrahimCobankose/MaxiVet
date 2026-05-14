import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/pet_owner_model.dart';

/// Hasta sahibinin kendi oturumunu ve profil durumunu (state) yöneten Controller.
/// State olarak giriş yapmış olan [PetOwner] nesnesini (veya null) tutar.
class PetOwnerController extends AsyncNotifier<PetOwner?> {
  @override
  FutureOr<PetOwner?> build() {
    // Uygulama ilk açıldığında henüz giriş yapmış bir kullanıcı olmadığı için null döndürüyoruz.
    return null;
  }

  /// ID'si verilen hasta sahibinin bilgilerini getirir ve state'i günceller.
  /// (Kullanıcının uygulamaya başarılı bir şekilde giriş yaptığı senaryo)
  Future<void> fetchPetOwnerById(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(petOwnerRepositoryProvider);
      final petOwner = await repository.getPetOwnerById(id);
      state = AsyncValue.data(petOwner);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Yeni bir hasta sahibi profili oluşturur ve başarılı olursa oluşturulan kişiyi state'e atar.
  Future<void> createPetOwner(PetOwner petOwner) async {
    try {
      final repository = ref.read(petOwnerRepositoryProvider);
      await repository.createPetOwner(petOwner);

      // Kayıt işlemi başarılı olduktan sonra state'i güncelliyoruz
      state = AsyncValue.data(petOwner);
    } catch (e) {
      rethrow; // UI tarafında yakalanıp hata mesajı gösterilmesi için
    }
  }

  /// Hasta sahibinin profil bilgilerini (telefon, isim vb.) günceller ve arayüze anında yansıtır.
  Future<void> updatePetOwner(PetOwner petOwner) async {
    try {
      final repository = ref.read(petOwnerRepositoryProvider);
      await repository.updatePetOwner(petOwner);

      // Güncelleme başarılıysa, state'i yeni verilerle eziyoruz (optimistic update)
      state = AsyncValue.data(petOwner);
    } catch (e) {
      rethrow;
    }
  }

  /// Hasta sahibinin hesabını siler ve state'i temizler (Çıkış yapmış gibi).
  Future<void> deletePetOwner(String id) async {
    try {
      final repository = ref.read(petOwnerRepositoryProvider);
      await repository.deletePetOwner(id);

      // Hesap silindiği için state'i null'a çekiyoruz
      state = const AsyncValue.data(null);
    } catch (e) {
      rethrow;
    }
  }
}

// UI tarafında bu controller'ı dinlemek ve fonksiyonlarına erişmek için Provider
final petOwnerControllerProvider =
    AsyncNotifierProvider<PetOwnerController, PetOwner?>(() {
      return PetOwnerController();
    });
