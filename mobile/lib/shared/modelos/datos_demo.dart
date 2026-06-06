class BicicleteroDemo {
  const BicicleteroDemo({
    required this.nombre,
    required this.ubicacion,
    required this.guardiasAsignados,
    required this.ocupacion,
  });

  final String nombre;
  final String ubicacion;
  final int guardiasAsignados;
  final int ocupacion;
}

class BicicletaDemo {
  const BicicletaDemo({
    required this.descripcion,
    required this.estado,
    required this.codigo,
  });

  final String descripcion;
  final String estado;
  final String codigo;
}

class MovimientoDemo {
  const MovimientoDemo({
    required this.tipo,
    required this.bicicletero,
    required this.fecha,
    required this.guardian,
    required this.usuario,
    required this.correo,
    required this.rut,
  });

  final String tipo;
  final String bicicletero;
  final String fecha;
  final String guardian;
  final String usuario;
  final String correo;
  final String rut;
}

class SolicitudDemo {
  const SolicitudDemo({
    required this.bicicletero,
    required this.tipo,
    required this.estado,
    required this.tiempo,
  });

  final String bicicletero;
  final String tipo;
  final String estado;
  final String tiempo;
}

const bicicleterosDemo = [
  BicicleteroDemo(
    nombre: 'Bicicletero cercano al Centro de Idiomas',
    ubicacion: 'Sector Centro de Idiomas',
    guardiasAsignados: 1,
    ocupacion: 68,
  ),
  BicicleteroDemo(
    nombre: 'Bicicletero cercano a la FACE',
    ubicacion: 'Sector FACE',
    guardiasAsignados: 1,
    ocupacion: 42,
  ),
];

const bicicletasDemo = [
  BicicletaDemo(
    descripcion: 'Trek urbana gris',
    estado: 'Registrada',
    codigo: 'UBB-BIC-1842',
  ),
  BicicletaDemo(
    descripcion: 'Oxford azul aro 29',
    estado: 'Sin movimiento',
    codigo: 'UBB-BIC-2291',
  ),
];

const movimientosDemo = [
  MovimientoDemo(
    tipo: 'Ingreso',
    bicicletero: 'Bicicletero cercano al Centro de Idiomas',
    fecha: 'Hoy, 08:14',
    guardian: 'Guardia M. Salazar',
    usuario: 'Sebastian Pinto',
    correo: 'sebastian.pinto@alumnos.ubiobio.cl',
    rut: '20.123.456-7',
  ),
  MovimientoDemo(
    tipo: 'RETIRO',
    bicicletero: 'Bicicletero cercano a la FACE',
    fecha: 'Ayer, 18:02',
    guardian: 'Guardia C. Munoz',
    usuario: 'Camila Torres',
    correo: 'camila.torres@ubiobio.cl',
    rut: '18.765.432-1',
  ),
  MovimientoDemo(
    tipo: 'Ingreso',
    bicicletero: 'Bicicletero cercano a la FACE',
    fecha: 'Ayer, 09:23',
    guardian: 'Guardia C. Munoz',
    usuario: 'Sebastian Pinto',
    correo: 'sebastian.pinto@alumnos.ubiobio.cl',
    rut: '20.123.456-7',
  ),
];

const guardiasDemo = [
  'Guardia M. Salazar',
  'Guardia C. Munoz',
];

const solicitudesDemo = [
  SolicitudDemo(
    bicicletero: 'Bicicletero cercano al Centro de Idiomas',
    tipo: 'Requiere servicio',
    estado: 'Pendiente',
    tiempo: 'Hace 3 min',
  ),
  SolicitudDemo(
    bicicletero: 'Bicicletero cercano a la FACE',
    tipo: 'Guardia ausente',
    estado: 'En camino',
    tiempo: 'Hace 9 min',
  ),
];
