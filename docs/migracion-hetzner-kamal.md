# Migración de Prodovo: Railway → Hetzner + Kamal

Guía preparada el 12/11/2026 para Kamal **2.12.0**. Los comandos son pasos para ejecutar durante la migración; todavía no se creó infraestructura ni se cambió producción. Reemplazar TODOS los placeholders antes de ejecutar. `192.0.2.10` y `example.com` son ejemplos, no destinos reales.

## 1. Arquitectura y condiciones de partida

Un VPS x86_64 con Ubuntu 24.04 LTS, Docker, kamal-proxy (HTTPS), Rails y Postgres. Empezar con 4 GB de RAM y medir generación concurrente de PDFs; no es una garantía de capacidad. Construir imágenes desde la computadora local, no consumir RAM del VPS compilando. El Dockerfile instala Google Chrome amd64: **no elegir ARM**.

La aplicación usa Rails 8.1.4.1, Ruby 3.4.12, Puma en 3000, Grover/Chrome y Active Storage local (`/rails/storage`). El backup actual sube únicamente Postgres a AWS S3. No se encontró un scheduler de backups en el repositorio. Action Cable tiene configurado Redis, pero no hay uso de broadcasts ni jobs diferidos detectado: no se incluye Redis. Si se usan WebSockets realmente, agregar Redis privado y su gema antes del corte.

Este diseño tiene un único punto de fallo: si el VPS cae, la web y DB caen. Los backups permiten recuperar; no brindan alta disponibilidad. Un dump diario implica perder potencialmente hasta 24 horas de datos. Acordar RPO (pérdida máxima aceptable) y RTO (tiempo de recuperación medido) antes de migrar.

El precio mencionado en la conversación anterior fue orientativo, no una cotización validada. Confirmar al contratar el total por región: VPS x86, IPv4, impuestos, snapshots/backups, tráfico y S3. No contratar suponiendo el precio de otra región.

## 2. Inventario y respaldo inicial

- [ ] Registrar dominio(s), proveedor DNS, registros A/AAAA/CNAME, TTL, región actual y servicios Railway (app, DB, volúmenes, cron).
- [ ] Verificar versión real con `SHOW server_version;`, tamaño DB y extensiones con `SELECT extname, extversion FROM pg_extension;`.
- [ ] Esta configuración usa Postgres 17 y el Dockerfile trae cliente 17. Si origen es mayor a 17, detenerse: ajustar servidor destino, cliente de backup y ruta de datos de la imagen elegida. Nunca intentar bajar de versión mediante este procedimiento.
- [ ] Confirmar dónde están los archivos reales en Railway. Active Storage local sin volumen puede haber perdido archivos en deploys anteriores: comparar registros de blobs con archivos presentes antes de migrar.
- [ ] Inventariar variables privadas desde el panel, sin volcarlas a Git ni compartirlas. Copiar `RAILS_MASTER_KEY` y el `SECRET_KEY_BASE` efectivo actuales para preservar credenciales/sesiones. Si el segundo viene de credentials, extraerlo privadamente desde el entorno actual.
- [ ] Revisar SMTP, webhooks, OAuth, allowlists de IP, integraciones, Redis y tareas programadas que estén fuera del repositorio.
- [ ] Descargar un backup S3 y probar que se puede leer con `pg_restore --list`. No asumir que tener código de backup implica tener backups válidos.
- [ ] Bajar TTL DNS a 300 al menos un TTL anterior antes del corte. Registrar valores originales.

En la computadora local, crear una carpeta privada ignorada por Git y Docker:

```bash
mkdir -p migration-private
chmod 700 migration-private
```

Guardar dumps y archivos sólo ahí o en almacenamiento cifrado. El dump y el tar contienen información de producción. Preferir disco local cifrado y S3 con bloqueo público, cifrado, versionado y retención.

## 3. Cuenta, servidor y firewall

1. Activar MFA en Hetzner, GitHub/registry, DNS y AWS; guardar códigos de recuperación en un gestor de contraseñas.
2. Crear una clave SSH dedicada con passphrase: `ssh-keygen -t ed25519 -f ~/.ssh/prodovo_deploy`. Agregarla al agente con `ssh-add ~/.ssh/prodovo_deploy`.
3. Crear VPS **x86_64**, Ubuntu 24.04, con esa clave pública. Elegir región según latencia desde los usuarios, no sólo costo.
4. Configurar firewall de Hetzner: entrada TCP 22 sólo desde tu IP/VPN; TCP 80 y 443 desde internet. Aplicar reglas para IPv4 e IPv6, permitir ICMP necesario y salida para DNS, NTP, HTTPS y repositorios. No abrir 3000, 5432, 2375 ni 6379.
5. Entrar como root para bootstrap y mantener esa sesión abierta hasta probar el usuario nuevo.

En el VPS como root:

```bash
apt-get update
apt-get upgrade -y
apt-get install -y unattended-upgrades ufw ca-certificates curl rsync
adduser --disabled-password --gecos '' deploy
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
cp /root/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys
```

Instalar Docker Engine con el repositorio oficial para Ubuntu (enlace al final). Evitar scripts de instalación remotos ejecutados a ciegas. Luego como root:

```bash
usermod -aG docker deploy
systemctl enable --now docker
systemctl enable --now unattended-upgrades
install -d -m 750 -o 1000 -g 1000 /srv/prodovo/storage
install -d -m 700 /srv/prodovo/postgres
```

El grupo Docker equivale en la práctica a root: reservarlo para despliegue. Usar root sólo vía consola de rescate/proveedor o acceso de administración restringido; `deploy` no necesita sudo para Kamal. Postgres ajustará el propietario de su directorio al inicializar.

Probar desde **otra terminal** `ssh -i ~/.ssh/prodovo_deploy deploy@IP_VPS` y `docker info`. Verificar huella SSH por la consola del proveedor; no desactivar la verificación de host.

Después crear `/etc/ssh/sshd_config.d/00-prodovo.conf` como root:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers deploy
```

Validar `sshd -t` y revisar `sshd -T` para confirmar valores efectivos (otras configuraciones/cloud-init pueden interferir). Ejecutar `systemctl reload ssh`, probar otra conexión y recién entonces cerrar la sesión anterior. Conservar acceso de rescate del proveedor.

Configurar UFW como root, sustituyendo TU_IP_PUBLICA:

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow from TU_IP_PUBLICA to any port 22 proto tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
ufw status verbose
```

**Docker puede eludir reglas UFW en puertos publicados.** El firewall del proveedor es la barrera externa; Postgres no publica ningún puerto. No agregar `port: 5432:5432` al accessory. Verificar desde otra máquina que 3000/5432 están cerrados y en el host con `docker ps` y `ss -lnt`. No desactivar las reglas iptables de Docker.

Configurar rotación de logs de Docker para todos los contenedores (incluido Postgres): fusionar en `/etc/docker/daemon.json`, sin sobrescribir otras opciones:

```json
{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"}}
```

Reiniciar Docker antes de crear servicios. Los contenedores existentes no adoptan automáticamente las nuevas opciones. Instalar parches de seguridad automáticamente, pero programar reinicios y actualizaciones de Docker/Postgres en ventanas con backup verificado.

## 4. Configuración local de Kamal y secretos

```bash
gem install kamal -v 2.12.0
kamal version
cp .kamal/secrets.example .kamal/secrets
chmod 600 .kamal/secrets
```

Completar `config/deploy.yml`: IP en web y accessory, usuario GHCR en image y registry, dominio inicial de ensayo, región y bucket S3. Para el ensayo usar por ejemplo `migracion.tudominio.com` apuntando al VPS; no cambiar todavía el dominio productivo. Mantener GitHub Container Registry **privado**, crear token con permisos mínimos de lectura/escritura de packages para desplegar. Proteger y rotar ese token; el VPS necesita poder descargar imágenes.

Completar `.kamal/secrets` en un editor privado. Generar dos passwords aleatorios distintos para administrador Postgres y usuario Rails; por ejemplo `openssl rand -hex 32`. Hex evita tener que escapar caracteres en DATABASE_URL. El hostname interno es **prodovo-db**. Mantener las claves Rails actuales. No ejecutar `kamal config` en logs compartidos: puede exponer valores resueltos.

AWS: credencial limitada a `s3:PutObject` sobre `arn:aws:s3:::TU_BUCKET/backups/*` para el servicio actual; la identidad de restauración y respaldo de archivos se administra por separado con lectura/listado y escritura sólo donde corresponda. No usar credenciales root de AWS. Si se exige KMS, agregar permisos KMS específicos. Configurar lifecycle (por ejemplo 30 diarios), versionado y alertas; considerar Object Lock para proteger contra borrado.

La app ya corre como UID 1000. Se ajustó `production.rb` para reconocer el proxy TLS y permitir `/up` sin redirecciones HTTPS. `/up` sólo comprueba arranque de Rails: también hay que verificar DB/PDFs manualmente.

**Pendiente previo al primer build:** el Dockerfile usa Node 20 y un repo PGDG fijo a bookworm sobre una imagen Ruby slim flotante. Revisar soporte de Node vigente y compatibilidad Debian de la imagen base; fijar base/digest y actualizar a una versión Node soportada con un build de prueba antes del corte. No se cambió ese stack automáticamente en esta preparación.

El build usa el commit Git actual por defecto. Revisar y commitear estos cambios antes del despliegue; nunca commitear `.kamal/secrets` ni `migration-private`. Comprobar:

```bash
git check-ignore .kamal/secrets migration-private/prueba.dump
kamal build push
kamal server bootstrap
kamal accessory boot db
```

No ejecutar `kamal setup` todavía: levantaría Rails antes de crear su usuario DB. No volver a inicializar el volumen Postgres si ya tiene datos.

## 5. Usuario Postgres sin superusuario

En el VPS como deploy, abrir psql del accessory:

```bash
docker exec -it prodovo-db psql -U postgres -d postgres
```

Dentro de psql, sólo en el servidor nuevo:

```sql
CREATE ROLE prodovo LOGIN;
\password prodovo
ALTER DATABASE prodovo_production OWNER TO prodovo;
\connect prodovo_production
ALTER SCHEMA public OWNER TO prodovo;
```

Introducir el password de Rails usado en DATABASE_URL cuando `\password` lo solicite. El usuario de Rails es dueño de su DB para ejecutar migraciones, sin SUPERUSER ni CREATEDB. El password administrador sólo lo usa el accessory. Cambiar `POSTGRES_PASSWORD` en secretos no cambia la contraseña de un volumen ya inicializado: una rotación requiere `ALTER ROLE`/`\password` y sincronizar credenciales.

## 6. Ensayo completo de exportación/restauración

Usar cliente pg_dump 17 contra origen <=17. Obtener la URL pública de Railway desde el panel; el hostname privado de Railway no es accesible desde tu computadora. Cargar `SOURCE_DATABASE_URL` por un gestor de secretos o prompt privado, nunca con su valor literal en el historial. Evitar imprimirla o incluirla en reportes.

En la computadora local con cliente PostgreSQL instalado:

```bash
pg_dump --dbname="$SOURCE_DATABASE_URL" --format=custom --no-owner --no-acl --file=migration-private/ensayo.dump
pg_restore --list migration-private/ensayo.dump
scp migration-private/ensayo.dump deploy@IP_VPS:/home/deploy/ensayo.dump
```

Si la política de origen requiere TLS, preservar su configuración SSL. Medir duración/tamaño del dump y verificar extensiones compatibles. El cliente debe ser >= versión del servidor origen; para esta ruta mantener destino 17 y origen <=17.

En el VPS, antes de iniciar Rails, restaurar en la DB **vacía**:

```bash
chmod 600 /home/deploy/ensayo.dump
docker exec -i prodovo-db pg_restore -U prodovo -d prodovo_production --no-owner --no-acl --exit-on-error < /home/deploy/ensayo.dump
```

Si aparecen extensiones que requieran privilegios, revisarlas e instalarlas como administrador sólo en destino antes de restaurar. No ignorar errores. No restaurar sobre datos existentes ni usar `--clean` por reflejo.

### Archivos Active Storage

Desde el shell del servicio **app correcto** en Railway, crear un tar de la ruta real de storage confirmada en el inventario, por ejemplo `/rails/storage`. Detener escrituras para una copia coherente en el corte final. Para el ensayo pueden cambiar archivos mientras se copia; documentar esa limitación.

```bash
tar -C /rails/storage -czf /tmp/prodovo-storage.tar.gz .
```

Transferir por un canal privado autenticado (por ejemplo S3 temporal con bloqueo público, cifrado y credenciales de transferencia con vencimiento). El mecanismo depende de las herramientas disponibles en ese contenedor: no instalar ni suponer `scp`/AWS CLI en producción. No usar directorios públicos ni URLs públicas para descargar datos. Descargar a `migration-private/storage.tar.gz` y subir al VPS:

```bash
scp migration-private/storage.tar.gz deploy@IP_VPS:/home/deploy/storage.tar.gz
```

Como root por consola administrativa del VPS, inspeccionar primero el listado del tar y extraer sólo el archivo generado por nosotros:

```bash
tar -tzf /home/deploy/storage.tar.gz | head
tar -xzf /home/deploy/storage.tar.gz -C /srv/prodovo/storage
chown -R 1000:1000 /srv/prodovo/storage
chmod 750 /srv/prodovo/storage
```

Copiar `storage` aunque parezca vacío, salvo que se haya comprobado que no hay adjuntos. El backup de DB no contiene los archivos binarios.

Desde la computadora local:

```bash
kamal deploy
kamal app details
kamal app logs
curl -fsS https://migracion.tudominio.com/up
kamal app exec 'bin/rails db:abort_if_pending_migrations'
kamal app exec 'bin/rails db:backup'
```

Validar login, permisos entre cuentas, altas y modificaciones, assets, descarga de adjuntos antiguos, carga nueva y PDF representativo (también varios concurrentes). Verificar conteos de tablas y totales de negocio contra origen. Registrar memoria con `docker stats --no-stream`, espacio con `df -h` y revisar errores del kernel/OOM. No probar webhooks/correos reales sin controlar sus destinos. Restringir acceso al dominio de ensayo y evitar usuarios reales escribiendo allí.

## 7. Backups automáticos y ensayo de recuperación

Antes del corte, programar y probar:

- DB diaria a S3 con el task existente; si se necesita RPO menor, aumentar frecuencia o elegir una estrategia con WAL/PITR.
- Archivos de `/srv/prodovo/storage` diariamente fuera del VPS y durante la misma pausa de escrituras si se necesita coherencia exacta DB/archivos.
- Backups/snapshots de Hetzner como segunda capa, verificando qué discos cubren. No sustituyen un dump ni garantizan consistencia lógica de Postgres.

Para programar DB sin guardar claves AWS en cron, crear en el VPS `/home/deploy/backup-db.sh` (usuario deploy, modo 700):

```bash
#!/bin/bash
set -euo pipefail
mapfile -t containers < <(docker ps --filter label=service=prodovo --filter label=role=web --format '{{.ID}}')
if [ "${#containers[@]}" -ne 1 ]; then
  echo 'Se esperaba exactamente un contenedor Rails activo; revisar deploy/backup' >&2
  exit 1
fi
docker exec "${containers[0]}" bin/rails db:backup
```

Probarlo manualmente. Comprobar las etiquetas con `docker inspect` en la versión instalada. En `crontab -e` de deploy, usando la zona horaria del servidor (ver `timedatectl`):

```cron
15 3 * * * /usr/bin/flock -n /home/deploy/backup-db.lock /home/deploy/backup-db.sh >> /home/deploy/backup-db.log 2>&1
```

Evitar deploys en ese horario; configurar rotación del log y alerta externa por exit !=0 **y por ausencia de un nuevo objeto S3 en 26 horas**. Cron por sí solo no alerta. No dar esta etapa por terminada sin probar una notificación de fallo.

Para archivos, instalar una herramienta de backup como restic desde fuente oficial en el host, usar repositorio S3 privado independiente, cifrado y password guardado también fuera del VPS. Configurar credenciales en un archivo 600, ejecutar `restic backup /srv/prodovo/storage`, programarlo, definir retención y verificar `restic check`. Registrar aquí bucket, horario y procedimiento exactos elegidos antes del corte; nunca el password. Si se usa un simple tar + S3 en cambio, automatizarlo con el mismo control de fallo/antigüedad y restauración.

**Prueba obligatoria:** descargar un dump nuevo de S3, restaurarlo en una DB desechable aislada con `pg_restore --exit-on-error`, restaurar archivos a otra carpeta y arrancar una instancia de prueba sin integraciones salientes. Verificar login, conteos y adjuntos. Medir el RTO. Una vez al mes repetir; después de cambios grandes repetir. No probar restauraciones sobre producción.

## 8. Corte definitivo con mantenimiento

1. Anunciar ventana según tiempo medido en ensayo y congelar cambios de código/esquema. Registrar SHA e imagen desplegada.
2. Detener TODAS las escrituras en origen: bloquear acceso web (incluidas sesiones existentes), parar cron, workers, webhooks e integraciones. Un aviso visual de mantenimiento no bloquea escrituras. Si no existe modo mantenimiento, detener el servicio app de Railway usando el panel y obtener archivos del volumen/una instancia de mantenimiento con ese volumen antes de detener el último contenedor accesible. Probar esta ruta en el ensayo.
3. Detener la app destino de ensayo con `kamal app stop`. Mantener ambos lados sin escritores hasta terminar validaciones.
4. Tomar dump FINAL y copia FINAL de storage con el procedimiento ensayado, verificar checksums (`shasum -a 256`) y guardar copias cifradas fuera del VPS. No reutilizar el dump del ensayo.
5. La DB destino contiene datos del ensayo: recrear **sólo la DB del VPS nuevo**, tras comprobar hostname, backup y app detenida. En psql administrador de destino ejecutar `DROP DATABASE prodovo_production;` y `CREATE DATABASE prodovo_production OWNER prodovo;`. Esto borra datos de ensayo. No ejecutar jamás contra Railway. Restaurar dump final con el comando del apartado 6 y reemplazar storage por la copia final sin mezclar adjuntos de prueba.
6. Con el dominio de ensayo aún configurado, ejecutar `kamal deploy`, verificar datos finales, adjuntos y PDFs. Mantener el acceso de ensayo restringido y no aceptar escrituras de negocio.
7. Cambiar `proxy.host` al dominio productivo; actualizar A al VPS y retirar/corregir AAAA anterior. Si hay CNAME, resolver su reemplazo correctamente. Desactivar temporalmente proxy/CDN DNS si interfiere con ACME. Ejecutar `kamal deploy` para registrar host y obtener TLS: Let's Encrypt requiere que el dominio ya apunte al VPS. Hay una ventana breve entre DNS/TLS; forma parte del mantenimiento.
8. Validar `curl -I https://TU_DOMINIO`, certificado, redirección HTTP, cookies seguras, login, datos, PDFs y subida/descarga. Probar desde otra red. Railway sigue sin aceptar escrituras aunque algunos clientes con DNS viejo lleguen allí.
9. Habilitar usuarios e integraciones sólo en Hetzner. Anotar la hora de la primera escritura nueva: desde ese momento volver atrás requiere migrar datos de regreso.
10. Confirmar primer backup automático, alerta, monitor HTTPS externo y recursos del VPS. Conservar Railway detenido y los backups durante un período acordado (por ejemplo 7 días); no eliminarlo durante el corte.

## 9. Rollback y recuperación

**Antes de habilitar escrituras en Hetzner:** detener destino, devolver DNS a los valores originales, reactivar app e integraciones en Railway y comprobar HTTPS/datos. Mantener un único lado escritor durante la propagación.

**Después de escrituras nuevas:** no basta con devolver DNS: perderías cambios. Entrar en mantenimiento, parar todos los escritores, exportar DB y archivos actuales de Hetzner y restaurarlos en origen con un plan de compatibilidad comprobado. Si hay migraciones de esquema incompatibles o versiones PG distintas, resolverlas antes de reabrir. La propagación DNS no sincroniza bases.

**Rollback de código:** `kamal app images` para identificar versión anterior y `kamal rollback VERSION`. No revierte migraciones DB ni archivos. Verificar compatibilidad de esquema antes; no ejecutar `db:rollback` automáticamente en producción.

**Pérdida del VPS:** crear otro con el mismo endurecimiento, instalar Docker, recuperar secretos del gestor, levantar DB, crear usuario, restaurar dump y storage externos, desplegar imagen registrada y cambiar DNS. Medir y documentar esta operación en el ensayo de recuperación.

## 10. Seguridad y operación continua

- [ ] Sólo 80/443 públicos; SSH por IP/VPN. Comprobado también por IPv6.
- [ ] Postgres sin puertos publicados; app sin superusuario; contenedor Rails sin root.
- [ ] Secretos fuera de Git, imagen, logs y backups de código. Dumps cifrados; acceso mínimo a backups.
- [ ] SSH y MFA probados, consola de recuperación disponible.
- [ ] Monitor externo HTTPS, alertas de errores, CPU/RAM, disco (alertar antes del 80%) y antigüedad de backups.
- [ ] Parches de SO activos, reinicios programados, rebuild periódico de imagen y actualización revisada de gems, Node y Chrome.
- [ ] Revisar dependencias con Brakeman, auditoría de gems/npm y escáner de imagen antes del corte; solucionar hallazgos relevantes.
- [ ] Chrome se ejecuta hoy con `--no-sandbox`. Aceptar explícitamente este riesgo residual; no renderizar HTML/URLs arbitrarias de usuarios y limitar accesos a redes internas/metadata. Evaluar sandbox o aislamiento de PDF si el contenido no es confiable. Docker no reemplaza el sandbox del navegador.
- [ ] Revisar autorización, CSRF y acceso a adjuntos, además de infraestructura.
- [ ] Después de estabilizar, configurar allowlist de hosts Rails para dominios definitivos y excluir `/up` para el chequeo interno; validar antes de desplegar para no bloquear el proxy.
- [ ] Retirar dominio de ensayo, archivos temporales y credenciales de transferencia; aplicar retención a dumps, no borrar la única copia recuperable.
- [ ] Cancelar Railway sólo tras restauración probada, ventana de observación y confirmación de que no quedan volúmenes/cron/buckets necesarios. Revocar credenciales Railway exclusivas después.

## Fuentes oficiales

Configuración contrastada con documentación de Kamal 2.12.0. Revisar instrucciones vigentes al ejecutar:

- [Kamal configuración](https://kamal-deploy.org/docs/configuration/overview/)
- [Kamal accesorios y red privada](https://kamal-deploy.org/docs/configuration/accessories/)
- [Kamal proxy y requisitos HTTPS](https://kamal-deploy.org/docs/configuration/proxy/)
- [Kamal secretos](https://kamal-deploy.org/docs/configuration/environment-variables/)
- [Docker Engine en Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker y firewall/UFW](https://docs.docker.com/engine/network/packet-filtering-firewalls/)
- [PostgreSQL pg_dump](https://www.postgresql.org/docs/17/app-pgdump.html)
- [PostgreSQL pg_restore](https://www.postgresql.org/docs/17/app-pgrestore.html)
- [Hetzner Cloud](https://www.hetzner.com/cloud/)
