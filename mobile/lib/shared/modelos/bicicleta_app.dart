class BicicletaApp {
  const BicicletaApp({
    required this.id,
    required this.descripcion,
    required this.activa,
    required this.dentroBicicletero,
    this.marca,
    this.modelo,
    this.color,
    this.aro,
    this.numeroSerie,
    this.fotoUrl,
    this.bicicleteroActualNombre,
  });

  final String id;
  final String descripcion;
  final String? marca;
  final String? modelo;
  final String? color;
  final String? aro;
  final String? numeroSerie;
  final String? fotoUrl;
  final bool activa;
  final bool dentroBicicletero;
  final String? bicicleteroActualNombre;

  factory BicicletaApp.desdeJson(Map<String, dynamic> json) {
    final bicicleteroActual =
        json['bicicleteroActual'] as Map<String, dynamic>?;

    return BicicletaApp(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      color: json['color'] as String?,
      aro: json['aro'] as String?,
      numeroSerie: json['numeroSerie'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      activa: json['activa'] as bool? ?? false,
      dentroBicicletero: json['dentroBicicletero'] as bool? ?? false,
      bicicleteroActualNombre: bicicleteroActual?['nombre'] as String?,
    );
  }
}
