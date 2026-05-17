class ExcepcionApi implements Exception {
  const ExcepcionApi(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
