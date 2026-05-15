# Paso a paso: desplegar en Azure por consola (rápido y estable)

Este proyecto se despliega en **una máquina virtual Ubuntu** con **Docker Compose**: frontend (puerto 80), gateway (8080 interno), microservicios y bases de datos. Todo queda operativo en **una sola URL** (`http://IP`).

---

## 0. Qué necesitas antes de empezar

1. **Cuenta de Azure** con suscripción activa.
2. **Azure CLI** instalado en Windows: [Instalar Azure CLI](https://learn.microsoft.com/es-es/cli/azure/install-azure-cli-windows).
3. **PowerShell** (el que trae Windows).
4. **Clave SSH** (la VM no usa contraseña, solo SSH):
   - Si no tienes clave, en PowerShell (acepta la ruta por defecto; puedes dejar la *passphrase* vacía):
     ```powershell
     ssh-keygen -t rsa -b 4096
     ```
   - Debe existir el archivo `id_rsa.pub` (ruta típica: `C:\Users\TU_NOMBRE\.ssh\id_rsa.pub`). Si tu usuario tiene **espacios** en la ruta, al ejecutar el script de despliegue usa comillas: `-SshPublicKeyPath "C:\Users\TU NOMBRE\.ssh\id_rsa.pub"`.
5. **Código en GitHub en un repositorio público** (rama por defecto `main` o la que tengas como default en GitHub). La VM hará `git clone` de esa URL.

---

## 1. Subir el proyecto a GitHub (solo la primera vez)

1. Crea un repositorio **público** en GitHub (vacío o con README).
2. En la carpeta del proyecto en tu PC:

   ```powershell
   cd "c:\proyectos\Parcial Arle"
   git init
   git add .
   git commit -m "Proyecto peluquería microservicios"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
   git push -u origin main
   ```

3. Comprueba en el navegador que la URL del repo abre y ves `docker-compose.yml` en la raíz.

---

## 2. Iniciar sesión en Azure

```powershell
az login
```

Elige la suscripción correcta (si tienes varias):

```powershell
az account list -o table
az account set --subscription "NOMBRE-O-ID-DE-TU-SUSCRIPCION"
```

---

## 3. Ejecutar el script de despliegue

Desde la carpeta del proyecto (ajusta **nombre del grupo**, **URL del repo**):

```powershell
cd "c:\proyectos\Parcial Arle"

.\azure\deploy-vm-docker-compose.ps1 `
  -ResourceGroupName "rg-peluqueria-arle" `
  -RepoUrl "https://github.com/TU_USUARIO/TU_REPO.git"
```

- **`-ResourceGroupName`**: debe ser único en tu suscripción (puedes usar tu apellido + fecha).
- **`-RepoUrl`**: HTTPS del repo **público** (termina en `.git` o sin `.git`, ambas suelen valer con `git clone`).

Por defecto el script usa **`-Location westeurope`** y **`-VmSize Standard_B2s`**, y **reintenta solo** con otras combinaciones (regiones y tamaños) si Azure responde **SkuNotAvailable** (restricción de capacidad). Puedes desactivar los reintentos con **`-NoAutoRetryVm`**.

Si aun así falla todo (poco habitual), prueba otro **nombre de grupo** y otra región a mano, por ejemplo:

```powershell
.\azure\deploy-vm-docker-compose.ps1 `
  -ResourceGroupName "rg-peluqueria-arle3" `
  -RepoUrl "https://github.com/TU_USUARIO/TU_REPO.git" `
  -Location "brazilsouth" `
  -VmSize "Standard_B2s" `
  -NoAutoRetryVm
```

Documentación Microsoft: [SKU not available](https://aka.ms/azureskunotavailable).

El script:

1. Crea el **grupo de recursos**.
2. Crea la **VM Ubuntu** con tu clave `id_rsa.pub`.
3. Abre el **puerto 80** (HTTP).
4. En la VM instala **Docker**, clona el repo, crea `.env` y ejecuta **`docker compose up -d --build`** (puede tardar **15–45 minutos** la primera vez por Maven dentro de los Dockerfiles).

**No cierres PowerShell** hasta que termine el paso del comando remoto (puede tardar mucho; si tu versión de Azure CLI corta el tiempo, conecta por SSH y ejecuta `sudo bash /tmp/bootstrap.sh`).

---

## 4. Cuando termine: probar

Al final el script muestra una línea como:

`Frontend + API ... http://XX.XX.XX.XX`

1. Abre en el navegador: **`http://ESA_IP`** → debe cargar el **login** del frontend.
2. Entra con:
   - **Email:** `admin@peluqueria.demo`
   - **Contraseña:** `Admin123`
3. Prueba **Citas** y **Servicios** (como ADMIN puedes CRUD en servicios).

La API va por el mismo sitio: el Nginx del frontend enruta **`/api`** al **gateway**; no hace falta abrir el 8080 al público para la entrega.

---

## 5. Si algo falla (sin pánico)

### Ver estado de los contenedores (por SSH)

```powershell
ssh azureuser@TU_IP_PUBLICA
sudo docker compose -f /opt/peluqueria-app/docker-compose.yml ps
sudo docker compose -f /opt/peluqueria-app/docker-compose.yml logs --tail=80 api-gateway
```

Salir de SSH: `exit`.

### Ver el log del instalador en la VM

```powershell
ssh azureuser@TU_IP_PUBLICA "sudo tail -200 /var/log/peluqueria-bootstrap.log"
```

### Repetir solo el compose en la VM (si Docker ya está bien)

```powershell
ssh azureuser@TU_IP_PUBLICA "cd /opt/peluqueria-app && sudo docker compose up -d --build"
```

### El comando remoto se cortó por tiempo

Vuelve a conectar y lanza el bootstrap a mano:

```powershell
ssh azureuser@TU_IP_PUBLICA "sudo bash /tmp/bootstrap.sh"
```

(Si `/tmp/bootstrap.sh` no existe, vuelve a ejecutar el script `deploy-vm-docker-compose.ps1` en otra VM nueva o clona y `docker compose` manual en `/opt/peluqueria-app`.)

### Error “Repository not found” al clonar

- Repo **privado**: el script solo funciona con repo **público**, o tendrías que configurar un token en la VM (no cubierto aquí).
- URL mal copiada: revisa `https://github.com/USUARIO/REPO.git`.

### No carga la web en el puerto 80

```powershell
az vm open-port --resource-group rg-peluqueria-arle --name vm-peluqueria --port 80
```

(Sustituye grupo y nombre de VM por los tuyos.)

---

## 6. Qué poner en Moodle

| Campo | Valor típico |
|--------|----------------|
| GitHub | `https://github.com/TU_USUARIO/TU_REPO` |
| Frontend | `http://TU_IP_PUBLICA` |
| Backend / API | Mismo que el frontend (todo va por `/api`), o si el profesor pide URL explícita del gateway: `http://TU_IP_PUBLICA/api` como prefijo de rutas (el gateway no tiene página en `/`, solo JSON en `/` y rutas `/api/...`). |

---

## 7. Borrar todo (dejar de pagar la VM)

```powershell
az group delete --name rg-peluqueria-arle --yes --no-wait
```

(Sustituye el nombre del grupo por el que usaste.)

---

## Resumen de una línea (después de GitHub listo)

```powershell
az login
cd "c:\proyectos\Parcial Arle"
.\azure\deploy-vm-docker-compose.ps1 -ResourceGroupName "rg-peluqueria-arle" -RepoUrl "https://github.com/TU_USUARIO/TU_REPO.git"
```

Espera a que termine → abre `http://IP` → login demo → listo.
