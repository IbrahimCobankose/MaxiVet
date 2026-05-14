import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';

class RoleCheckView extends ConsumerStatefulWidget {
  const RoleCheckView({super.key});

  @override
  ConsumerState<RoleCheckView> createState() => _RoleCheckViewState();
}

class _RoleCheckViewState extends ConsumerState<RoleCheckView> {
  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    // 1. Giriş yapmış kullanıcıyı alıyoruz
    final user = ref.read(authControllerProvider).value;

    if (user != null) {
      // 2. AuthController'daki metodumuzla rolünü sorguluyoruz
      final role = await ref
          .read(authControllerProvider.notifier)
          .getUserRole(user.uid);

      if (!mounted) return;

      // 3. Rolüne göre doğru sayfaya yönlendiriyoruz
      if (role == 'clinic') {
        context.go('/clinic-home');
      } else {
        // Rolü pet_owner ise veya henüz atanmamışsa varsayılan olarak müşteri sayfasına at
        context.go('/home');
      }
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF006D33), // MaxiVet Ana Yeşili
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
