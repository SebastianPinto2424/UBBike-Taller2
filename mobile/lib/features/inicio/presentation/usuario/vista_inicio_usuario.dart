part of '../pantalla_principal.dart';

class VistaInicioUsuario extends StatefulWidget {
  const VistaInicioUsuario({super.key});

  @override
  State<VistaInicioUsuario> createState() => _VistaInicioUsuarioState();
}

class _VistaInicioUsuarioState extends State<VistaInicioUsuario> {
  final bicicletaApi = BicicletaApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<BicicletaApp?> futuroBicicletaActiva;
  late Future<List<BicicleteroApp>> futuroBicicleteros;

  @override
  void initState() {
    super.initState();
    futuroBicicletaActiva = bicicletaApi.obtenerActiva();
    futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
  }

  void _recargar() {
    setState(() {
      futuroBicicletaActiva = bicicletaApi.obtenerActiva();
      futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
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
            titulo: '${_saludoActual()}, ${_nombreSesion('Usuario UBB')}',
            detalle: 'Estado de tus bicicletas y bicicleteros disponibles.',
            icono: Icons.home_outlined,
          ),
          const SizedBox(height: 16),
          FutureBuilder<BicicletaApp?>(
            future: futuroBicicletaActiva,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const EstadoLista(
                  icono: Icons.pedal_bike,
                  titulo: 'Cargando estado',
                  detalle: 'Consultando tu bicicleta activa.',
                );
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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
            },
          ),
        ],
      ),
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
