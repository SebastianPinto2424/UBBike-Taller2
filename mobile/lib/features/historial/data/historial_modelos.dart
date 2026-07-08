import 'package:ubbike/shared/modelos/bicicletero_app.dart';
import 'package:ubbike/shared/modelos/usuario_app.dart';

class ResumenHistorialApp {
  const ResumenHistorialApp({
    required this.totalMovimientos,
    required this.ingresos,
    required this.retiros,
    required this.confirmados,
    required this.denegados,
    required this.manuales,
    required this.qr,
    required this.operacionesPorGuardia,
    required this.operacionesPorBicicletero,
  });

  final int totalMovimientos;
  final int ingresos;
  final int retiros;
  final int confirmados;
  final int denegados;
  final int manuales;
  final int qr;
  final Map<String, int> operacionesPorGuardia;
  final Map<String, int> operacionesPorBicicletero;

  factory ResumenHistorialApp.desdeJson(Map<String, dynamic> json) {
    Map<String, int> mapa(String llave) {
      final datos = json[llave] as Map<String, dynamic>? ?? const {};
      return datos.map((clave, valor) => MapEntry(clave, valor as int));
    }

    return ResumenHistorialApp(
      totalMovimientos: json['totalMovimientos'] as int? ?? 0,
      ingresos: json['ingresos'] as int? ?? 0,
      retiros: json['retiros'] as int? ?? 0,
      confirmados: json['confirmados'] as int? ?? 0,
      denegados: json['denegados'] as int? ?? 0,
      manuales: json['manuales'] as int? ?? 0,
      qr: json['qr'] as int? ?? 0,
      operacionesPorGuardia: mapa('operacionesPorGuardia'),
      operacionesPorBicicletero: mapa('operacionesPorBicicletero'),
    );
  }
}

class OpcionesHistorialApp {
  const OpcionesHistorialApp({
    required this.bicicleteros,
    required this.guardias,
  });

  final List<BicicleteroApp> bicicleteros;
  final List<UsuarioApp> guardias;

  factory OpcionesHistorialApp.desdeJson(Map<String, dynamic> json) {
    return OpcionesHistorialApp(
      bicicleteros: (json['bicicleteros'] as List<dynamic>? ?? const [])
          .map((item) => BicicleteroApp.desdeJson(item as Map<String, dynamic>))
          .toList(),
      guardias: (json['guardias'] as List<dynamic>? ?? const [])
          .map((item) => UsuarioApp.desdeJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
