part of '../pantalla_principal.dart';

class VistaInicioUsuario extends StatefulWidget {
  const VistaInicioUsuario({super.key});

  @override
  State<VistaInicioUsuario> createState() => _VistaInicioUsuarioState();
}

class _VistaInicioUsuarioState extends State<VistaInicioUsuario> {
  final bicicletaApi = BicicletaApi();
  final bicicleteroApi = BicicleteroApi();
  late Future<BicicletaApp?> futuroBicicletaActiva;
  late Future<List<BicicleteroApp>> futuroBicicleteros;

  @override
  void initState() {
    super.initState();
    futuroBicicletaActiva = bicicletaApi.obtenerActiva();
    futuroBicicleteros = bicicleteroApi.listar();
  }

  void _recargar() {
    setState(() {
      futuroBicicletaActiva = bicicletaApi.obtenerActiva();
      futuroBicicleteros = bicicleteroApi.listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _EncabezadoSeccion(
          titulo: '${_saludoActual()}, ${_nombreSesion('Usuario UBB')}',
          detalle: 'Estado de tus bicicletas y bicicleteros disponibles.',
          icono: Icons.home_outlined,
        ),
        const SizedBox(height: 16),
        FutureBuilder<BicicletaApp?>(
          future: futuroBicicletaActiva,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _EstadoLista(
                icono: Icons.pedal_bike,
                titulo: 'Cargando estado',
                detalle: 'Consultando tu bicicleta activa.',
              );
            }
            return _EstadoActualUsuario(bicicleta: snapshot.data);
          },
        ),
        const SizedBox(height: 16),
        _TituloApartado(titulo: 'Uso de bicicleteros', onRefresh: _recargar),
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
              return const _EstadoLista(
                icono: Icons.location_off_outlined,
                titulo: 'Sin bicicleteros activos',
                detalle: 'Cuando existan bicicleteros activos aparecerán aquí.',
              );
            }
            return Column(
              children: bicicleteros
                  .map(
                    (bicicletero) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaBicicleteroApp(bicicletero: bicicletero),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
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

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: ColoresUbb.azulApp.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: const BoxDecoration(
          color: ColoresUbb.azulApp, // Dejar solo azul como solicitó
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                dentro ? Icons.lock_outline : Icons.lock_open_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              bicicleta == null
                  ? 'Sin bicicleta activa'
                  : dentro
                      ? 'Bicicleta dentro'
                      : 'Sin bicicleta dentro',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              bicicleta == null
                  ? 'Registra una bicicleta y márcala como activa para esta etapa del sistema.'
                  : dentro
                      ? '${bicicleta.descripcion} está asociada a ${bicicleta.bicicleteroActualNombre ?? 'un bicicletero'}.'
                      : '${bicicleta.descripcion} está registrada como bicicleta activa.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
