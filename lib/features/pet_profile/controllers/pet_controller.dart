import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// İçe aktarma yolları mimariye uygun şekilde ayarlandı
import '../../../core/providers/repository_providers.dart';
import '../models/pet_model.dart';

/// Hasta sahibine ait hayvanları (Dostlarım) ve arayüzdeki listeyi (state) yöneten Controller
class PetController extends AsyncNotifier<List<Pet>> {
  @override
  FutureOr<List<Pet>> build() {
    return [];
  }

  Future<void> fetchPetsByOwner(String ownerId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(petRepositoryProvider);
      final pets = await repository.getPetsByOwnerId(ownerId);
      state = AsyncValue.data(pets);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addPet(Pet pet) async {
    try {
      final repository = ref.read(petRepositoryProvider);
      await repository.addPet(pet);
      await fetchPetsByOwner(pet.ownerId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePet(Pet pet) async {
    try {
      final repository = ref.read(petRepositoryProvider);
      await repository.updatePet(pet);

      if (state.hasValue) {
        final updatedList = state.value!.map((p) {
          if (p.id == pet.id) return pet;
          return p;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePet(String id) async {
    try {
      final repository = ref.read(petRepositoryProvider);
      await repository.deletePet(id);

      if (state.hasValue) {
        final updatedList = state.value!.where((p) => p.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// (Opsiyonel Yardımcı Metot) Belirli bir hayvanın güncel bilgilerini tekil olarak getirmek istersen
  Future<Pet?> getPetDetails(String id) async {
    try {
      final repository = ref.read(petRepositoryProvider);
      final pet = await repository.getPetById(id);

      // ÇÖZÜM: Eğer hayvan bulunduysa ve şu anki state listesinde yoksa (örneğin klinik için), listeye ekle!
      if (pet != null && state.hasValue) {
        final currentList = state.value!;
        final exists = currentList.any((p) => p.id == pet.id);
        if (!exists) {
          state = AsyncValue.data([...currentList, pet]);
        }
      }
      return pet;
    } catch (e) {
      rethrow;
    }
  }
}

// SİLDİĞİN İÇİN 30 HATA FIRLATAN O SİHİRLİ SATIR BURASI 👇
final petControllerProvider = AsyncNotifierProvider<PetController, List<Pet>>(
  () {
    return PetController();
  },
);
