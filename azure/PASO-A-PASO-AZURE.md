# Paso a paso: desplegar en Azure por consola (Windows + PowerShell)

Al terminar tendrás **una URL** (`http://IP_PUBLICA`): ahí está el **frontend** y la **API** (Nginx en la VM envía `/api` al gateway). No necesitas abrir el puerto 8080 al público.

**Archivo del script:** `azure/deploy-vm-docker-compose.ps1`  
**Tu repo de ejemplo:** `https://github.com/MaicolCastro/Parcial-Arle-Spring-bot.git`

---

## Paso 1 — Comprobar requisitos en tu PC

| Requisito | Qué hacer |
|-----------|-----------|
| Cuenta Azure | Suscripción activa (estudiante o normal). |
| Azure CLI | [Instalar Azure CLI (Windows)](https://learn.microsoft.com/es-es/cli/azure/install-azure-cli-windows). |
| PowerShell | Abre **Windows PowerShell** o **Terminal**. |
| Repo en GitHub | Debe ser **público** y tener el código en la rama por defecto (`main`). Debe verse `docker-compose.yml` en la raíz al abrir el repo en el navegador. |
| Clave SSH | Debe existir `C:\Users\TU_USUARIO\.ssh\id_rsa.pub`. Si **no** existe, el script intentará crearla solo la primera vez. Si prefieres crearla tú: `ssh-keygen -t rsa -b 4096` (Enter a la ruta por defecto; passphrase vacía si quieres). |

---

## Paso 2 — Tener el proyecto en GitHub (solo la primera vez)

Si el código **ya está** en GitHub, pasa al **Paso 3**.

Si no:

1. Crea un repositorio **público** en GitHub.
2. En tu PC, en la carpeta del proyecto:

```powershell
cd "c:\proyectos\Parcial Arle"
git init
git add .
git commit -m "Proyecto peluqueria"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git push -u origin main
```

---

## Paso 3 — Iniciar sesión en Azure

```powershell
az login
```

Si tienes **varias suscripciones**:

```powershell
az account list -o table
az account set --subscription "NOMBRE-O-ID-DE-TU-SUSCRIPCION"
```

Comprueba que hay sesión:

```powershell
az account show -o table
```

---

## Paso 4 — Actualizar el script en tu PC (recomendado)

Si ya clonaste o trabajas en la carpeta del proyecto:

```powershell
cd "c:\proyectos\Parcial Arle"
git pull
```

Así tienes la última versión de `deploy-vm-docker-compose.ps1` (reintentos de VM, grupo de recursos ya existente, etc.).

---

## Paso 5 — Ejecutar el despliegue (un comando)

Elige un **nombre de grupo de recursos** (único en tu suscripción). Ejemplo: `rg-peluqueria-arle`.

```powershell
cd "c:\proyectos\Parcial Arle"

.\azure\deploy-vm-docker-compose.ps1 `
  -ResourceGroupName "rg-peluqueria-arle" `
  -RepoUrl "https://github.com/MaicolCastro/Parcial-Arle-Spring-bot.git"
```

**Qué hace el script (en orden):**

1. Comprueba **Azure CLI** y sesión `az login`.
2. Comprueba o **crea** la clave SSH `id_rsa.pub` si falta.
3. Si el **grupo de recursos no existe**, lo crea (región por defecto del parámetro `-Location`, hoy **westeurope**).  
   Si el grupo **ya existe** (por un intento anterior en otra región, p. ej. `eastus2`), **no** lo vuelve a crear: Azure no permite cambiar la región de un grupo ya creado.
4. Crea la **VM Ubuntu** con Docker: prueba tu `-Location` / `-VmSize` y, si Azure devuelve **SkuNotAvailable**, **reintenta solo** otras regiones y tamaños hasta que una funcione (salvo que uses `-NoAutoRetryVm`).
5. Abre el **puerto 80**.
6. En la VM: instala Docker, hace `git clone` del repo, `docker compose up -d --build` (la **primera vez puede tardar 15–45 minutos**).

**No cierres la ventana** hasta que termine el bloque largo del comando remoto.

**Parámetros opcionales útiles:**

| Parámetro | Uso |
|-----------|-----|
| `-Location "westeurope"` | Región del grupo **nuevo** y primer intento de VM (por defecto ya es westeurope). |
| `-VmSize "Standard_B2s"` | Tamaño de VM del primer intento (por defecto Standard_B2s). |
| `-SshPublicKeyPath "C:\Users\TU NOMBRE\.ssh\id_rsa.pub"` | Si tu ruta tiene espacios. |
| `-NoAutoRetryVm` | Un solo intento de VM (sin bucle de SKUs/regiones). |

Si **todo** falla por capacidad: otro **`-ResourceGroupName`** nuevo y otra `-Location`, por ejemplo:

```powershell
.\azure\deploy-vm-docker-compose.ps1 `
  -ResourceGroupName "rg-peluqueria-nuevo" `
  -RepoUrl "https://github.com/MaicolCastro/Parcial-Arle-Spring-bot.git" `
  -Location "brazilsouth" `
  -VmSize "Standard_B2s"
```

Más información: [SKU not available](https://aka.ms/azureskunotavailable).

---

## Paso 6 — Probar en el navegador

Al finalizar, el script imprime una línea del estilo:

`Frontend + API ... http://XX.XX.XX.XX`

1. Abre **`http://ESA_IP`** (solo `http`, sin puerto extra: el 80 es el web).
2. **Login demo** (si la base de usuarios arrancó vacía):
   - **Email:** `admin@peluqueria.demo`
   - **Contraseña:** `Admin123`
3. Revisa **Citas** y **Servicios**.

La API es la misma URL con rutas **`/api/...`** (el Nginx del frontend hace de proxy al gateway).

---

## Paso 7 — Si algo falla (SSH y logs)

Sustituye `TU_IP` por la IP pública que te dio el script o la ves en Azure Portal.

```powershell
ssh azureuser@TU_IP
```

Dentro de la VM:

```bash
sudo docker compose -f /opt/peluqueria-app/docker-compose.yml ps
sudo tail -200 /var/log/peluqueria-bootstrap.log
```

Reintentar solo Docker (si la VM ya existe y Docker está bien):

```powershell
ssh azureuser@TU_IP "cd /opt/peluqueria-app && sudo docker compose up -d --build"
```

Si el comando remoto de Azure se cortó pero la VM existe:

```powershell
ssh azureuser@TU_IP "sudo bash /tmp/bootstrap.sh"
```

---

## Paso 8 — Entrega en Moodle (ejemplo)

| Campo | Qué poner |
|--------|-----------|
| GitHub | `https://github.com/MaicolCastro/Parcial-Arle-Spring-bot` |
| URL frontend | `http://TU_IP_PUBLICA` |
| URL backend | Misma base: la API va en `http://TU_IP_PUBLICA/api/...` (ej. login: `POST http://TU_IP_PUBLICA/api/auth/login`). |

---

## Paso 9 — Borrar todo y dejar de pagar (cuando ya no lo necesites)

```powershell
az group delete --name rg-peluqueria-arle --yes --no-wait
```

(Cambia `rg-peluqueria-arle` por el nombre de grupo que hayas usado.)

---

## Copiar y pegar (resumen mínimo)

```powershell
az login
cd "c:\proyectos\Parcial Arle"
git pull
.\azure\deploy-vm-docker-compose.ps1 `
  -ResourceGroupName "rg-peluqueria-arle" `
  -RepoUrl "https://github.com/MaicolCastro/Parcial-Arle-Spring-bot.git"
```

Espera a que termine → abre `http://IP` → `admin@peluqueria.demo` / `Admin123` → listo.
