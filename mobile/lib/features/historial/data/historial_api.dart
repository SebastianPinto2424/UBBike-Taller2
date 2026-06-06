import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/modelos/movimiento_app.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

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

class HistorialApi {
  HistorialApi() : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  String _crearQuery({
    String? filtro,
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
    int? limite,
  }) {
    final parametros = <String>[];

    void agregar(String llave, String? valor) {
      if (valor != null && valor.trim().isNotEmpty && valor != 'TODOS') {
        parametros.add('$llave=${Uri.encodeQueryComponent(valor.trim())}');
      }
    }

    String fecha(DateTime valor) {
      final local = DateTime(valor.year, valor.month, valor.day);
      final mes = local.month.toString().padLeft(2, '0');
      final dia = local.day.toString().padLeft(2, '0');
      return '${local.year}-$mes-$dia';
    }

    agregar('q', filtro);
    agregar('periodo', desde == null && hasta == null ? periodo : null);
    agregar('desde', desde == null ? null : fecha(desde));
    agregar('hasta', hasta == null ? null : fecha(hasta));
    agregar('tipo', tipo);
    agregar('estado', estado);
    agregar('bicicleteroId', bicicleteroId);
    agregar('guardiaId', guardiaId);
    agregar('origen', origen);
    if (limite != null && limite > 0) {
      parametros.add('limit=$limite');
    }

    return parametros.isEmpty ? '' : '?${parametros.join('&')}';
  }

  Future<List<MovimientoApp>> listar({
    String? filtro,
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
    int? limite,
  }) async {
    final query = _crearQuery(
      filtro: filtro,
      periodo: periodo,
      desde: desde,
      hasta: hasta,
      tipo: tipo,
      estado: estado,
      bicicleteroId: bicicleteroId,
      guardiaId: guardiaId,
      origen: origen,
      limite: limite,
    );
    final respuesta = await cliente.get('/historial$query');
    final datos =
        (respuesta['movimientos'] ?? respuesta['datos']) as List<dynamic>;
    return datos
        .map((item) => MovimientoApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ResumenHistorialApp> resumen({
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
  }) async {
    final query = _crearQuery(
      periodo: periodo,
      desde: desde,
      hasta: hasta,
      tipo: tipo,
      estado: estado,
      bicicleteroId: bicicleteroId,
      guardiaId: guardiaId,
      origen: origen,
    );
    final respuesta = await cliente.get('/historial/resumen$query');
    return ResumenHistorialApp.desdeJson(
      respuesta['resumen'] as Map<String, dynamic>,
    );
  }

  Future<OpcionesHistorialApp> opciones() async {
    final respuesta = await cliente.get('/historial/opciones');
    return OpcionesHistorialApp.desdeJson(respuesta);
  }

  Future<String> exportarExcel({
    String? filtro,
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
  }) {
    final query = _crearQuery(
      filtro: filtro,
      periodo: periodo,
      desde: desde,
      hasta: hasta,
      tipo: tipo,
      estado: estado,
      bicicleteroId: bicicleteroId,
      guardiaId: guardiaId,
      origen: origen,
    );
    return cliente.getTexto('/historial/exportar-excel$query');
  }
}
