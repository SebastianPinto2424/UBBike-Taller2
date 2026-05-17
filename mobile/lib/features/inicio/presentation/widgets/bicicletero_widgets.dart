part of '../pantalla_principal.dart';

class _TarjetaBicicleteroApp extends StatelessWidget {
  const _TarjetaBicicleteroApp({required this.bicicletero});

  final BicicleteroApp bicicletero;

  @override
  Widget build(BuildContext context) {
    final uso = (bicicletero.porcentajeUso / 100).clamp(0.0, 1.0);
    final colorOcupado =
        uso >= 0.9 ? ColoresUbb.rojoInstitucional : ColoresUbb.azulApp;

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColoresUbb.azulApp.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      color: ColoresUbb.azulApp, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bicicletero.nombre,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bicicletero.ubicacion,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                ChipEstado(
                  texto: '${bicicletero.porcentajeUso}%',
                  color: colorOcupado,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: uso,
                minHeight: 10,
                backgroundColor: ColoresUbb.superficieAzulSuave,
                valueColor: AlwaysStoppedAnimation<Color>(colorOcupado),
              ),
            ),
            const SizedBox(height: 14),
            _DatoCompactoIcono(
              etiqueta: 'Cupos disponibles',
              valor: '${bicicletero.cuposDisponibles}',
              color: ColoresUbb.exito,
            ),
            const SizedBox(height: 10),
            _DatoCompactoIcono(
              etiqueta: 'Bicicletas registradas dentro',
              valor: '${bicicletero.ocupados}/${bicicletero.capacidad}',
              color: colorOcupado,
            ),
          ],
        ),
      ),
    );
  }
}

class _DatoCompactoIcono extends StatelessWidget {
  const _DatoCompactoIcono({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresUbb.textoSecundario,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Text(
          valor,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
