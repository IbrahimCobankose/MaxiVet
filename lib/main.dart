import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

// Firebase yapılandırma dosyası (flutterfire configure komutu ile otomatik oluşur)
import 'firebase_options.dart';
import 'core/routing/app_router.dart';

void main() async {
  // Flutter widget bağlamalarının başlatıldığından emin ol (Firebase için zorunlu)
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // TÜRKÇE TARİH FORMATLARI İÇİN GEREKLİ KOD:
  await initializeDateFormatting('tr_TR', null);
  // Uygulamayı Riverpod ProviderScope ile sararak çalıştır
  runApp(const ProviderScope(child: MaxiVetApp()));
}

class MaxiVetApp extends ConsumerWidget {
  const MaxiVetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Router sağlayıcısını (app_router.dart) dinliyoruz
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MaxiVet',
      debugShowCheckedModeBanner:
          false, // Sağ üstteki "DEBUG" yazısını kaldırır
      theme: ThemeData(
        // HTML tasarımlarındaki ana yeşil rengimiz (#006D33)
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D33)),
        useMaterial3: true,
        fontFamily: 'Inter', // Genel font ailemiz
      ),
      routerConfig: router,
    );
  }
}
