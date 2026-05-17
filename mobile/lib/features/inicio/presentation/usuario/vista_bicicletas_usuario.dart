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
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Bicicletas',
          detalle: 'Administra las bicicletas asociadas a tu cuenta.',
          icono: Icons.pedal_bike,
        ),
        const SizedBox(height: 16),
        const _TituloApartado(titulo: 'Mis bicicletas'),
        const SizedBox(height: 10),
        FutureBuilder<List<BicicletaApp>>(
          future: futuroBicicletas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const _EstadoLista(
                icono: Icons.cloud_off_outlined,
                titulo: 'No se pudieron cargar bicicletas',
                detalle: 'Revisa que el backend esté activo.',
              );
            }

            final bicicletas = snapshot.data ?? [];

            if (bicicletas.isEmpty) {
              return SizedBox(
                height: 250,
                child: Center(
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
                        'Toca abajo para registrar tu primera bicicleta',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: ColoresUbb.textoSecundario),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: bicicletas
                  .map(
                    (bicicleta) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaBicicletaUsuario(
                        bicicleta: bicicleta,
                        onEditar: () => _mostrarFormularioBicicleta(
                          bicicleta: bicicleta,
                        ),
                        onEliminar: () => _eliminarBicicleta(bicicleta),
                        onCambiarActiva: (activa) =>
                            _cambiarEstadoActivoBicicleta(bicicleta, activa),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _mostrarFormularioBicicleta,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: ColoresUbb.azulApp.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColoresUbb.azulApp.withValues(alpha: 0.5),
                style: BorderStyle.none, // We will just use background
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: 1),
                    ],
                  ),
                  child: const Icon(Icons.add,
                      size: 32, color: ColoresUbb.azulApp),
                ),
                const SizedBox(height: 12),
                Text(
                  'Registrar nueva bicicleta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ColoresUbb.azulApp,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Agrega descripción, foto y datos visibles para validación.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresUbb.textoSecundario,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activa
                  ? '${bicicleta.descripcion} activada'
                  : '${bicicleta.descripcion} inactiva',
            ),
          ),
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    }
  }

  Future<void> _eliminarBicicleta(BicicletaApp bicicleta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar bicicleta'),
        content: Text('Se eliminará "${bicicleta.descripcion}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bicicleta eliminada')),
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
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
    }
  }
}
