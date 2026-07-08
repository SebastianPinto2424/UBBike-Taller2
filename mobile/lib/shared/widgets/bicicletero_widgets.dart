import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ubbike/core/tema/colores_ubb.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';

class TarjetaBicicleteroApp extends StatelessWidget {
  const TarjetaBicicleteroApp({super.key, required this.bicicletero});

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
        padding: const EdgeInsets.all(14),
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
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  height: 66,
                  width: 66,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: bicicletero.ocupados == 0 ? 0 : 3,
                          centerSpaceRadius: 20,
                          sections: [
                            PieChartSectionData(
                              value: bicicletero.ocupados.toDouble(),
                              color: colorOcupado,
                              title: '',
                              radius: 10,
                            ),
                            PieChartSectionData(
                              value: bicicletero.cuposDisponibles.toDouble(),
                              color: Colors.grey.shade300,
                              title: '',
                              radius: 10,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${bicicletero.porcentajeUso}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorOcupado,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DatoCompactoIcono(
                        etiqueta: 'Disponibles',
                        valor: '${bicicletero.cuposDisponibles}',
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      DatoCompactoIcono(
                        etiqueta: 'Ocupados',
                        valor: '${bicicletero.ocupados}',
                        color: colorOcupado,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DatoCompactoIcono extends StatelessWidget {
  const DatoCompactoIcono({
    super.key,
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
