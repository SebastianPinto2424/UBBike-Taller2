import { ErrorRequestHandler } from 'express';
import { ErrorHttp } from '../errors/error-http';

export const middlewareErrores: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof ErrorHttp) {
    return res.status(error.statusCode).json({
      message: error.message
    });
  }

  console.error(error);

  return res.status(500).json({
    message: 'Error interno del servidor'
  });
};
