part of '../pantalla_principal.dart';

class VistaQrUsuario extends StatefulWidget {
  const VistaQrUsuario({super.key});

  @override
  State<VistaQrUsuario> createState() => _VistaQrUsuarioState();
}

class _VistaQrUsuarioState extends State<VistaQrUsuario> {
  final qrApi = QrApi();
  final bicicletaApi = BicicletaApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  QrTemporalApp? qrActual;
  BicicletaApp? bicicletaActiva;
  BicicleteroApp? bicicleteroSeleccionado;
  List<BicicleteroApp> bicicleteros = [];
  bool cargandoDatos = true;
  bool generando = false;
  int _generacionQr = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        bicicletaApi.obtenerActiva(),
        solicitudGuardiaApi.listarBicicleteros(),
      ]);

      if (mounted) {
        final bicicleta = resultados[0] as BicicletaApp?;
        final listaBicicleteros = resultados[1] as List<BicicleteroApp>;
        setState(() {
          bicicletaActiva = bicicleta;
          bicicleteros = listaBicicleteros;
          bicicleteroSeleccionado = listaBicicleteros.isEmpty
              ? null
              : listaBicicleteros.firstWhere(
                  (item) => item.cuposDisponibles > 0,
                  orElse: () => listaBicicleteros.first,
                );
          cargandoDatos = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => cargandoDatos = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = qrActual;
    final segundosRestantes = qr == null
        ? 0
        : qr.expiraEn.difference(DateTime.now()).inSeconds.clamp(0, 15);
    final bicicleta = bicicletaActiva;
    final tipoOperacion =
        bicicleta?.dentroBicicletero == true ? 'RETIRO' : 'INGRESO';
    final debeSeleccionarBicicletero = tipoOperacion == 'INGRESO';

    return RefreshIndicator(
      onRefresh: () => _cargarDatos(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          if (cargandoDatos)
            const Center(child: CircularProgressIndicator())
          else if (bicicleta == null)
            const EstadoLista(
              icono: Icons.pedal_bike,
              titulo: 'Sin bicicleta activa',
              detalle: 'Activa una bicicleta antes de generar QR.',
            )
          else ...[
            if (debeSeleccionarBicicletero)
              _SelectorBicicleteroQr(
                bicicleteros: bicicleteros,
                bicicleteroSeleccionado: bicicleteroSeleccionado,
                onChanged: (valor) =>
                    setState(() => bicicleteroSeleccionado = valor),
              ),
            const SizedBox(height: 24),
            _PanelQrUsuario(
              qr: qr,
              segundosRestantes: segundosRestantes,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ColoresUbb.azulApp,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: generando ||
                      cargandoDatos ||
                      (debeSeleccionarBicicletero &&
                          bicicleteroSeleccionado == null)
                  ? null
                  : _generarQr,
              icon: generando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                qr == null || segundosRestantes == 0
                    ? 'Generar QR'
                    : 'Regenerar QR',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generarQr() async {
    setState(() => generando = true);

    try {
      final tipo =
          bicicletaActiva?.dentroBicicletero == true ? 'RETIRO' : 'INGRESO';
      final qr = await qrApi.generar(
        bicicleteroId: tipo == 'INGRESO' ? bicicleteroSeleccionado?.id : null,
      );

      if (mounted) {
        _generacionQr++;
        setState(() => qrActual = qr);
        _programarActualizacion(_generacionQr);
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    } finally {
      if (mounted) {
        setState(() => generando = false);
      }
    }
  }

  void _programarActualizacion(int generacion) {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || qrActual == null || generacion != _generacionQr) {
        return;
      }

      setState(() {});

      if (qrActual!.expiraEn.isAfter(DateTime.now())) {
        _programarActualizacion(generacion);
      }
    });
  }
}

class _SelectorBicicleteroQr extends StatelessWidget {
  const _SelectorBicicleteroQr({
    required this.bicicleteros,
    required this.bicicleteroSeleccionado,
    required this.onChanged,
  });

  final List<BicicleteroApp> bicicleteros;
  final BicicleteroApp? bicicleteroSeleccionado;
  final ValueChanged<BicicleteroApp?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleccione el bicicletero a utilizar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresUbb.azulNoche,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColoresUbb.azulApp.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return DropdownAnclado<BicicleteroApp>(
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                menuMaxHeight: 300,
                value: bicicleteroSeleccionado,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: ColoresUbb.azulApp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                dropdownColor: Colors.white,
                items: bicicleteros
                    .map(
                      (bicicletero) => DropdownMenuItem(
                        value: bicicletero,
                        enabled: bicicletero.cuposDisponibles > 0,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${bicicletero.nombre} (${bicicletero.cuposDisponibles} cupos)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: bicicletero.cuposDisponibles > 0
                                      ? null
                                      : ColoresUbb.textoSecundario,
                                ),
                              ),
                            ),
                            if (bicicletero.cuposDisponibles == 0)
                              const Icon(
                                Icons.block_outlined,
                                size: 16,
                                color: ColoresUbb.rojoInstitucional,
                              ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PanelQrUsuario extends StatelessWidget {
  const _PanelQrUsuario({
    required this.qr,
    required this.segundosRestantes,
  });

  final QrTemporalApp? qr;
  final int segundosRestantes;

  @override
  Widget build(BuildContext context) {
    final qrActual = qr;

    return SizedBox(
      height: 396,
      width: double.infinity,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: qrActual == null
                ? const _QrPlaceholder()
                : _QrActivo(
                    token: qrActual.token,
                    segundosRestantes: segundosRestantes,
                  ),
          ),
        ),
      ),
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('qr-placeholder'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColoresUbb.azulApp.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_2,
              color: ColoresUbb.azulApp,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'QR no generado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona el bicicletero y genera el codigo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresUbb.textoSecundario,
                ),
          ),
        ],
      ),
    );
  }
}

class _QrActivo extends StatelessWidget {
  const _QrActivo({
    required this.token,
    required this.segundosRestantes,
  });

  final String token;
  final int segundosRestantes;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('qr-activo'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QrTemporal(
          token: token,
          segundosRestantes: segundosRestantes,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: segundosRestantes / 15,
            minHeight: 6,
            backgroundColor: ColoresUbb.bordeFuerte,
            valueColor: AlwaysStoppedAnimation(
              segundosRestantes > 5
                  ? ColoresUbb.azulApp
                  : ColoresUbb.rojoInstitucional,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ChipEstado(
          texto: segundosRestantes > 0
              ? 'Expira en $segundosRestantes s'
              : 'QR expirado',
          color: segundosRestantes > 0
              ? ColoresUbb.azulApp
              : ColoresUbb.rojoInstitucional,
        ),
      ],
    );
  }
}
