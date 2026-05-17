import 'package:flutter/material.dart';

import 'core/tema/tema_ubb.dart';
import 'features/auth/presentation/pantalla_login.dart';
import 'features/auth/presentation/pantallas_correo.dart';

void main() {
  runApp(const AplicacionUBBike());
}

class AplicacionUBBike extends StatelessWidget {
  const AplicacionUBBike({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UBBike',
      debugShowCheckedModeBanner: false,
      theme: crearTemaUbb(),
      onGenerateRoute: _generarRuta,
    );
  }

  Route<dynamic> _generarRuta(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    if (uri.path == '/verificar-correo') {
      return MaterialPageRoute(
        builder: (_) => PantallaVerificarCorreo(
          token: uri.queryParameters['token'] ?? '',
        ),
      );
    }

    if (uri.path == '/cambiar-contrasena') {
      return MaterialPageRoute(
        builder: (_) => PantallaCambiarContrasena(
          token: uri.queryParameters['token'] ?? '',
        ),
      );
    }

    return MaterialPageRoute(builder: (_) => const PantallaLogin());
  }
}
