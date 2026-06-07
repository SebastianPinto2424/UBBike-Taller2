import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/sesion_provider.dart';
import 'core/tema/tema_ubb.dart';
import 'features/auth/presentation/pantalla_login.dart';
import 'features/auth/presentation/pantallas_correo.dart';
import 'features/inicio/presentation/pantalla_principal.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const ProviderScope(child: AplicacionUBBike()));
}

class AplicacionUBBike extends StatefulWidget {
  const AplicacionUBBike({super.key});

  @override
  State<AplicacionUBBike> createState() => _AplicacionUBBikeState();
}

class _AplicacionUBBikeState extends State<AplicacionUBBike> {
  final _appLinks = AppLinks();
  String? _ultimaRutaDeepLink;

  @override
  void initState() {
    super.initState();
    _inicializarDeepLinks();
  }

  Future<void> _inicializarDeepLinks() async {
    final uriInicial = await _appLinks.getInitialLink();
    if (uriInicial != null) {
      _navegarDesdeUri(uriInicial);
    }
    _appLinks.uriLinkStream.listen(_navegarDesdeUri);
  }

  void _navegarDesdeUri(Uri uri) {
    final ruta = uri.query.isEmpty ? uri.path : '${uri.path}?${uri.query}';
    if (ruta == _ultimaRutaDeepLink) {
      return;
    }
    _ultimaRutaDeepLink = ruta;
    _navigatorKey.currentState?.pushNamed(ruta);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'UBBike',
      debugShowCheckedModeBanner: false,
      theme: crearTemaUbb(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: _generarRuta,
      home: const _EnrutadorRaiz(),
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

    if (uri.path == '/completar-registro') {
      return MaterialPageRoute(
        builder: (_) => PantallaCompletarRegistro(
          token: uri.queryParameters['token'] ?? '',
        ),
      );
    }

    return MaterialPageRoute(builder: (_) => const PantallaLogin());
  }
}

class _EnrutadorRaiz extends ConsumerWidget {
  const _EnrutadorRaiz();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesionAsync = ref.watch(sesionProvider);

    return sesionAsync.when(
      loading: () => const _PantallaCarga(),
      error: (_, __) => const PantallaLogin(),
      data: (sesion) => switch (sesion) {
        SesionCargando() => const _PantallaCarga(),
        SesionVacia() => const PantallaLogin(),
        SesionActiva() => const PantallaPrincipal(),
      },
    );
  }
}

class _PantallaCarga extends StatelessWidget {
  const _PantallaCarga();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Iniciando UBBike...'),
          ],
        ),
      ),
    );
  }
}
