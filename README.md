# Salad AI

Contenedor GPU basado en **Ubuntu 24.04**, **CUDA 12.8.1** y **cuDNN 9** para ejecutar un escritorio remoto XFCE mediante TurboVNC y noVNC.

Incluye:

* Firefox oficial con reproducción HTML5.
* FFmpeg y códecs multimedia.
* code-server.
* Python 3.12 con entorno virtual en `/opt/venv`.
* TensorFlow, ONNX Runtime GPU, InsightFace, OpenCV y PySide6.
* Configuración de privacidad y telemetría conocida deshabilitada.
* Compatibilidad con Salad Cloud mediante IPv6 interno.

## Imagen pública

```text
docker.io/westerterrazas/salad-ai:ai-v3
```

Para producción debe utilizarse un tag versionado, no depender exclusivamente de `latest`.

## Servicios

| Servicio     | Dirección interna | Puerto |
| ------------ | ----------------- | -----: |
| noVNC / XFCE | `[::]`            |   6080 |
| TurboVNC     | `127.0.0.1`       |   5901 |
| code-server  | `127.0.0.1`       |   8080 |

Solo el puerto `6080` se publica de forma predeterminada.

code-server permanece accesible únicamente dentro del contenedor hasta que se implemente un proxy autenticado independiente.

## Variables de entorno

### Obligatorias

```text
VNC_PASSWORD=clave-vnc
CODE_PASSWORD=clave-code-server-distinta
```

TurboVNC utiliza únicamente los primeros ocho caracteres de `VNC_PASSWORD`.

### Opcionales

```text
ENABLE_CODE_SERVER=true
REQUIRE_GPU=false
VNC_GEOMETRY=1920x1080
CODE_SERVER_BIND=127.0.0.1:8080
```

En Salad con GPU:

```text
REQUIRE_GPU=true
```

## Construcción local

```bash
docker buildx build \
  --platform linux/amd64 \
  --provenance=false \
  --sbom=false \
  --tag salad-ai:local \
  --load \
  .
```

## Ejecución local

Sin GPU:

```bash
docker run --rm \
  --name salad-ai \
  --shm-size=2g \
  -e VNC_PASSWORD='ClaveVNC' \
  -e CODE_PASSWORD='ClaveCodeDistinta' \
  -e REQUIRE_GPU=false \
  -p 6080:6080 \
  salad-ai:local
```

Con GPU NVIDIA:

```bash
docker run --rm \
  --name salad-ai \
  --gpus all \
  --shm-size=2g \
  -e VNC_PASSWORD='ClaveVNC' \
  -e CODE_PASSWORD='ClaveCodeDistinta' \
  -e REQUIRE_GPU=true \
  -p 6080:6080 \
  salad-ai:local
```

Acceso local:

```text
http://localhost:6080/
```

## Publicación manual en Docker Hub

La publicación se realiza desde Codespaces o una terminal autenticada:

```bash
docker login
```

```bash
docker buildx build \
  --builder salad-builder \
  --platform linux/amd64 \
  --provenance=false \
  --sbom=false \
  --tag westerterrazas/salad-ai:ai-v3 \
  --tag westerterrazas/salad-ai:latest \
  --push \
  .
```

Verificación:

```bash
docker buildx imagetools inspect \
  docker.io/westerterrazas/salad-ai:ai-v3
```

## Configuración en Salad Cloud

```text
Imagen: docker.io/westerterrazas/salad-ai:ai-v3
Arquitectura: linux/amd64
Puerto del gateway: 6080
Protocolo interno: HTTP
Command: vacío
Entrypoint: no sobrescribir
```

Variables:

```text
VNC_PASSWORD=clave-de-8-caracteres
CODE_PASSWORD=clave-distinta-y-larga
ENABLE_CODE_SERVER=true
REQUIRE_GPU=true
VNC_GEOMETRY=1920x1080
```

El Container Gateway debe apuntar al puerto `6080`.

La autenticación del gateway debe permanecer desactivada para permitir la conexión WebSocket de noVNC. La contraseña VNC protege el acceso al escritorio.

## Entorno Python IA

El entorno virtual está ubicado en:

```text
/opt/venv
```

Está agregado al `PATH`, por lo que dentro de la terminal del escritorio puede utilizarse:

```bash
python
pip
```

Principales dependencias:

* NumPy 1.26.4
* OpenCV 4.10
* ONNX 1.18
* ONNX Runtime GPU 1.23.2
* TensorFlow 2.19.1
* InsightFace 0.7.3
* PySide6
* OpenNSFW2
* Pillow
* psutil
* tqdm

Verificación:

```bash
/workspace/verificar-ia.sh
```

## Verificación del contenedor

```bash
/workspace/healthcheck.sh
/workspace/verificar-navegador.sh
/workspace/verificar-ia.sh
```

Comprobar procesos:

```bash
ps aux | grep -E 'websockify|Xvnc|code-server'
```

Comprobar GPU:

```bash
nvidia-smi
```

Comprobar permisos:

```bash
stat -c '%U:%G %n' \
  /home/ia \
  /home/ia/.cache \
  /home/ia/.mozilla \
  /home/ia/.keras \
  /home/ia/.config
```

Todos esos directorios deben pertenecer a:

```text
ia:ia
```

## Supervisión

El contenedor supervisa:

* TurboVNC.
* noVNC/websockify.
* code-server cuando está habilitado.

El healthcheck valida que los servicios principales respondan realmente.

El contenedor no utiliza `tail -f /dev/null` para simular un estado activo.

## Seguridad y privacidad

* Usuario gráfico sin sudo.
* Contraseñas VNC y code-server separadas.
* TurboVNC escucha únicamente en localhost.
* code-server escucha únicamente en localhost.
* Historial Bash y Python redirigido a `/dev/null`.
* Telemetría conocida de Firefox, code-server, TensorFlow y bibliotecas compatibles deshabilitada mediante configuración.
* Estudios, Pocket, cuentas Firefox, contenido patrocinado y actualizaciones automáticas deshabilitados.
* Directorio `/home/ia` propiedad de `ia:ia`.
* Descargas críticas verificadas mediante SHA256.
* No contiene Tor ni proxy SOCKS.
* No se publica el socket Docker.
* No requiere modo privilegiado.

No puede garantizarse “cero tráfico externo”: Firefox, YouTube, descarga de modelos y las aplicaciones ejecutadas por el usuario realizan conexiones necesarias para funcionar.

## Limitaciones

* noVNC transporta vídeo, teclado y ratón, pero no audio remoto.
* La webcam física del usuario no se expone automáticamente dentro del contenedor.
* DRM/Widevine está deshabilitado.
* YouTube HTML5 funciona, pero el sonido no llega al navegador cliente mediante noVNC.
* Los modelos de IA deben almacenarse en `/models` o descargarse desde una fuente controlada.


## AI v5: desarrollo y DNS cifrado

Incluye VSCodium, toolchains C/C++, Rust, Go y Node.js, depuradores,
clientes de bases de datos y utilidades de terminal.

El DNS del sistema utiliza `dnscrypt-proxy` en `127.0.0.1:53` con
resolutores cifrados y relays de DNS anonimizado:

```text
Aplicaciones → dnscrypt-proxy → relay → resolver cifrado
```

Variables:

```text
SECURE_DNS_ENABLED=true
SECURE_DNS_REQUIRED=true
```

Verificación:

```bash
/workspace/verificar-dns-seguro.sh
/workspace/verificar-herramientas.sh
```

Firefox fuerza HTTPS-Only, utiliza el DNS seguro del sistema, instala
uBlock Origin y mantiene deshabilitada su telemetría.

El DNS cifrado oculta las consultas DNS en texto claro, pero no oculta
a la infraestructura las IP de destino ni proporciona anonimato total.

## DNS seguro ai-v5.1

El contenedor usa `dnscrypt-proxy` compatible con Ubuntu 24.04 y dos
endpoints estáticos Quad9 DNS-over-HTTPS por puerto 443. No utiliza ODoH
ni descarga listas remotas durante el arranque. `SECURE_DNS_REQUIRED=true`
mantiene el inicio en modo fail-closed si el resolver cifrado no funciona.

Esto cifra las consultas DNS del sistema, pero la red que hospeda el
contenedor todavía puede observar las IP de destino y metadatos de tráfico.
