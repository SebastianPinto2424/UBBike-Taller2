part of 'widgets_comun.dart';

class TarjetaBicicletaUsuario extends StatefulWidget {
  const TarjetaBicicletaUsuario({
    super.key,
    required this.bicicleta,
    required this.onEditar,
    required this.onEliminar,
    required this.onCambiarActiva,
  });

  final BicicletaApp bicicleta;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final ValueChanged<bool> onCambiarActiva;

  @override
  State<TarjetaBicicletaUsuario> createState() =>
      TarjetaBicicletaUsuarioState();
}

class TarjetaBicicletaUsuarioState extends State<TarjetaBicicletaUsuario> {
  bool gestionAbierta = false;

  void _mostrarFotoAmpliada(BuildContext context, String fotoReferencia) {
    final bytesFoto = decodificarFotoDataUrl(fotoReferencia);
    final Widget imagen = bytesFoto != null
        ? Image.memory(bytesFoto, fit: BoxFit.contain)
        : Image.network(
            resolverUrlFotoBicicleta(fotoReferencia),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          );

    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: imagen,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bicicleta = widget.bicicleta;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ColoresUbb.superficieAzulSuave,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pedal_bike,
                    color: ColoresUbb.azulApp,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bicicleta.descripcion,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bicicleta.activa
                            ? 'Activa para operar en bicicleteros.'
                            : 'Disponible para administrar en tu cuenta.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ChipEstado(
                  texto: bicicleta.activa ? 'Activa' : 'Inactiva',
                  color: bicicleta.activa
                      ? ColoresUbb.exito
                      : ColoresUbb.textoSecundario,
                ),
              ],
            ),
            if (bicicleta.fotoUrl != null && bicicleta.fotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _mostrarFotoAmpliada(context, bicicleta.fotoUrl!),
                child: Stack(
                  children: [
                    _ImagenBicicleta(fotoReferencia: bicicleta.fotoUrl!),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.zoom_in_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _InfoBicicletaGrid(bicicleta: bicicleta),
            const SizedBox(height: 14),
            _BotonGestionBicicleta(
              expandido: gestionAbierta,
              onTap: () => setState(() => gestionAbierta = !gestionAbierta),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: gestionAbierta
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _PanelGestionBicicleta(
                bicicleta: bicicleta,
                onCambiarActiva: widget.onCambiarActiva,
                onEditar: widget.onEditar,
                onEliminar: widget.onEliminar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBicicletaGrid extends StatelessWidget {
  const _InfoBicicletaGrid({required this.bicicleta});

  final BicicletaApp bicicleta;

  @override
  Widget build(BuildContext context) {
    final estadoActual = bicicleta.dentroBicicletero
        ? 'En ${bicicleta.bicicleteroActualNombre ?? 'bicicletero'}'
        : 'Fuera del bicicletero';
    final datos = [
      _DatoBicicletaInfo(
          etiqueta: 'Marca', valor: _valorInformado(bicicleta.marca)),
      _DatoBicicletaInfo(
          etiqueta: 'Modelo', valor: _valorInformado(bicicleta.modelo)),
      _DatoBicicletaInfo(
          etiqueta: 'Color', valor: _valorInformado(bicicleta.color)),
      _DatoBicicletaInfo(
          etiqueta: 'Aro', valor: _valorInformado(bicicleta.aro)),
      _DatoBicicletaInfo(
          etiqueta: 'N° de serie',
          valor: _valorInformado(bicicleta.numeroSerie)),
      _DatoBicicletaInfo(etiqueta: 'Estado actual', valor: estadoActual),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth < 280 ? 1 : 2;
        const separacion = 10.0;
        final ancho =
            (constraints.maxWidth - (separacion * (columnas - 1))) / columnas;

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: datos
              .map(
                (dato) => SizedBox(
                  width: ancho,
                  child: dato,
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _valorInformado(String? valor) {
    final limpio = valor?.trim();
    return limpio == null || limpio.isEmpty ? 'No informado' : limpio;
  }
}

class _DatoBicicletaInfo extends StatelessWidget {
  const _DatoBicicletaInfo({
    required this.etiqueta,
    required this.valor,
  });

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresUbb.azulApp.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresUbb.azulApp.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresUbb.azulApp.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            softWrap: true,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ColoresUbb.azulNoche,
                ),
          ),
        ],
      ),
    );
  }
}

class _BotonGestionBicicleta extends StatelessWidget {
  const _BotonGestionBicicleta({
    required this.expandido,
    required this.onTap,
  });

  final bool expandido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColoresUbb.bordeFuerte),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, color: ColoresUbb.azulApp),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gestionar bicicleta',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColoresUbb.azulOscuro,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Icon(
                  expandido
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: ColoresUbb.textoSecundario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelGestionBicicleta extends StatelessWidget {
  const _PanelGestionBicicleta({
    required this.bicicleta,
    required this.onCambiarActiva,
    required this.onEditar,
    required this.onEliminar,
  });

  final BicicletaApp bicicleta;
  final ValueChanged<bool> onCambiarActiva;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColoresUbb.fondo,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColoresUbb.borde),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bicicleta.activa ? 'Activa' : 'Inactiva',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        Text(
                          'Solo una bicicleta puede quedar activa.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColoresUbb.textoSecundario,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: bicicleta.activa,
                    onChanged: (valor) => onCambiarActiva(valor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onEditar,
                      style: FilledButton.styleFrom(
                        backgroundColor: ColoresUbb.azulApp,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEliminar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColoresUbb.rojoInstitucional,
                        side: const BorderSide(
                          color: ColoresUbb.rojoInstitucional,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagenBicicleta extends StatelessWidget {
  const _ImagenBicicleta({required this.fotoReferencia});

  final String fotoReferencia;

  @override
  Widget build(BuildContext context) {
    final bytesFoto = decodificarFotoDataUrl(fotoReferencia);
    if (bytesFoto == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          resolverUrlFotoBicicleta(fotoReferencia),
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 150,
            width: double.infinity,
            color: ColoresUbb.superficieAzulSuave,
            child: const Icon(
              Icons.pedal_bike_outlined,
              color: ColoresUbb.azulApp,
              size: 46,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytesFoto,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
