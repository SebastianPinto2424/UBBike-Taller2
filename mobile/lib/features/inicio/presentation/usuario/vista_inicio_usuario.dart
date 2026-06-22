import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ubbike/core/providers/repositorios_provider.dart';
import 'package:ubbike/core/tema/colores_ubb.dart';
import 'package:ubbike/core/utils/leer_provider.dart';
import 'package:ubbike/features/acceso/data/solicitud_guardia_repository.dart';
import 'package:ubbike/features/bicicletas/data/bicicleta_repository.dart';
import 'package:ubbike/shared/modelos/bicicleta_app.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';
import 'package:ubbike/shared/utils/sesion_ui_utils.dart';
import 'package:ubbike/shared/widgets/tarjeta_accion.dart';
import 'package:ubbike/features/inicio/presentation/comun/widgets_comun.dart';

class VistaInicioUsuario extends StatefulWidget {
  const VistaInicioUsuario({super.key});

  @override
  State<VistaInicioUsuario> createState() => _VistaInicioUsuarioState();
}

class _VistaInicioUsuarioState extends State<VistaInicioUsuario> {
  late final BicicletaRepository bicicletaRepository;
  late final SolicitudGuardiaRepository solicitudGuardiaRepository;
  late Future<BicicletaApp?> futuroBicicletaActiva;
  late Future<List<BicicleteroApp>> futuroBicicleteros;
  BicicletaApp? ultimaBicicletaActiva;
  bool bicicletaActivaConsultada = false;
  List<BicicleteroApp>? ultimosBicicleteros;

  @override
  void initState() {
    super.initState();
    bicicletaRepository = leerProvider(context, bicicletaRepositoryProvider);
    solicitudGuardiaRepository = leerProvider(
      context,
      solicitudGuardiaRepositoryProvider,
    );
    futuroBicicletaActiva = bicicletaRepository.obtenerActiva();
    futuroBicicleteros = solicitudGuardiaRepository.listarBicicleteros();
  }

  void _recargar() {
    setState(() {
      futuroBicicletaActiva = bicicletaRepository.obtenerActiva();
      futuroBicicleteros = solicitudGuardiaRepository.listarBicicleteros();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _recargar(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EncabezadoSeccion(
            titulo:
                '${saludoActual()}, ${nombreSesion(context, 'Usuario UBB')}',
            detalle: 'Estado de tus bicicletas y bicicleteros disponibles.',
            icono: Icons.home_outlined,
          ),
          const SizedBox(height: 16),
          FutureBuilder<BicicletaApp?>(
            future: futuroBicicletaActiva,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.waiting &&
                  !snapshot.hasError) {
                ultimaBicicletaActiva = snapshot.data;
                bicicletaActivaConsultada = true;
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                if (bicicletaActivaConsultada) {
                  return _EstadoActualUsuario(
                    bicicleta: ultimaBicicletaActiva,
                  );
                }
                return const SizedBox.shrink();
              }
              return _EstadoActualUsuario(bicicleta: snapshot.data);
            },
          ),
          const SizedBox(height: 16),
          const TituloApartado(titulo: 'Uso de bicicleteros'),
          const SizedBox(height: 10),
          FutureBuilder<List<BicicleteroApp>>(
            future: futuroBicicleteros,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                ultimosBicicleteros = snapshot.data;
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                final bicicleteros = ultimosBicicleteros;
                if (bicicleteros == null) {
                  return const SizedBox.shrink();
                }
                return _ListaBicicleterosUsuario(bicicleteros: bicicleteros);
              }
              if (snapshot.hasError) {
                return TarjetaAccion(
                  icono: Icons.cloud_off_outlined,
                  titulo: 'No se pudieron cargar bicicleteros',
                  detalle: 'Toca para reintentar.',
                  color: ColoresUbb.rojoInstitucional,
                  onTap: _recargar,
                );
              }
              final bicicleteros = snapshot.data ?? [];
              if (bicicleteros.isEmpty) {
                return const EstadoLista(
                  icono: Icons.location_off_outlined,
                  titulo: 'Sin bicicleteros activos',
                  detalle:
                      'Cuando existan bicicleteros activos aparecerán aquí.',
                );
              }
              return _ListaBicicleterosUsuario(bicicleteros: bicicleteros);
            },
          ),
        ],
      ),
    );
  }
}

class _ListaBicicleterosUsuario extends StatelessWidget {
  const _ListaBicicleterosUsuario({required this.bicicleteros});

  final List<BicicleteroApp> bicicleteros;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: bicicleteros
          .map(
            (bicicletero) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TarjetaBicicleteroApp(bicicletero: bicicletero),
            ),
          )
          .toList(),
    );
  }
}

class _EstadoActualUsuario extends StatelessWidget {
  const _EstadoActualUsuario({required this.bicicleta});

  final BicicletaApp? bicicleta;

  @override
  Widget build(BuildContext context) {
    final bicicleta = this.bicicleta;
    final dentro = bicicleta?.dentroBicicletero ?? false;

    final titulo = bicicleta == null
        ? 'Sin bicicleta activa'
        : dentro
            ? 'Resguardada en ${bicicleta.bicicleteroActualNombre ?? 'bicicletero'}'
            : 'Fuera del bicicletero';

    final subtitulo = bicicleta == null
        ? 'Registra una bicicleta y márcala como activa.'
        : bicicleta.descripcion;

    final icono = bicicleta != null && dentro
        ? Icons.lock_outline
        : Icons.lock_open_outlined;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: ColoresUbb.azulApp.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: const BoxDecoration(color: ColoresUbb.azulApp),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
