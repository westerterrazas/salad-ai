# Salad AI

Contenedor GPU basado en CUDA 13.1 y Ubuntu 24.04 para ejecutar un escritorio XFCE remoto con TurboVNC, noVNC, code-server y Firefox mediante Tor.

## Servicios

| Servicio           | Puerto |
| ------------------ | -----: |
| noVNC / XFCE       |   6080 |
| code-server        |   8080 |
| TurboVNC interno   |   5901 |
| Tor SOCKS5 interno |   9050 |

## Variable obligatoria

Configurar en Salad Cloud:

```text
VNC_PASSWORD=contraseña-segura
```

La misma contraseña permite acceder a:

* noVNC
* code-server
* usuario Linux `ia`
* `sudo`

## Construcción local

```bash
docker build -t salad-ai:local .
```

Ejecución con GPU:

```bash
docker run --rm \
  --gpus all \
  -e VNC_PASSWORD='contraseña-segura' \
  -p 6080:6080 \
  -p 8080:8080 \
  salad-ai:local
```

Acceso local:

```text
http://localhost:6080
http://localhost:8080
```

## Publicación automática en Docker Hub

El workflow se encuentra en:

```text
.github/workflows/docker-publish.yml
```

Crear estos secretos en GitHub:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

Cada push a `main` publica:

```text
DOCKERHUB_USERNAME/salad-ai:<SHA_COMMIT>
DOCKERHUB_USERNAME/salad-ai:latest
```

Para producción debe usarse el tag SHA, no `latest`.

## Configuración en Salad Cloud

* Imagen: `usuario/salad-ai:<SHA_COMMIT>`
* Arquitectura: `linux/amd64`
* GPU: NVIDIA con al menos 24 GB VRAM
* Puerto noVNC: `6080`
* Puerto code-server: `8080`
* Command: vacío
* Entrypoint: no sobrescribir
* Variable: `VNC_PASSWORD`

El gateway de Salad debe apuntar al puerto `6080`.

## Supervisión

`websockify` es el proceso principal del contenedor. Si noVNC falla, el contenedor termina para que Salad detecte el error y reinicie la instancia.

El contenedor no utiliza `tail -f /dev/null` para simular un estado activo.

## Verificación

```bash
curl -gfsS http://[::1]:6080/
nvidia-smi
ps aux | grep -E 'websockify|Xvnc|code-server|tor'
```

## Seguridad

* Historial de Bash y Python deshabilitado.
* Telemetría deshabilitada.
* Firefox utiliza Tor SOCKS5.
* TurboVNC solo escucha internamente.
* Los servicios públicos escuchan mediante IPv6, requerido por Salad.
