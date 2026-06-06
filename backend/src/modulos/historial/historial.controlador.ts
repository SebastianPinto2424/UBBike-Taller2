import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import { controladorAsync } from '../../comun/utils/controlador-async';
import { listarMovimientos, opcionesHistorial, resumenHistorial } from './historial.servicio';

const crearFiltrosHistorial = (req: SolicitudAutenticada, limite: number, pagina: number) => ({
  usuarioId: req.usuario!.usuarioId,
  rol: req.usuario!.rol,
  q: req.query.q?.toString(),
  periodo: req.query.periodo as 'DIA' | 'SEMANA' | 'MES' | 'ANIO' | undefined,
  desde: req.query.desde?.toString(),
  hasta: req.query.hasta?.toString(),
  tipo: req.query.tipo as 'INGRESO' | 'RETIRO' | 'TODOS' | undefined,
  estado: req.query.estado as 'CONFIRMADO' | 'DENEGADO' | 'TODOS' | undefined,
  bicicleteroId: req.query.bicicleteroId?.toString(),
  guardiaId: req.query.guardiaId?.toString(),
  origen: req.query.origen as 'QR' | 'MANUAL' | 'TODOS' | undefined,
  limite,
  pagina
});

export const listar = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const limite = req.query.limit ? parseInt(req.query.limit as string) : 100;
  const pagina = req.query.page ? parseInt(req.query.page as string) : 1;
  const resultado = await listarMovimientos(crearFiltrosHistorial(req, limite, pagina));

  return res.status(200).json(resultado);
});

export const resumen = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const datos = await resumenHistorial(crearFiltrosHistorial(req, 100000, 1));
  return res.status(200).json({ resumen: datos });
});

export const opciones = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const datos = await opcionesHistorial(req.usuario!.rol);
  return res.status(200).json(datos);
});

const escaparExcel = (valor: string) =>
  valor.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

export const exportarExcel = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const resultado = await listarMovimientos(crearFiltrosHistorial(req, 100000, 1));

  const encabezados = [
    'ID',
    'Tipo',
    'Estado',
    'Usuario Nombre',
    'Usuario Correo',
    'Usuario RUT',
    'Bicicleta',
    'Bicicletero',
    'Guardia Validador',
    'Guardia Correo',
    'Motivo Denegacion',
    'Comentario Guardia',
    'Origen',
    'Fecha Creacion'
  ];
  const filas = resultado.datos
    .map((movimiento) =>
      [
        movimiento.id,
        movimiento.tipo,
        movimiento.estado,
        movimiento.usuario.nombre,
        movimiento.usuario.correo,
        movimiento.usuario.rut || '-',
        movimiento.bicicleta.descripcion,
        movimiento.bicicletero?.nombre || '-',
        movimiento.guardia?.nombre || '-',
        movimiento.guardia?.correo || '-',
        movimiento.motivoDenegacion || '-',
        movimiento.comentarioGuardia || '-',
        movimiento.origen,
        movimiento.creadoEn.toISOString()
      ]
        .map((valor) => `<td>${escaparExcel(valor)}</td>`)
        .join('')
    )
    .map((fila) => `<tr>${fila}</tr>`)
    .join('');
  const html = `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    table { border-collapse: collapse; font-family: Arial, sans-serif; }
    th { background: #014898; color: white; font-weight: bold; }
    th, td { border: 1px solid #9ca3af; padding: 8px; }
  </style>
</head>
<body>
  <h2>Reporte de Movimientos UBBike</h2>
  <table>
    <tr>${encabezados.map((valor) => `<th>${escaparExcel(valor)}</th>`).join('')}</tr>
    ${filas}
  </table>
</body>
</html>`;

  res.header('Content-Type', 'application/vnd.ms-excel; charset=utf-8');
  res.attachment('historial-movimientos-ubbike.xls');
  return res.send(html);
});
