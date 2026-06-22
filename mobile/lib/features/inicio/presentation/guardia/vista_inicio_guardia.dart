import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ubbike/core/providers/repositorios_provider.dart';
import 'package:ubbike/core/tema/colores_ubb.dart';
import 'package:ubbike/core/utils/leer_provider.dart';
import 'package:ubbike/features/acceso/data/solicitud_guardia_repository.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';
import 'package:ubbike/shared/utils/sesion_ui_utils.dart';
import 'package:ubbike/shared/widgets/tarjeta_accion.dart';
import 'package:ubbike/features/inicio/presentation/comun/widgets_comun.dart';
import 'package:ubbike/features/inicio/presentation/guardia/vista_ingreso_guardia.dart';
import 'package:ubbike/features/inicio/presentation/perfil/pantalla_principal_perfil.dart';

class VistaInicioGuardia extends StatefulWidget {
  const VistaInicioGuardia({
    super.key,
    this.onOpenIngreso,
  });

  final ValueChanged<ModoIngresoGuardia>? onOpenIngreso;

  @override
  State<VistaInicioGuardia> createState() => _VistaInicioGuardiaState();
}

class _VistaInicioGuardiaState extends State<VistaInicioGuardia> {
  late final SolicitudGuardiaRepository solicitudGuardiaRepository;
  late Future<BicicleteroApp?> futuroBicicletero;

  @override
  void initState() {
    super.initState();
    solicitudGuardiaRepository = leerProvider(
      context,
      solicitudGuardiaRepositoryProvider,
    );
    futuroBicicletero =
        solicitudGuardiaRepository.obtenerBicicleteroGestionado();
  }

  void _recargar() {
    setState(
      () => futuroBicicletero =
          solicitudGuardiaRepository.obtenerBicicleteroGestionado(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _recargar(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EncabezadoSeccion(
            titulo: '${saludoActual()}, ${nombreSesion(context, 'Guardia')}',
            detalle: 'Turno activo, bicicletero asignado y accesos recientes.',
            icono: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 16),
          FutureBuilder<BicicleteroApp?>(
            future: futuroBicicletero,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Column(
                  children: [
                    const TarjetaAccion(
                      icono: Icons.location_off_outlined,
                      titulo: 'Sin bicicletero asignado',
                      detalle:
                          'Selecciona el bicicletero que gestionarás en este turno.',
                      color: ColoresUbb.amarilloInstitucional,
                    ),
                    const SizedBox(height: 12),
                    SelectorBicicleteroGuardiaPerfil(onCambiado: _recargar),
                  ],
                );
              }
              return Column(
                children: [
                  TarjetaBicicleteroApp(bicicletero: snapshot.data!),
                  const SizedBox(height: 12),
                  SelectorBicicleteroGuardiaPerfil(onCambiado: _recargar),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          TarjetaAccion(
            icono: Icons.qr_code_scanner,
            titulo: 'Escanear QR temporal',
            detalle:
                'Lee el código del usuario para confirmar o denegar ingreso/retiro.',
            color: ColoresUbb.exito,
            onTap: () => widget.onOpenIngreso?.call(ModoIngresoGuardia.qr),
          ),
          const SizedBox(height: 10),
          TarjetaAccion(
            icono: Icons.edit_note_outlined,
            titulo: 'Gestión manual',
            detalle:
                'Registra ingreso o retiro usando correo institucional y RUT.',
            color: ColoresUbb.azulInstitucional,
            onTap: () => widget.onOpenIngreso?.call(ModoIngresoGuardia.manual),
          ),
        ],
      ),
    );
  }
}
