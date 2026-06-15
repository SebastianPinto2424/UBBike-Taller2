import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/modelos/usuario_app.dart';

class QrValidadoApp {
  const QrValidadoApp({
    required this.token,
    required this.tipo,
    required this.expiraEn,
    required this.usuarioNombre,
    required this.usuarioCorreo,
    required this.usuarioRut,
    required this.bicicletaDescripcion,
    this.bicicletaMarca,
    this.bicicletaModelo,
    this.bicicletaColor,
    this.bicicletaAro,
    this.bicicletaNumeroSerie,
    this.bicicletaFotoUrl,
    this.bicicleteroNombre,
  });

  final String token;
  final String tipo;
  final DateTime expiraEn;
  final String usuarioNombre;
  final String usuarioCorreo;
  final String? usuarioRut;
  final String bicicletaDescripcion;
  final String? bicicletaMarca;
  final String? bicicletaModelo;
  final String? bicicletaColor;
  final String? bicicletaAro;
  final String? bicicletaNumeroSerie;
  final String? bicicletaFotoUrl;
  final String? bicicleteroNombre;

  factory QrValidadoApp.desdeJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>;
    final bicicleta = json['bicicleta'] as Map<String, dynamic>;
    final bicicletero = json['bicicletero'] as Map<String, dynamic>?;

    return QrValidadoApp(
      token: json['token'] as String,
      tipo: json['tipo'] as String,
      expiraEn: DateTime.parse(json['expiraEn'] as String),
      usuarioNombre: usuario['nombre'] as String,
      usuarioCorreo: usuario['correo'] as String,
      usuarioRut: usuario['rut'] as String?,
      bicicletaDescripcion: bicicleta['descripcion'] as String,
      bicicletaMarca: bicicleta['marca'] as String?,
      bicicletaModelo: bicicleta['modelo'] as String?,
      bicicletaColor: bicicleta['color'] as String?,
      bicicletaAro: bicicleta['aro'] as String?,
      bicicletaNumeroSerie: bicicleta['numeroSerie'] as String?,
      bicicletaFotoUrl: bicicleta['fotoUrl'] as String?,
      bicicleteroNombre: bicicletero?['nombre'] as String?,
    );
  }
}

class CoincidenciaManualApp {
  const CoincidenciaManualApp({
    required this.usuario,
    required this.bicicletas,
  });

  final UsuarioApp usuario;
  final List<BicicletaApp> bicicletas;

  factory CoincidenciaManualApp.desdeJson(Map<String, dynamic> json) {
    final bicicletasJson = json['bicicletas'] as List<dynamic>? ?? const [];

    return CoincidenciaManualApp(
      usuario: UsuarioApp.desdeJson(json['usuario'] as Map<String, dynamic>),
      bicicletas: bicicletasJson
          .map((item) => BicicletaApp.desdeJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
