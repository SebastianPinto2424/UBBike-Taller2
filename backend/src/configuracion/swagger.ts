import swaggerJsdoc from 'swagger-jsdoc';

const opciones: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.3',
    info: {
      title: 'UBBike API',
      version: '1.0.0',
      description:
        'API REST para el sistema de gestión de bicicleteros de la Universidad del Bío-Bío. ' +
        'Permite a estudiantes y funcionarios registrar sus bicicletas, generar códigos QR para ' +
        'ingresos y retiros, y solicitar asistencia de guardias.'
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Desarrollo local'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Token JWT obtenido desde POST /autenticacion/login'
        }
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            message: { type: 'string', example: 'Descripcion del error' }
          }
        },
        Usuario: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            nombre: { type: 'string' },
            correo: { type: 'string', format: 'email' },
            rut: { type: 'string', nullable: true },
            rol: {
              type: 'string',
              enum: ['ESTUDIANTE', 'FUNCIONARIO', 'GUARDIA', 'ADMIN_CENTRAL', 'ADMINISTRADOR']
            },
            correoVerificado: { type: 'boolean' },
            cuentaActiva: { type: 'boolean' },
            creadoEn: { type: 'string', format: 'date-time' }
          }
        },
        Bicicleta: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            descripcion: { type: 'string' },
            marca: { type: 'string', nullable: true },
            modelo: { type: 'string', nullable: true },
            color: { type: 'string', nullable: true },
            aro: { type: 'string', nullable: true },
            numeroSerie: { type: 'string', nullable: true },
            fotoUrl: { type: 'string', nullable: true },
            activa: { type: 'boolean' },
            dentroBicicletero: { type: 'boolean' }
          }
        },
        Movimiento: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            tipo: { type: 'string', enum: ['INGRESO', 'RETIRO'] },
            estado: { type: 'string', enum: ['CONFIRMADO', 'DENEGADO'] },
            origen: { type: 'string', enum: ['QR', 'MANUAL'] },
            creadoEn: { type: 'string', format: 'date-time' },
            motivoDenegacion: { type: 'string', nullable: true },
            comentarioGuardia: { type: 'string', nullable: true }
          }
        },
        Notificacion: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            titulo: { type: 'string' },
            mensaje: { type: 'string' },
            tipo: { type: 'string' },
            leida: { type: 'boolean' },
            creadaEn: { type: 'string', format: 'date-time' }
          }
        },
        PaginacionCursor: {
          type: 'object',
          properties: {
            nextCursor: {
              type: 'string',
              nullable: true,
              description: 'ID para la siguiente pagina'
            }
          }
        }
      }
    },
    security: [{ bearerAuth: [] }],
    tags: [
      { name: 'Autenticacion', description: 'Registro, login, refresh token y perfil' },
      { name: 'QR', description: 'Generacion y validacion de codigos QR temporales' },
      { name: 'Accesos', description: 'Confirmacion y denegacion de movimientos' },
      { name: 'Bicicletas', description: 'Gestion de bicicletas del usuario' },
      { name: 'Bicicleteros', description: 'Consulta de bicicleteros disponibles' },
      { name: 'Historial', description: 'Historial de movimientos' },
      { name: 'Notificaciones', description: 'Notificaciones del usuario' },
      { name: 'Incidencias', description: 'Reporte y gestion de incidencias' },
      { name: 'Solicitudes Guardia', description: 'Solicitudes de asistencia de guardia' }
    ]
  },
  apis: ['./src/modulos/**/*.rutas.ts', './src/modulos/**/*.controlador.ts']
};

export const especificacionSwagger = swaggerJsdoc(opciones);
