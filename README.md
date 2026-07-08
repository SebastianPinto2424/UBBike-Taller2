# UBBike

Aplicacion web/mobile y API REST para registrar bicicletas, validar ingresos y retiros en bicicleteros, y mantener trazabilidad operativa para la Universidad del Bio-Bio.

## Alcance de la entrega

La entrega funcional se valida con estos roles:

| Rol | Cuenta demo | Funciones principales |
| --- | --- | --- |
| Usuario | `estudiante@alumnos.ubiobio.cl` | Registrar bicicleta, seleccionar bicicleta activa, generar QR, revisar historial, solicitar apoyo y gestionar perfil. |
| Guardia | `guardia@ubiobio.cl` | Seleccionar bicicletero de turno, validar QR, registrar movimientos manuales, atender solicitudes y revisar historial. |
| Administrador | `administrador@ubiobio.cl` | Gestionar usuarios, validar operaciones, revisar soporte, administrar solicitudes y usar herramientas de control. |

Contrasena demo local:

```text
UBBike2026*
```

En produccion debe usarse `SEED_DEMO_DATA=false`.

## Estructura

- `backend/`: API REST con Node.js, Express, Prisma y PostgreSQL.
- `mobile/`: aplicacion Flutter para Web y Android.
- `deploy/`: plantillas para produccion sin Docker.
- `docs/`: documentacion tecnica complementaria.

## Ejecucion local con Docker

Requisitos:

- Docker Desktop o Docker Engine con Docker Compose.
- Git.
- Navegador web.
- Flutter solo si se compila APK o se ejecuta la app fuera de Docker.

Levantar el entorno local:

```bash
docker compose up -d --build
```

Verificar:

```bash
docker compose ps
```

Accesos locales por defecto:

| Servicio | URL |
| --- | --- |
| Web Flutter | `http://localhost:8082` |
| Backend health | `http://localhost:3001/health` |
| PostgreSQL local | `127.0.0.1:5433` |

Detener:

```bash
docker compose down
```

## APK demo en red Wi-Fi

Para probar desde celulares reales, conecta el PC y los celulares a la misma red Wi-Fi y ejecuta:

```powershell
.\preparar-demo.ps1
```

El script detecta la IP local, actualiza `.env`, levanta Docker, verifica el backend y genera una APK debug para prueba local en:

```text
C:\Users\sebas\Desktop\apks-pruebas\ubbike-taller.apk
```

Antes de instalar la APK, abre desde el celular:

```text
http://IP_DEL_PC:3000/salud
```

Si no responde, ejecuta el script una vez como administrador o habilita el puerto TCP 3000 en el Firewall de Windows. Esta APK es solo para demo local por HTTP; la APK de produccion debe compilarse en release apuntando a HTTPS.

## Produccion sin Docker

La produccion se despliega sin Docker usando:

- Apache como servidor HTTPS y proxy reverso.
- Node.js 20 para el backend.
- PostgreSQL institucional externo.
- Flutter Web compilado como archivos estaticos.
- systemd para mantener el backend activo.

Las plantillas incluidas son:

| Archivo | Uso |
| --- | --- |
| `backend/.env.production.example` | Variables requeridas por el backend en produccion. |
| `deploy/apache/ubbike-https.conf.example` | VirtualHost Apache con HTTPS, Flutter Web y proxy al backend. |
| `deploy/systemd/ubbike-backend.service.example` | Servicio systemd para ejecutar `node dist/servidor.js`. |

Nunca subas `.env`, credenciales, certificados privados, APKs ni archivos de Firebase reales.

### HTTPS

Produccion debe usar HTTPS. La app Android y Flutter Web deben compilarse apuntando al origen publico seguro:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://DOMINIO_O_IP_PUBLICA
flutter build apk --release --dart-define=API_BASE_URL=https://DOMINIO_O_IP_PUBLICA
```

Recomendado: solicitar un dominio o subdominio institucional apuntando al servidor y emitir certificado con Certbot/Let's Encrypt.

Si solo se usa IP publica, Let's Encrypt permite certificados para IP desde 2026, pero son certificados short-lived y requieren automatizacion frecuente. Certbot puede obtenerlos con `--ip-address`, aunque la instalacion automatica en Apache todavia no es igual al flujo de dominios. Para una entrega estable, es preferible usar dominio institucional.

Fuentes:

- `https://certbot.eff.org/instructions?os=snap&ws=apache`
- `https://letsencrypt.org/2026/03/11/shorter-certs-certbot`

### Variables de entorno

En el servidor crea:

```bash
/opt/ubbike/backend/.env
```

Usa `backend/.env.production.example` como base y completa los valores reales:

```env
NODE_ENV=production
PORT=3000
TRUST_PROXY=loopback
DB_HOST=<HOST_DB_INSTITUCIONAL>
DB_PORT=5432
DB_USER=<USUARIO_DB>
DB_PASSWORD=<PASSWORD_DB>
DB_NAME=<NOMBRE_DB>
JWT_SECRET=<SECRETO_LARGO_MINIMO_32_CARACTERES>
FRONTEND_URL=https://DOMINIO_O_IP_PUBLICA
CORS_ORIGINS=https://DOMINIO_O_IP_PUBLICA
SEED_DEMO_DATA=false
SWAGGER_ENABLED=false
UPLOADS_DIR=/opt/ubbike/uploads
UPLOADS_PUBLIC_PATH=/uploads
```

### Compilacion backend

Desde el servidor:

```bash
cd /opt/ubbike/backend
npm ci
npm run build
npm run migrate
```

### Servicio backend

Copiar la plantilla:

```bash
sudo cp /opt/ubbike/deploy/systemd/ubbike-backend.service.example /etc/systemd/system/ubbike-backend.service
sudo systemctl daemon-reload
sudo systemctl enable --now ubbike-backend
sudo systemctl status ubbike-backend
```

### Compilacion Flutter Web

Desde el servidor si Flutter esta instalado:

```bash
cd /opt/ubbike/mobile
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://DOMINIO_O_IP_PUBLICA
sudo rsync -a --delete build/web/ /var/www/ubbike/
```

Si Flutter no esta instalado en el servidor, compila localmente y sube `mobile/build/web/` a `/var/www/ubbike/`.

### Apache

Habilitar modulos:

```bash
sudo a2enmod ssl headers rewrite proxy proxy_http proxy_wstunnel
```

Copiar la plantilla:

```bash
sudo cp /opt/ubbike/deploy/apache/ubbike-https.conf.example /etc/apache2/sites-available/ubbike.conf
```

Editar:

```bash
sudo nano /etc/apache2/sites-available/ubbike.conf
```

Reemplazar `DOMINIO_O_IP_PUBLICA` por el origen HTTPS real.

Activar:

```bash
sudo a2ensite ubbike.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### Verificacion produccion

```bash
curl -I https://DOMINIO_O_IP_PUBLICA
curl https://DOMINIO_O_IP_PUBLICA/salud
sudo systemctl status ubbike-backend
sudo journalctl -u ubbike-backend -f
```

## Validaciones antes de subir

Backend:

```bash
cd backend
npm run typecheck
npm test
```

Mobile:

```bash
cd mobile
flutter analyze
```

## Seguridad

- `JWT_SECRET` debe tener al menos 32 caracteres y ser unico.
- `SEED_DEMO_DATA=false` en produccion.
- PostgreSQL no debe exponerse publicamente desde el servidor de la app.
- No publicar `.env`, certificados, llaves privadas ni credenciales.
- Usar HTTPS para web, API, WebSocket y APK.
- Configurar SMTP real para correos.
- Mantener backups de base de datos y uploads.

## Documentacion adicional

- `docs/desarrollo-y-api.md`
- `docs/modelo-relacional.md`
