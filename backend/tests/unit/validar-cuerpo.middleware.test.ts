import express from 'express';
import Joi from 'joi';
import request from 'supertest';
import { validarCuerpo } from '../../src/comun/middlewares/validar-cuerpo.middleware';

const crearAppPrueba = () => {
  const app = express();
  app.use(express.json());
  app.post(
    '/validar',
    validarCuerpo(
      Joi.object({
        nombre: Joi.string().trim().min(3).required(),
        activo: Joi.boolean().default(false)
      })
    ),
    (req, res) => res.status(200).json({ body: req.body })
  );
  return app;
};

describe('validarCuerpo middleware · caja negra', () => {
  it('responde 400 y reporta todos los errores de validacion', async () => {
    const res = await request(crearAppPrueba()).post('/validar').send({
      nombre: 'ab',
      activo: 'no-es-booleano'
    });

    expect(res.status).toBe(400);
    expect(res.body.message).toBe('Datos inválidos');
    expect(res.body.details).toHaveLength(2);
  });

  it('normaliza el body valido, aplica defaults y elimina campos desconocidos', async () => {
    const res = await request(crearAppPrueba()).post('/validar').send({
      nombre: '  Usuario prueba  ',
      campoExtra: 'debe salir'
    });

    expect(res.status).toBe(200);
    expect(res.body.body).toEqual({
      nombre: 'Usuario prueba',
      activo: false
    });
  });
});
