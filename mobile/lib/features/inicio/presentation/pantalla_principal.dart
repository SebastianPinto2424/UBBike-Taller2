import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repositorios_provider.dart';
import '../../../core/providers/sesion_provider.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../core/servicios/fcm_service.dart';
import '../../../core/servicios/tiempo_real_service.dart';
import '../../../features/inicio/application/controlador_notificaciones_inicio.dart';
import '../../../features/notificaciones/presentation/pantalla_notificaciones.dart';
import '../../../shared/modelos/notificacion_app.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';

import 'usuario/vista_inicio_usuario.dart';
import 'usuario/vista_bicicletas_usuario.dart';
import 'usuario/vista_qr_usuario.dart';
import 'guardia/vista_inicio_guardia.dart';
import 'guardia/vista_ingreso_guardia.dart';
import 'central/vista_dashboard_central.dart';
import 'central/vista_movimientos_central.dart';
import 'central/vista_operaciones_guardias_central.dart';
import 'soporte/vista_soporte.dart';
import 'perfil/pantalla_principal_perfil.dart';

class PantallaPrincipal extends ConsumerStatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  ConsumerState<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends ConsumerState<PantallaPrincipal> {
  int indice = 0;
  ModoIngresoGuardia modoIngresoGuardia = ModoIngresoGuardia.qr;
  int tabGestionAdmin = 0;
  int tabAtencionAdmin = 0;
  int tabSoporte = 0;
  int tabBicicletas = 0;
  late final ControladorNotificacionesInicio controladorNotificaciones;
  late final TiempoRealService tiempoRealService;

  void _abrirIngresoGuardia(ModoIngresoGuardia modo) {
    setState(() {
      modoIngresoGuardia = modo;
      indice = 2;
    });
  }

  void _abrirGestionAdmin(int tab) {
    setState(() {
      tabGestionAdmin = tab;
      indice = 4;
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
    FcmService.instancia.notificacionTocada.addListener(_alTocarPush);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sincronizarTiempoRealConSesion(ref.read(sesionProvider).value);

        _alTocarPush();
      }
    });
  }

  @override
  void dispose() {
    controladorNotificaciones.removeListener(_sincronizarNotificaciones);
    controladorNotificaciones.dispose();
    FcmService.instancia.notificacionTocada.removeListener(_alTocarPush);
    tiempoRealService.dispose();
    super.dispose();
  }

  void _alTocarPush() {
    final data = FcmService.instancia.notificacionTocada.value;
    if (data == null || !mounted) {
      return;
    }

    final sesion = ref.read(sesionProvider).value;
    final rol =
        sesion is SesionActiva ? sesion.usuario.rol : RolUsuario.estudiante;
    final tipo = data['tipo']?.toString();

    switch (tipo) {
      case 'SOLICITUD_GUARDIA':
        _abrirDestinoSolicitudGuardia(rol);
        break;
      case 'INCIDENCIA':
        _abrirDestinoIncidencia(rol);
        break;
      case 'MOVIMIENTO':
        _abrirDestinoMovimiento(rol);
        break;
    }

    FcmService.instancia.notificacionTocada.value = null;
    controladorNotificaciones.actualizar();
  }

  void _sincronizarTiempoRealConSesion(SesionState? sesion) {
    final repositorio = ref.read(notificacionRepositoryProvider);

    if (sesion is SesionActiva) {
      tiempoRealService.conectar(sesion.token);
      FcmService.instancia.registrarToken(repositorio);
      return;
    }

    tiempoRealService.desconectar();
    FcmService.instancia.eliminarToken(repositorio);
  }

  Future<void> _abrirNotificaciones() async {
    final sesion = ref.read(sesionProvider).value;
    final rol =
        sesion is SesionActiva ? sesion.usuario.rol : RolUsuario.estudiante;

    final notificacion = await Navigator.of(context).push<NotificacionApp>(
      MaterialPageRoute(
        builder: (_) => const PantallaNotificaciones(),
      ),
    );

    if (mounted) {
      if (notificacion != null) {
        _navegarDesdeNotificacion(notificacion, rol);
      }
      await controladorNotificaciones.actualizar();
    }
  }

  void _navegarDesdeNotificacion(
    NotificacionApp notificacion,
    RolUsuario rol,
  ) {
    switch (notificacion.tipo) {
      case 'SOLICITUD_GUARDIA':
        _abrirDestinoSolicitudGuardia(rol);
        return;
      case 'INCIDENCIA':
        _abrirDestinoIncidencia(rol);
        return;
      case 'MOVIMIENTO':
        _abrirDestinoMovimiento(rol);
        return;
    }
  }

  void _abrirDestinoSolicitudGuardia(RolUsuario rol) {
    setState(() {
      tabSoporte = 0;
      if (rol == RolUsuario.guardia) {
        indice = 3;
      } else if (rol == RolUsuario.adminCentral) {
        indice = 3;
      } else if (rol == RolUsuario.administrador) {
        tabGestionAdmin = 2;
        tabAtencionAdmin = 1;
        indice = 4;
      } else {
        indice = 3;
      }
    });
  }

  void _abrirDestinoIncidencia(RolUsuario rol) {
    setState(() {
      tabSoporte = 1;
      if (rol == RolUsuario.administrador) {
        tabGestionAdmin = 2;
        tabAtencionAdmin = 2;
        indice = 4;
      } else {
        indice = 3;
      }
    });
  }

  void _abrirDestinoMovimiento(RolUsuario rol) {
    setState(() {
      if (rol == RolUsuario.guardia || rol == RolUsuario.adminCentral) {
        indice = 1;
      } else if (rol == RolUsuario.administrador) {
        tabGestionAdmin = 1;
        indice = 4;
      } else {
        tabBicicletas = 1;
        indice = 1;
      }
    });
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
          icon: Icon(Icons.pedal_bike_outlined),
          selectedIcon: Icon(Icons.pedal_bike),
          label: 'Bicicletas',
        ),
        const NavigationDestination(
          icon: Icon(Icons.qr_code_scanner_outlined),
          selectedIcon: Icon(Icons.qr_code_scanner),
          label: 'Validar',
        ),
        const NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: 'Soporte',
        ),
        const NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
          label: 'Gestión',
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
        VistaIngresoGuardia(
          modoInicial: modoIngresoGuardia,

          onIrAHistorial: () => setState(() => indice = 1),
        ),
        VistaSoporteGuardia(
          key: ValueKey('soporte-guardia-$tabSoporte'),
          initialIndex: tabSoporte,
        ),
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
        VistaSoporteCentral(
          key: ValueKey('soporte-central-$tabSoporte'),
          initialIndex: tabSoporte,
        ),
        const VistaPerfil(rol: RolUsuario.adminCentral),
      ];
    }

    if (rol == RolUsuario.administrador) {
      return [
        VistaDashboardCentral(
          onAbrirMovimientos: () => _abrirGestionAdmin(1),
          onAbrirGuardias: () => _abrirGestionAdmin(2),
          onAbrirSoporte: () => _abrirGestionAdmin(2),
        ),
        VistaBicicletas(
          key: ValueKey('bicicletas-admin-$tabBicicletas'),
          initialIndex: tabBicicletas,
        ),
        const VistaQrAdmin(),
        VistaSoporteUsuario(
          key: ValueKey('soporte-admin-propio-$tabSoporte'),
          initialIndex: tabSoporte,
        ),
        VistaGestionAdmin(
          key: ValueKey('gestion-admin-$tabGestionAdmin-$tabAtencionAdmin'),
          initialIndex: tabGestionAdmin,
          initialSoporteIndex: tabAtencionAdmin,
        ),
        const VistaPerfil(rol: RolUsuario.administrador),
      ];
    }

    return [
      const VistaInicioUsuario(),
      VistaBicicletas(
        key: ValueKey('bicicletas-usuario-$tabBicicletas'),
        initialIndex: tabBicicletas,
      ),
      const VistaQrUsuario(),
      VistaSoporteUsuario(
        key: ValueKey('soporte-usuario-$tabSoporte'),
        initialIndex: tabSoporte,
      ),
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
        (Icons.pedal_bike_outlined, 'Bicicletas'),
        (Icons.qr_code_scanner, 'Validar'),
        (Icons.support_agent_outlined, 'Soporte'),
        (Icons.tune_outlined, 'Gestión'),
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
