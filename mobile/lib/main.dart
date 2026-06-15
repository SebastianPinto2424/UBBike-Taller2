import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/providers/sesion_provider.dart';
import 'core/tema/tema_ubb.dart';
import 'features/auth/presentation/pantalla_login.dart';
import 'features/auth/presentation/pantallas_correo.dart';
import 'features/inicio/presentation/pantalla_principal.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  usePathUrlStrategy();
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
    if (!kIsWeb) {
      _inicializarDeepLinks();
    }
  }

  Future<void> _inicializarDeepLinks() async {
    final uriInicial = await _appLinks.getInitialLink();
    if (uriInicial != null) {
      _navegarDesdeUri(uriInicial);
    }
    _appLinks.uriLinkStream.listen(_navegarDesdeUri);
  }

  void _navegarDesdeUri(Uri uri) {
    final path =
        uri.scheme == 'ubbike' && uri.path.isEmpty && uri.host.isNotEmpty
            ? '/${uri.host}'
            : uri.path;
    final ruta = uri.query.isEmpty ? path : '$path?${uri.query}';
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
      theme: crearTemaUbb(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
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

    if (uri.path == '/completar-registro') {
      return MaterialPageRoute(
        builder: (_) => PantallaCompletarRegistro(
          token: uri.queryParameters['token'] ?? '',
        ),
      );
    }

    if (uri.path == '/login') {
      final verificado = uri.queryParameters['verificado'] == '1';
      final contrasenaActualizada =
          uri.queryParameters['contrasena_actualizada'] == '1';
      final correo = uri.queryParameters['correo']?.trim();

      return MaterialPageRoute(
        builder: (_) => PantallaLogin(
          correoInicial: correo != null && correo.isNotEmpty ? correo : null,
          mensajeInicial: verificado
              ? 'Correo verificado. Ingresa tu contraseña para iniciar sesión.'
              : contrasenaActualizada
                  ? 'Contraseña actualizada. Ingresa con tu nueva contraseña.'
                  : null,
        ),
      );
    }

    return MaterialPageRoute(builder: (_) => const _EnrutadorRaiz());
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
