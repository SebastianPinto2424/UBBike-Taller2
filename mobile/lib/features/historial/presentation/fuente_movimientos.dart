import 'package:flutter/material.dart';
import 'package:ubbike/core/tema/colores_ubb.dart';
import 'package:ubbike/shared/modelos/movimiento_app.dart';
import 'package:ubbike/shared/widgets/chip_estado.dart';

class FuenteMovimientos extends DataTableSource {
  FuenteMovimientos({required this.movimientos});

  final List<MovimientoApp> movimientos;

  @override
  DataRow? getRow(int index) {
    if (index >= movimientos.length) return null;
    final movimiento = movimientos[index];
    final esIngreso = movimiento.tipo == 'INGRESO';
    final confirmado = movimiento.estado == 'CONFIRMADO';

    return DataRow(
      cells: [
        DataCell(
          ChipEstado(
            texto: esIngreso ? 'Ingreso' : 'Retiro',
            color: esIngreso ? ColoresUbb.azulApp : ColoresUbb.turquesa,
          ),
        ),
        DataCell(
          ChipEstado(
            texto: confirmado ? 'Confirmado' : 'Denegado',
            color: confirmado ? ColoresUbb.exito : ColoresUbb.rojoInstitucional,
          ),
        ),
        DataCell(Text(_formatearFecha(movimiento.creadoEn))),
        DataCell(Text(_formatearHora(movimiento.creadoEn))),
        DataCell(Text(movimiento.usuarioNombre)),
        DataCell(Text(movimiento.usuarioCorreo)),
        DataCell(Text(movimiento.usuarioRut ?? 'Sin RUT')),
        DataCell(Text(movimiento.bicicletaDescripcion)),
        DataCell(Text(movimiento.bicicleteroNombre)),
        DataCell(Text(movimiento.guardiaNombre)),
        DataCell(Text(_etiquetaOrigen(movimiento.origen))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => movimientos.length;

  @override
  int get selectedRowCount => 0;

  String _formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year}';
  }

  String _formatearHora(DateTime fecha) {
    final local = fecha.toLocal();
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  String _etiquetaOrigen(String origen) {
    return switch (origen) {
      'MANUAL' => 'Manual',
      'QR' => 'QR',
      _ => origen,
    };
  }
}
