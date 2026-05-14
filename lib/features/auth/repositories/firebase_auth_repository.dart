import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Giriş başarısız: $e');
    }
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Kayıt başarısız: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<String?> getUserRole(String uid) async {
    try {
      // 1. Önce bu UID bir kliniğe mi ait diye clinics koleksiyonuna bakıyoruz
      var clinicDoc = await _firestore.collection('clinics').doc(uid).get();
      if (clinicDoc.exists) {
        return 'clinic';
      }

      // 2. Eğer klinik değilse, pet_owners koleksiyonuna bakıyoruz
      var ownerDoc = await _firestore.collection('pet_owners').doc(uid).get();
      if (ownerDoc.exists) {
        return 'pet_owner';
      }

      // İkisinde de yoksa rol atanmamış/hatalı bir kullanıcıdır
      return null;
    } catch (e) {
      throw Exception('Kullanıcı rolü bulunamadı: $e');
    }
  }
}
