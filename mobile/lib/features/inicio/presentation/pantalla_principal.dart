import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/providers/repositorios_provider.dart';
import '../../../core/providers/sesion_provider.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../core/servicios/excepcion_api.dart';
import '../../../core/servicios/tiempo_real_service.dart';
import '../../../features/acceso/data/acceso_modelos.dart';
import '../../../features/acceso/data/solicitud_guardia_modelos.dart';
import '../../../features/acceso/data/solicitud_guardia_repository.dart';
import '../../../features/admin/presentation/vista_gestion_usuarios.dart';
import '../../../features/bicicletas/data/bicicleta_repository.dart';
import '../../../features/acceso/data/acceso_repository.dart';
import '../../../features/historial/data/historial_modelos.dart';
import '../../../features/historial/data/historial_repository.dart';
import '../../../features/incidencias/data/incidencia_modelos.dart';
import '../../../features/incidencias/data/incidencia_repository.dart';
import '../../../features/inicio/application/controlador_notificaciones_inicio.dart';
import '../../../features/notificaciones/presentation/pantalla_notificaciones.dart';
import '../../../features/qr/data/qr_modelos.dart';
import '../../../features/qr/data/qr_repository.dart';
import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/modelos/movimiento_app.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/servicios/descarga_reporte.dart';
import '../../../shared/widgets/chip_estado.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/tarjeta_accion.dart';
import '../../../shared/utils/auto_refresco.dart';
import '../../../shared/utils/identidad.dart';
import '../../../shared/utils/opciones_bicicleta.dart';
import '../../../shared/widgets/snackbar_semantico.dart';
import 'comun/widgets_comun.dart';

part 'usuario/vista_inicio_usuario.dart';
part 'usuario/vista_bicicletas_usuario.dart';
part 'usuario/formulario_bicicleta_usuario.dart';
part 'usuario/vista_movimientos_usuario.dart';
part 'usuario/vista_qr_usuario.dart';
part 'usuario/vista_solicitar_guardia.dart';
part 'guardia/vista_inicio_guardia.dart';
part 'guardia/vista_escaner_qr_guardia.dart';
part 'guardia/vista_gestion_manual_guardia.dart';
part 'guardia/vista_ingreso_guardia.dart';
part 'guardia/vista_alertas_guardia.dart';
part 'central/vista_dashboard_central.dart';
part 'central/vista_movimientos_central.dart';
part 'central/vista_operaciones_guardias_central.dart';
part 'central/vista_solicitudes_central.dart';
part 'soporte/vista_incidencias.dart';
part 'soporte/vista_soporte.dart';
part 'perfil/pantalla_principal_perfil.dart';

const int _maxFotoDataUrlLength = 7000000;
const Set<String> _mimesFotoPermitidos = {
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
};

T _leerProvider<T>(BuildContext context, ProviderListenable<T> provider) {
  return ProviderScope.containerOf(context, listen: false).read(provider);
}

class PantallaPrincipal extends ConsumerStatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  ConsumerState<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends ConsumerState<PantallaPrincipal> {
  int indice = 0;
  ModoIngresoGuardia modoIngresoGuardia = ModoIngresoGuardia.qr;
  late final ControladorNotificacionesInicio controladorNotificaciones;
  late final TiempoRealService tiempoRealService;

  void _abrirIngresoGuardia(ModoIngresoGuardia modo) {
    setState(() {
      modoIngresoGuardia = modo;
      indice = 2;
    });
  }

  @override
  void initState() {
    super.initState();
    tiempoRealService = TiempoRealService();
    controladorNotificaciones = ControladorNotificacionesInicio(
      notificacionRepository: ref.read(notificacionRepositoryProvider),
      eventosTiempoReal: tiempoRealService.notificaciones,
    );
    controladorNotificaciones.addListener(_sincronizarNotificaciones);
    controladorNotificaciones.iniciar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sincronizarTiempoRealConSesion(ref.read(sesionProvider).value);
      }
    });
  }

  @override
  void dispose() {
    controladorNotificaciones.removeListener(_sincronizarNotificaciones);
    controladorNotificaciones.dispose();
    tiempoRealService.dispose();
    super.dispose();
  }

  void _sincronizarTiempoRealConSesion(SesionState? sesion) {
    if (sesion is SesionActiva) {
      tiempoRealService.conectar(sesion.token);
      return;
    }

    tiempoRealService.desconectar();
  }

  Future<void> _abrirNotificaciones() async {
    controladorNotificaciones.marcarTodasLeidas();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PantallaNotificaciones(),
      ),
    );

    if (mounted) {
      await controladorNotificaciones.actualizar();
    }
  }

  void _sincronizarNotificaciones() {
    if (!mounted) {
      return;
    }

    setState(() {});
    final nueva = controladorNotificaciones.nuevaNotificacion;
    if (nueva == null) {
      return;
    }

    controladorNotificaciones.marcarNuevaNotificacionMostrada();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nueva.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nueva.mensaje,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: ColoresUbb.azulNoche,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: nueva.muestraAccionVer
            ? SnackBarAction(
                label: 'Ver',
                textColor: ColoresUbb.turquesa,
                onPressed: _abrirNotificaciones,
              )
            : null,
      ),
    );
  }

  Widget _iconoNotificaciones() {
    final cantidad = controladorNotificaciones.noLeidas;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined),
        if (cantidad > 0)
          Positioned(
            right: -4,
            top: -6,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: ColoresUbb.rojoInstitucional,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  cantidad > 9 ? '9+' : '$cantidad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sesionProvider, (_, siguiente) {
      _sincronizarTiempoRealConSesion(siguiente.value);
    });

    final sesion = ref.watch(sesionProvider).value;
    final rol =
        sesion is SesionActiva ? sesion.usuario.rol : RolUsuario.estudiante;
    final destinos = _destinosPorRol(rol);
    final paginas = _paginasPorRol(rol);

    final datos = _datosPaginas(rol);
    final datoActual = indice < datos.length ? datos[indice] : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(datoActual?.$2 ?? 'UBBike'),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: _abrirNotificaciones,
            icon: _iconoNotificaciones(),
          ),
        ],
      ),
      body: ContenedorResponsivo(
        anchoMaximo: 940,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: paginas[indice],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (nuevoIndice) =>
            setState(() => indice = nuevoIndice),
        destinations: destinos,
      ),
    );
  }

  List<NavigationDestination> _destinosPorRol(RolUsuario rol) {
    final iconoQrGuardia = Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      decoration: BoxDecoration(
        color: ColoresUbb.azulApp,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColoresUbb.azulApp.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
    );

    final iconoQrUsuario = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: ColoresUbb.azulApp,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColoresUbb.azulApp.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.qr_code_2, color: Colors.white, size: 30),
    );

    if (rol == RolUsuario.guardia) {
      return [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        const NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Historial',
        ),
        NavigationDestination(
          icon: iconoQrGuardia,
          selectedIcon: iconoQrGuardia,
          label: 'Validar',
        ),
        const NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: 'Avisos',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }

    if (rol == RolUsuario.adminCentral) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.manage_search_outlined),
          selectedIcon: Icon(Icons.manage_search),
          label: 'Movimientos',
        ),
        NavigationDestination(
          icon: Icon(Icons.security_outlined),
          selectedIcon: Icon(Icons.security),
          label: 'Guardias',
        ),
        NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: 'Soporte',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }

    if (rol == RolUsuario.administrador) {
      return [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        const NavigationDestination(
          icon: Icon(Icons.manage_search_outlined),
          selectedIcon: Icon(Icons.manage_search),
          label: 'Movimientos',
        ),
        const NavigationDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts),
          label: 'Usuarios',
        ),
        NavigationDestination(
          icon: iconoQrGuardia,
          selectedIcon: iconoQrGuardia,
          label: 'Validar',
        ),
        const NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: 'Soporte',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }

    return [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const NavigationDestination(
        icon: Icon(Icons.pedal_bike_outlined),
        selectedIcon: Icon(Icons.pedal_bike),
        label: 'Bicicletas',
      ),
      NavigationDestination(
        icon: iconoQrUsuario,
        selectedIcon: iconoQrUsuario,
        label: 'QR',
      ),
      const NavigationDestination(
        icon: Icon(Icons.support_agent_outlined),
        selectedIcon: Icon(Icons.support_agent),
        label: 'Soporte',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];
  }

  List<Widget> _paginasPorRol(RolUsuario rol) {
    if (rol == RolUsuario.guardia) {
      return [
        VistaInicioGuardia(
          onOpenIngreso: _abrirIngresoGuardia,
        ),
        const VistaMovimientosCentral(),
        VistaIngresoGuardia(modoInicial: modoIngresoGuardia),
        const VistaSoporteGuardia(),
        const VistaPerfil(rol: RolUsuario.guardia),
      ];
    }

    if (rol == RolUsuario.adminCentral) {
      return [
        VistaDashboardCentral(
          onAbrirMovimientos: () => setState(() => indice = 1),
          onAbrirGuardias: () => setState(() => indice = 2),
          onAbrirSoporte: () => setState(() => indice = 3),
        ),
        const VistaMovimientosCentral(),
        const VistaOperacionesGuardiasCentral(),
        const VistaSoporteCentral(),
        const VistaPerfil(rol: RolUsuario.adminCentral),
      ];
    }

    if (rol == RolUsuario.administrador) {
      return [
        VistaDashboardCentral(
          onAbrirMovimientos: () => setState(() => indice = 1),
          onAbrirGuardias: () => setState(() => indice = 4),
          onAbrirSoporte: () => setState(() => indice = 4),
        ),
        const VistaMovimientosCentral(),
        const VistaGestionUsuarios(),
        VistaIngresoGuardia(modoInicial: modoIngresoGuardia),
        const VistaSoporteAdministrador(),
        const VistaPerfil(rol: RolUsuario.administrador),
      ];
    }

    return [
      const VistaInicioUsuario(),
      const VistaBicicletas(),
      const VistaQrUsuario(),
      const VistaSoporteUsuario(),
      VistaPerfil(rol: rol),
    ];
  }

  List<(IconData, String)> _datosPaginas(RolUsuario rol) {
    if (rol == RolUsuario.guardia) {
      return const [
        (Icons.home_outlined, 'Inicio'),
        (Icons.history_outlined, 'Historial'),
        (Icons.qr_code_scanner, 'Validar'),
        (Icons.support_agent_outlined, 'Avisos'),
        (Icons.person_outline, 'Perfil'),
      ];
    }
    if (rol == RolUsuario.adminCentral) {
      return const [
        (Icons.dashboard_outlined, 'Inicio'),
        (Icons.manage_search_outlined, 'Movimientos'),
        (Icons.security_outlined, 'Guardias'),
        (Icons.support_agent_outlined, 'Soporte'),
        (Icons.person_outline, 'Perfil'),
      ];
    }
    if (rol == RolUsuario.administrador) {
      return const [
        (Icons.dashboard_outlined, 'Inicio'),
        (Icons.manage_search_outlined, 'Movimientos'),
        (Icons.manage_accounts_outlined, 'Usuarios'),
        (Icons.qr_code_scanner, 'Validar'),
        (Icons.support_agent_outlined, 'Soporte'),
        (Icons.person_outline, 'Perfil'),
      ];
    }
    return const [
      (Icons.home_outlined, 'Inicio'),
      (Icons.pedal_bike_outlined, 'Bicicletas'),
      (Icons.qr_code_2, 'QR'),
      (Icons.support_agent_outlined, 'Soporte'),
      (Icons.person_outline, 'Perfil'),
    ];
  }
}

String _saludoActual() {
  final hora = DateTime.now().hour;
  if (hora < 12) {
    return 'Buenos días';
  }
  if (hora < 20) {
    return 'Buenas tardes';
  }
  return 'Buenas noches';
}

String _nombreSesion(BuildContext context, String respaldo) {
  final sesion = _leerProvider(context, sesionProvider).value;
  final nombre = sesion is SesionActiva ? sesion.usuario.nombre : null;
  return nombreCorto(_textoNoVacio(nombre, respaldo));
}

String _textoNoVacio(String? valor, String respaldo) {
  final texto = valor?.trim();
  if (texto == null || texto.isEmpty) {
    return respaldo;
  }
  return texto;
}

String _detectarMimeDesdeBytes(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return 'image/jpeg';
}
