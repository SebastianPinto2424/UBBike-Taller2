import { NextFunction, Request, Response } from 'express';
import { ObjectSchema } from 'joi';

export const validarCuerpo =
  (esquema: ObjectSchema) => (req: Request, res: Response, next: NextFunction) => {
    const { error, value } = esquema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      return res.status(400).json({
        message: 'Datos inválidos',
        details: error.details.map((detail) => detail.message)
      });
    }

    req.body = value;
    return next();
  };
