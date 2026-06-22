import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repositorios_provider.dart';
import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../shared/modelos/notificacion_app.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../data/notificacion_repository.dart';

class PantallaNotificaciones extends ConsumerStatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  ConsumerState<PantallaNotificaciones> createState() =>
      _PantallaNotificacionesState();
}

class _PantallaNotificacionesState
    extends ConsumerState<PantallaNotificaciones> {
  late final NotificacionRepository notificacionRepository;
  late Future<List<NotificacionApp>> futuroNotificaciones;
  Timer? temporizadorNotificaciones;

  @override
  void initState() {
    super.initState();
    notificacionRepository = ref.read(notificacionRepositoryProvider);
    futuroNotificaciones = notificacionRepository.listar();
    temporizadorNotificaciones = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _recargar(),
    );
  }

  @override
  void dispose() {
    temporizadorNotificaciones?.cancel();
    super.dispose();
  }

  Future<void> _recargar() async {
    if (!mounted) {
      return;
    }

    setState(() {
      futuroNotificaciones = notificacionRepository.listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ContenedorResponsivo(
        anchoMaximo: 760,
        child: FutureBuilder<List<NotificacionApp>>(
          future: futuroNotificaciones,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final mensaje = snapshot.error is ExcepcionApi
                  ? (snapshot.error! as ExcepcionApi).mensaje
                  : 'No se pudieron cargar las notificaciones';
              return _EstadoNotificaciones(
                icono: Icons.cloud_off_outlined,
                titulo: 'Sin conexión',
                mensaje: mensaje,
              );
            }

            final notificaciones = snapshot.data ?? [];

            if (notificaciones.isEmpty) {
              return const _EstadoNotificaciones(
                icono: Icons.notifications_none_outlined,
                titulo: 'Sin notificaciones',
                mensaje: 'Aquí verás solicitudes, alertas e incidencias.',
              );
            }

            final ordenadas = [...notificaciones]..sort((a, b) {
                if (a.leida != b.leida) return a.leida ? 1 : -1;
                return b.creadaEn.compareTo(a.creadaEn);
              });

            return RefreshIndicator(
              onRefresh: _recargar,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ordenadas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _TarjetaNotificacion(
                    notificacion: ordenadas[index],
                    onTap: () => _abrirNotificacion(ordenadas[index]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _abrirNotificacion(NotificacionApp notificacion) async {
    try {
      if (!notificacion.leida) {
        await notificacionRepository.marcarLeida(notificacion.id);
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(notificacion);
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  const _TarjetaNotificacion({
    required this.notificacion,
    required this.onTap,
  });

  final NotificacionApp notificacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorPorTipo(notificacion.tipo);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: notificacion.leida
                  ? ColoresUbb.borde
                  : color.withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconoPorTipo(notificacion.tipo),
                      color: color,
                      size: 22,
                    ),
                  ),
                  if (!notificacion.leida)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.tituloVisible,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: ColoresUbb.textoPrincipal,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificacion.mensajeVisible,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ColoresUbb.textoPrincipal,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tiempoRelativo(notificacion.creadaEn),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColoresUbb.textoSecundario,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: ColoresUbb.textoSecundario.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'CUENTA':
        return Icons.manage_accounts_outlined;
      case 'SOLICITUD_GUARDIA':
        return Icons.headset_mic_outlined;
      case 'SEGURIDAD':
        return Icons.security_outlined;
      case 'MOVIMIENTO':
        return Icons.swap_horiz_outlined;
      case 'INCIDENCIA':
        return Icons.flag_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorPorTipo(String tipo) {
    switch (tipo) {
      case 'CUENTA':
        return ColoresUbb.azulInstitucional;
      case 'SOLICITUD_GUARDIA':
        return ColoresUbb.turquesa;
      case 'SEGURIDAD':
        return ColoresUbb.rojoInstitucional;
      case 'MOVIMIENTO':
        return ColoresUbb.exito;
      case 'INCIDENCIA':
        return ColoresUbb.amarilloInstitucional;
      default:
        return ColoresUbb.azulApp;
    }
  }

  String _tiempoRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Hace un momento';
    }
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    }
    if (diferencia.inHours < 24) {
      final h = diferencia.inHours;
      return 'Hace $h ${h == 1 ? 'hora' : 'horas'}';
    }
    if (diferencia.inDays < 7) {
      final d = diferencia.inDays;
      return 'Hace $d ${d == 1 ? 'día' : 'días'}';
    }
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

class _EstadoNotificaciones extends StatelessWidget {
  const _EstadoNotificaciones({
    required this.icono,
    required this.titulo,
    required this.mensaje,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: ColoresUbb.azulApp, size: 44),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(mensaje, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
