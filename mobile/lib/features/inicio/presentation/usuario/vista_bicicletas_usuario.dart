part of '../pantalla_principal.dart';

class VistaBicicletas extends StatefulWidget {
  const VistaBicicletas({super.key});

  @override
  State<VistaBicicletas> createState() => _VistaBicicletasState();
}

class _VistaBicicletasState extends State<VistaBicicletas> {
  final bicicletaApi = BicicletaApi();
  late Future<List<BicicletaApp>> futuroBicicletas;

  @override
  void initState() {
    super.initState();
    futuroBicicletas = bicicletaApi.listar();
  }

  void _recargar() {
    setState(() {
      futuroBicicletas = bicicletaApi.listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _VistaConTabs(
      tabs: [
        _tabCompacto(Icons.pedal_bike_outlined, 'Bicicletas'),
        _tabCompacto(Icons.manage_search_outlined, 'Movimientos'),
      ],
      vistas: [
        _vistaMisBicicletas(),
        const VistaMovimientosUsuario(),
      ],
    );
  }

  Widget _vistaMisBicicletas() {
    return FutureBuilder<List<BicicletaApp>>(
      future: futuroBicicletas,
      builder: (context, snapshot) {
        final bicicletas = snapshot.data ?? [];
        final mostrarBotonEncabezado =
            snapshot.hasData && bicicletas.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _EncabezadoBicicletas(
              mostrarBoton: mostrarBotonEncabezado,
              onRegistrar: _mostrarFormularioBicicleta,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _recargar(),
                child: _ContenidoBicicletas(
                  snapshot: snapshot,
                  onRegistrar: _mostrarFormularioBicicleta,
                  onEditar: (bicicleta) => _mostrarFormularioBicicleta(
                    bicicleta: bicicleta,
                  ),
                  onEliminar: _eliminarBicicleta,
                  onCambiarActiva: _cambiarEstadoActivoBicicleta,
                  onReintentar: _recargar,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cambiarEstadoActivoBicicleta(
    BicicletaApp bicicleta,
    bool activa,
  ) async {
    if (bicicleta.activa == activa) {
      return;
    }

    try {
      if (activa) {
        await bicicletaApi.activar(bicicleta.id);
      } else {
        await bicicletaApi.desactivar(bicicleta.id);
      }
      _recargar();
      if (mounted) {
        context.mostrarExito(
          activa
              ? '${bicicleta.descripcion} activada'
              : '${bicicleta.descripcion} inactiva',
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    }
  }

  Future<void> _eliminarBicicleta(BicicletaApp bicicleta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_outlined,
          color: ColoresUbb.rojoInstitucional,
          size: 44,
        ),
        title: const Text('Eliminar bicicleta'),
        content: Text(
          '¿Seguro que deseas eliminar "${bicicleta.descripcion}"?\nEsta acción no se puede deshacer.',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ColoresUbb.rojoInstitucional,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await bicicletaApi.eliminar(bicicleta.id);
      _recargar();
      if (mounted) {
        context.mostrarExito('Bicicleta eliminada');
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    }
  }

  Future<void> _mostrarFormularioBicicleta({BicicletaApp? bicicleta}) async {
    final guardo = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => _FormularioBicicletaSheet(
        bicicleta: bicicleta,
        bicicletaApi: bicicletaApi,
      ),
    );

    if (guardo == true && mounted) {
      _recargar();
      context.mostrarExito(
        bicicleta == null
            ? 'Bicicleta registrada correctamente'
            : 'Datos editados correctamente',
      );
    }
  }
}

class _EncabezadoBicicletas extends StatelessWidget {
  const _EncabezadoBicicletas({
    required this.mostrarBoton,
    required this.onRegistrar,
  });

  final bool mostrarBoton;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: TituloApartado(titulo: 'Mis bicicletas')),
        if (mostrarBoton) ...[
          const SizedBox(width: 12),
          _BotonRegistrarCompacto(
            texto: 'Registrar',
            onPressed: onRegistrar,
          ),
        ],
      ],
    );
  }
}

class _ContenidoBicicletas extends StatelessWidget {
  const _ContenidoBicicletas({
    required this.snapshot,
    required this.onRegistrar,
    required this.onEditar,
    required this.onEliminar,
    required this.onCambiarActiva,
    required this.onReintentar,
  });

  final AsyncSnapshot<List<BicicletaApp>> snapshot;
  final VoidCallback onRegistrar;
  final ValueChanged<BicicletaApp> onEditar;
  final ValueChanged<BicicletaApp> onEliminar;
  final void Function(BicicletaApp bicicleta, bool activa) onCambiarActiva;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 280,
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
            icono: Icons.cloud_off_outlined,
            titulo: 'No se pudieron cargar bicicletas',
            detalle: 'Revisa que el backend esté activo.',
            color: ColoresUbb.rojoInstitucional,
            onTap: onReintentar,
          ),
        ],
      );
    }

    final bicicletas = snapshot.data ?? [];

    if (bicicletas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 360,
            child: _EstadoVacioBicicletas(onRegistrar: onRegistrar),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ...bicicletas.map(
          (bicicleta) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TarjetaBicicletaUsuario(
              bicicleta: bicicleta,
              onEditar: () => onEditar(bicicleta),
              onEliminar: () => onEliminar(bicicleta),
              onCambiarActiva: (activa) => onCambiarActiva(bicicleta, activa),
            ),
          ),
        ),
      ],
    );
  }
}

class _EstadoVacioBicicletas extends StatelessWidget {
  const _EstadoVacioBicicletas({required this.onRegistrar});

  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pedal_bike,
            size: 64,
            color: ColoresUbb.textoSecundario,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin bicicletas',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: ColoresUbb.textoSecundario),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primera bicicleta para usar el sistema.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: ColoresUbb.textoSecundario),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                backgroundColor: ColoresUbb.azulApp,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRegistrar,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Registrar bicicleta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonRegistrarCompacto extends StatelessWidget {
  const _BotonRegistrarCompacto({
    required this.texto,
    required this.onPressed,
  });

  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: ColoresUbb.azulApp,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
