part of '../pantalla_principal.dart';

class VistaAlertasGuardia extends StatefulWidget {
  const VistaAlertasGuardia({super.key});

  @override
  State<VistaAlertasGuardia> createState() => _VistaAlertasGuardiaState();
}

class _VistaAlertasGuardiaState extends State<VistaAlertasGuardia> {
  late final SolicitudGuardiaRepository solicitudGuardiaRepository;
  final busquedaController = TextEditingController();
  String estadoFiltro = 'TODOS';
  late Future<List<SolicitudGuardiaApp>> futuroSolicitudes;
  Timer? temporizadorAlertas;
  Set<String> solicitudesConocidas = {};
  bool solicitudesInicializadas = false;

  @override
  void initState() {
    super.initState();
    solicitudGuardiaRepository = _leerProvider(
      context,
      solicitudGuardiaRepositoryProvider,
    );
    futuroSolicitudes = _cargarSolicitudes();
    temporizadorAlertas = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _recargar(avisarNuevas: true),
    );
  }

  @override
  void dispose() {
    temporizadorAlertas?.cancel();
    busquedaController.dispose();
    super.dispose();
  }

  List<SolicitudGuardiaApp> _filtrar(List<SolicitudGuardiaApp> solicitudes) {
    final consulta = busquedaController.text.trim().toLowerCase();
    return solicitudes.where((solicitud) {
      final coincideEstado =
          estadoFiltro == 'TODOS' || solicitud.estado == estadoFiltro;
      final coincideBusqueda = consulta.isEmpty ||
          solicitud.bicicletero.nombre.toLowerCase().contains(consulta) ||
          solicitud.solicitante.nombre.toLowerCase().contains(consulta) ||
          solicitud.solicitante.correo.toLowerCase().contains(consulta);
      return coincideEstado && coincideBusqueda;
    }).toList();
  }

  bool _solicitudAbierta(SolicitudGuardiaApp solicitud) {
    return solicitud.estado != 'RESUELTA' && solicitud.estado != 'CANCELADA';
  }

  Future<List<SolicitudGuardiaApp>> _cargarSolicitudes({
    bool avisarNuevas = false,
  }) async {
    final solicitudes = await solicitudGuardiaRepository.listarSolicitudes();
    final abiertas = solicitudes.where(_solicitudAbierta).toList();
    final idsAbiertas = abiertas.map((solicitud) => solicitud.id).toSet();
    final nuevas = abiertas
        .where((solicitud) => !solicitudesConocidas.contains(solicitud.id))
        .toList();
    final debeAvisar =
        avisarNuevas && solicitudesInicializadas && nuevas.isNotEmpty;

    solicitudesConocidas = idsAbiertas;
    solicitudesInicializadas = true;

    if (debeAvisar && mounted) {
      final primera = nuevas.first;
      context.mostrarInfo(
        nuevas.length == 1
            ? 'Nueva alerta en ${primera.bicicletero.nombre}'
            : '${nuevas.length} nuevas alertas asignadas',
      );
    }

    return solicitudes;
  }

  void _recargar({bool avisarNuevas = false}) {
    if (!mounted) {
      return;
    }

    setState(() {
      futuroSolicitudes = _cargarSolicitudes(avisarNuevas: avisarNuevas);
    });
  }

  Widget _tarjetaSolicitud(SolicitudGuardiaApp solicitud) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TarjetaSolicitudGuardia(
        solicitud: solicitud,
        mostrarSolicitante: true,
        onActualizar: (estado) async {
          await solicitudGuardiaRepository.actualizarEstado(
            solicitudId: solicitud.id,
            estado: estado,
          );
          _recargar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloApartado(titulo: 'Alertas'),
          const SizedBox(height: 10),
          TextField(
            controller: busquedaController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Buscar por bicicletero o solicitante',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: busquedaController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(busquedaController.clear),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          _PanelFiltros(
            titulo: 'Filtros',
            detalle: estadoFiltro == 'TODOS'
                ? 'Todas'
                : etiquetaEstadoSolicitud(estadoFiltro),
            onLimpiar: () => setState(() {
              estadoFiltro = 'TODOS';
              busquedaController.clear();
            }),
            children: [
              _EtiquetaFiltro(
                texto: 'Estado',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in [
                      'TODOS',
                      'PENDIENTE',
                      'NOTIFICADA',
                      'EN_CAMINO',
                      'RESUELTA',
                      'CANCELADA',
                    ])
                      _FiltroChip(
                        label: item == 'TODOS'
                            ? 'Todas'
                            : etiquetaEstadoSolicitud(item),
                        value: item,
                        selectedValue: estadoFiltro,
                        onTap: (valor) => setState(() => estadoFiltro = valor),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: FutureBuilder<List<SolicitudGuardiaApp>>(
                future: futuroSolicitudes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        TarjetaAccion(
                          icono: Icons.error_outline,
                          titulo: 'No se pudieron cargar alertas',
                          detalle: '${snapshot.error}\nToca para reintentar.',
                          color: ColoresUbb.rojoInstitucional,
                          onTap: _recargar,
                        ),
                      ],
                    );
                  }

                  final todas = snapshot.data ?? [];
                  final solicitudes = _filtrar(todas);

                  if (solicitudes.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EstadoLista(
                          icono: Icons.notifications_active_outlined,
                          titulo:
                              todas.isEmpty ? 'Sin alertas' : 'Sin resultados',
                          detalle: todas.isEmpty
                              ? 'No hay solicitudes asignadas por ahora.'
                              : 'Ninguna alerta coincide con tu búsqueda o filtro.',
                        ),
                      ],
                    );
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: solicitudes.map(_tarjetaSolicitud).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
