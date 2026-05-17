import { createClient, RedisClientType } from 'redis';
import { entorno } from './entorno';

let cliente: RedisClientType | null = null;
let promesaConexion: Promise<RedisClientType> | null = null;

export const obtenerClienteRedis = async (): Promise<RedisClientType | null> => {
  if (!entorno.redis.url) {
    return null;
  }

  if (cliente?.isOpen) {
    return cliente;
  }

  if (!promesaConexion) {
    cliente = createClient({
      url: entorno.redis.url
    });

    cliente.on('error', (error) => {
      console.error('Redis no disponible para rate limiting', error);
    });

    promesaConexion = cliente
      .connect()
      .then(() => cliente as RedisClientType)
      .catch((error) => {
        cliente = null;
        promesaConexion = null;
        throw error;
      });
  }

  return promesaConexion;
};
