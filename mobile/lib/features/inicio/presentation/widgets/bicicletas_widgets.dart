part of '../pantalla_principal.dart';

class _TarjetaBicicletaUsuario extends StatefulWidget {
  const _TarjetaBicicletaUsuario({
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
  State<_TarjetaBicicletaUsuario> createState() =>
      _TarjetaBicicletaUsuarioState();
}

class _TarjetaBicicletaUsuarioState extends State<_TarjetaBicicletaUsuario> {
  bool gestionAbierta = false;

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
                            ? 'Bicicleta principal de tu cuenta.'
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
            if (bicicleta.fotoUrl != null &&
                bicicleta.fotoUrl!.startsWith('data:image')) ...[
              const SizedBox(height: 14),
              _ImagenBicicleta(fotoDataUrl: bicicleta.fotoUrl!),
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
        icono: Icons.sell_outlined,
        etiqueta: 'Marca',
        valor: _valorInformado(bicicleta.marca),
      ),
      _DatoBicicletaInfo(
        icono: Icons.category_outlined,
        etiqueta: 'Modelo',
        valor: _valorInformado(bicicleta.modelo),
      ),
      _DatoBicicletaInfo(
        icono: Icons.palette_outlined,
        etiqueta: 'Color',
        valor: _valorInformado(bicicleta.color),
      ),
      _DatoBicicletaInfo(
        icono: Icons.circle_outlined,
        etiqueta: 'Aro',
        valor: _valorInformado(bicicleta.aro),
      ),
      _DatoBicicletaInfo(
        icono: Icons.confirmation_number_outlined,
        etiqueta: 'Serie',
        valor: _valorInformado(bicicleta.numeroSerie),
      ),
      _DatoBicicletaInfo(
        icono: bicicleta.dentroBicicletero
            ? Icons.lock_outline
            : Icons.lock_open_outlined,
        etiqueta: 'Estado actual',
        valor: estadoActual,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reducimos el breakpoint para asegurar que siempre use 2 columnas en teléfonos normales
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
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: ColoresUbb.azulApp, size: 20),
          const SizedBox(width: 8),
          Expanded(
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
                  const Icon(
                    Icons.radio_button_checked,
                    color: ColoresUbb.azulApp,
                  ),
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEliminar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresUbb.rojoInstitucional,
                      side: const BorderSide(
                        color: ColoresUbb.rojoInstitucional,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
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
  const _ImagenBicicleta({required this.fotoDataUrl});

  final String fotoDataUrl;

  @override
  Widget build(BuildContext context) {
    final bytesFoto = _decodificarFotoDataUrl(fotoDataUrl);
    if (bytesFoto == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 150,
          width: double.infinity,
          color: ColoresUbb.superficieAzulSuave,
          child: const Icon(
            Icons.pedal_bike_outlined,
            color: ColoresUbb.azulApp,
            size: 46,
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
