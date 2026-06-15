import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/modelos/usuario_app.dart';

class IncidenciaApp {
  const IncidenciaApp({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.estado,
    required this.creadaEn,
    required this.actualizadaEn,
    required this.bicicletero,
    required this.reportadaPorUsuario,
    this.bicicleta,
    this.gestionadaPorUsuario,
    this.respuesta,
    this.resueltaEn,
  });

  final String id;
  final String tipo;
  final String descripcion;
  final String estado;
  final String? respuesta;
  final DateTime creadaEn;
  final DateTime actualizadaEn;
  final DateTime? resueltaEn;
  final BicicleteroApp bicicletero;
  final BicicletaApp? bicicleta;
  final UsuarioApp reportadaPorUsuario;
  final UsuarioApp? gestionadaPorUsuario;

  factory IncidenciaApp.desdeJson(Map<String, dynamic> json) {
    final bicicleta = json['bicicleta'] as Map<String, dynamic>?;
    final gestionadaPorUsuario =
        json['gestionadaPorUsuario'] as Map<String, dynamic>?;

    return IncidenciaApp(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      estado: json['estado'] as String,
      respuesta: json['respuesta'] as String?,
      creadaEn: DateTime.parse(json['creadaEn'] as String),
      actualizadaEn: DateTime.parse(json['actualizadaEn'] as String),
      resueltaEn: json['resueltaEn'] == null
          ? null
          : DateTime.parse(json['resueltaEn'] as String),
      bicicletero: BicicleteroApp.desdeJson(
        json['bicicletero'] as Map<String, dynamic>,
      ),
      bicicleta: bicicleta == null ? null : BicicletaApp.desdeJson(bicicleta),
      reportadaPorUsuario: UsuarioApp.desdeJson(
        json['reportadaPorUsuario'] as Map<String, dynamic>,
      ),
      gestionadaPorUsuario: gestionadaPorUsuario == null
          ? null
          : UsuarioApp.desdeJson(gestionadaPorUsuario),
    );
  }
}
