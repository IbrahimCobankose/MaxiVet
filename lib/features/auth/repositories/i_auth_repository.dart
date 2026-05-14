import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthRepository {
  // Kullanıcının anlık giriş/çıkış durumunu dinleyen Stream
  Stream<User?> get authStateChanges;

  // Mevcut kullanıcının anlık verisi
  User? get currentUser;

  // Giriş Yapma
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );

  // Kayıt Olma
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  );

  // Çıkış Yapma
  Future<void> signOut();

  // KRİTİK: Giriş yapan kişinin Klinik mi yoksa Hasta Sahibi mi olduğunu bulan metot
  Future<String?> getUserRole(String uid);
}
