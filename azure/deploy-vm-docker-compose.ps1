# Despliegue en Azure VM (Ubuntu) con Docker Compose
# Requisitos: Azure CLI (`az`), clave SSH pública, repositorio Git público con este proyecto.
#
# Uso:
#   az login
#   .\azure\deploy-vm-docker-compose.ps1 -ResourceGroupName "rg-peluqueria" -RepoUrl "https://github.com/TU_USUARIO/TU_REPO.git"
# Si no tienes clave SSH, el script intentará crear id_rsa / id_rsa.pub (sin frase de paso).
#
# Si Azure devuelve SkuNotAvailable, el script reintenta otras regiones/tamaños automáticamente.
# Para desactivar: -NoAutoRetryVm

param(
    [Parameter(Mandatory = $true)][string]$ResourceGroupName,
    [Parameter(Mandatory = $true)][string]$RepoUrl,
    [string]$Location = "uksouth",
    [string]$VmName = "vm-peluqueria",
    [string]$VmSize = "Standard_D2s_v5",
    [string]$SshPublicKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub",
    [string]$JwtSecretBase64 = "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDE=",
    [switch]$NoAutoRetryVm
)

$ErrorActionPreference = "Stop"

function Stop-Deploy([string]$Message, [int]$Code = 1) {
    Write-Host $Message -ForegroundColor Red
    exit $Code
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Stop-Deploy "Instala Azure CLI: https://aka.ms/installazurecliwindows"
}

if (-not (Test-Path $SshPublicKeyPath)) {
    $sshDir = Join-Path $env:USERPROFILE '.ssh'
    $privKeyPath = Join-Path $sshDir 'id_rsa'
    if (Test-Path $privKeyPath) {
        Write-Host "Existe la clave privada pero no la pública:" -ForegroundColor Red
        Write-Host "  $privKeyPath" -ForegroundColor Red
        Write-Host "Genera la pública con:" -ForegroundColor Yellow
        Write-Host "  ssh-keygen -y -f `"$privKeyPath`" | Out-File -Encoding ascii `"$SshPublicKeyPath`"" -ForegroundColor Gray
        exit 1
    }
    if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
        Write-Host "No está instalado OpenSSH (comando ssh-keygen)." -ForegroundColor Red
        Write-Host "Actívalo en: Configuración > Aplicaciones > Características opcionales > OpenSSH Cliente." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "No se encontró la clave pública. Se creará una nueva en:" -ForegroundColor Yellow
    Write-Host "  $SshPublicKeyPath" -ForegroundColor Gray
    New-Item -ItemType Directory -Force -Path $sshDir | Out-Null
    & ssh-keygen @('-t', 'rsa', '-b', '4096', '-f', $privKeyPath, '-q', '-N', '')
    if (-not (Test-Path $SshPublicKeyPath)) {
        Stop-Deploy "ssh-keygen no creó el archivo esperado. Ejecuta a mano: ssh-keygen -t rsa -b 4096"
    }
    Write-Host "Clave SSH creada correctamente." -ForegroundColor Green
}
$pub = Get-Content -Raw $SshPublicKeyPath

Write-Host "Comprobando sesión en Azure..." -ForegroundColor Cyan
az account show *> $null
if ($LASTEXITCODE -ne 0) {
    Stop-Deploy "Ejecuta primero: az login"
}

$rgJson = az group show --name $ResourceGroupName -o json 2>$null
if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($rgJson)) {
    $rgObj = $rgJson | ConvertFrom-Json
    Write-Host "El grupo '$ResourceGroupName' ya existe (región metadatos de Azure: $($rgObj.location)). No se vuelve a ejecutar 'az group create'." -ForegroundColor Yellow
    Write-Host "(La VM puede crearse en otra región con --location; eso no tiene por qué coincidir con la del grupo.)" -ForegroundColor DarkGray
} else {
    Write-Host "Creando grupo de recursos '$ResourceGroupName' en $Location..." -ForegroundColor Cyan
    az group create --name $ResourceGroupName --location $Location | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Stop-Deploy "No se pudo crear el grupo de recursos."
    }
}

# Plan de VM: tu -Location / -VmSize primero; luego serie D (pool distinto a B pequeñas); otras regiones.
# B1s/B1ms suelen devolver SkuNotAvailable — no se reintentan.
$vmPlan = [System.Collections.ArrayList]@()
$seen = @{}
function Add-VmAttempt([string]$Loc, [string]$Size) {
    $key = "$Loc|$Size"
    if ($seen.ContainsKey($key)) {
        return
    }
    $seen[$key] = $true
    [void]$script:vmPlan.Add(@{ L = $Loc; S = $Size })
}

Add-VmAttempt $Location $VmSize
if (-not $NoAutoRetryVm) {
    foreach ($s in @('Standard_D2s_v5', 'Standard_DS1_v2', 'Standard_D4s_v5', 'Standard_B2ms', 'Standard_B2s')) {
        if ($s -ne $VmSize) {
            Add-VmAttempt $Location $s
        }
    }
    foreach ($loc in @('uksouth', 'westeurope', 'southcentralus', 'northeurope', 'francecentral', 'swedencentral', 'brazilsouth', 'eastus2', 'eastus')) {
        if ($loc -eq $Location) {
            continue
        }
        foreach ($s in @('Standard_D2s_v5', 'Standard_DS1_v2', 'Standard_B2s', 'Standard_B2ms')) {
            Add-VmAttempt $loc $s
        }
    }
}

$vmOk = $false
$usedLoc = $Location
$usedSize = $VmSize
foreach ($row in $vmPlan) {
    Write-Host "Creando VM '$VmName' → región $($row.L), tamaño $($row.S) (3-10 min)..." -ForegroundColor Cyan
    az vm create `
        --resource-group $ResourceGroupName `
        --name $VmName `
        --location $row.L `
        --image Ubuntu2204 `
        --size $row.S `
        --admin-username azureuser `
        --authentication-type ssh `
        --ssh-key-values $pub `
        --public-ip-sku Standard `
        --output none
    if ($LASTEXITCODE -eq 0) {
        $vmOk = $true
        $usedLoc = $row.L
        $usedSize = $row.S
        Write-Host "VM creada correctamente en $($row.L) con $($row.S)." -ForegroundColor Green
        break
    }
    Write-Host "Falló esta combinación (sigue reintentando si hay más)..." -ForegroundColor DarkYellow
}

if (-not $vmOk) {
    Write-Host ""
    Write-Host "No hubo capacidad para ninguna combinación probada (SkuNotAvailable). Prueba manualmente otra región/SKU." -ForegroundColor Yellow
    Write-Host "Ejemplos (copia una línea completa):" -ForegroundColor Yellow
    Write-Host ('  .\azure\deploy-vm-docker-compose.ps1 -ResourceGroupName "rg-pelu-3" -RepoUrl "{0}" -Location westeurope -VmSize Standard_D2s_v5' -f $RepoUrl)
    Write-Host ('  .\azure\deploy-vm-docker-compose.ps1 -ResourceGroupName "rg-pelu-3" -RepoUrl "{0}" -Location southcentralus -VmSize Standard_B2s' -f $RepoUrl)
    Write-Host ('  .\azure\deploy-vm-docker-compose.ps1 -ResourceGroupName "rg-pelu-3" -RepoUrl "{0}" -NoAutoRetryVm -Location brazilsouth -VmSize Standard_B2s' -f $RepoUrl)
    Write-Host ""
    Write-Host "https://aka.ms/azureskunotavailable" -ForegroundColor DarkGray
    exit 1
}

Write-Host "Abriendo puerto 80 (HTTP)..." -ForegroundColor Cyan
az vm open-port --resource-group $ResourceGroupName --name $VmName --port 80 --output none
if ($LASTEXITCODE -ne 0) {
    Stop-Deploy "No se pudo abrir el puerto 80."
}

# Swap evita OOM al compilar Maven dentro de Docker en VMs pequeñas
$bootstrap = @'
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
exec > >(tee /var/log/peluqueria-bootstrap.log) 2>&1

if ! swapon --show | grep -q swapfile; then
  fallocate -l 4G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=4096
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
fi

apt-get update -y
apt-get install -y ca-certificates curl git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker

cd /opt
rm -rf peluqueria-app
git clone --depth 1 REPO_URL_PLACEHOLDER peluqueria-app
cd peluqueria-app
printf "JWT_SECRET_BASE64=%s\nMYSQL_ROOT_PASSWORD=root\nPOSTGRES_PASSWORD=postgres\n" "JWT_B64_PLACEHOLDER" > .env

docker compose up -d --build
docker compose ps
'@

$bootstrap = $bootstrap.Replace("REPO_URL_PLACEHOLDER", $RepoUrl).Replace("JWT_B64_PLACEHOLDER", $JwtSecretBase64)

$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($bootstrap))

Write-Host "Instalando Docker y construyendo imágenes en la VM (puede tardar 15-45 min la primera vez). No cierres esta ventana." -ForegroundColor Yellow
Write-Host "(Si el comando remoto se corta por tiempo, conecta por SSH y ejecuta: sudo bash /tmp/bootstrap.sh)" -ForegroundColor DarkGray

az vm run-command invoke `
    --resource-group $ResourceGroupName `
    --name $VmName `
    --command-id RunShellScript `
    --scripts "echo $b64 | base64 -d > /tmp/bootstrap.sh && chmod +x /tmp/bootstrap.sh && /tmp/bootstrap.sh" `
    -o table

if ($LASTEXITCODE -ne 0) {
    $ipEarly = az vm list-ip-addresses -g $ResourceGroupName -n $VmName --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>$null
    Write-Warning "El comando remoto devolvió error. Revisa la salida de arriba."
    if ($ipEarly) {
        Write-Host "Si la VM existe, puedes repetir el despliegue manual por SSH:" -ForegroundColor Yellow
        Write-Host "  ssh azureuser@$ipEarly `"sudo bash /tmp/bootstrap.sh`"" -ForegroundColor Gray
    }
}

$ip = az vm list-ip-addresses -g $ResourceGroupName -n $VmName --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv
if (-not $ip) {
    $ip = az network public-ip list -g $ResourceGroupName --query "[0].ipAddress" -o tsv
}

Write-Host ""
if ($ip) {
    Write-Host "=== Listo ===" -ForegroundColor Green
    Write-Host "Frontend + API (mismo sitio, Nginx -> Gateway): http://$ip"
    Write-Host "Credenciales demo: admin@peluqueria.demo / Admin123"
    Write-Host "Comprobar contenedores: ssh azureuser@$ip 'sudo docker compose -f /opt/peluqueria-app/docker-compose.yml ps'"
    Write-Host "Log en la VM: ssh azureuser@$ip 'sudo tail -100 /var/log/peluqueria-bootstrap.log'"
} else {
    Write-Host "No se pudo obtener la IP pública (¿falló la creación de la VM?)." -ForegroundColor Red
    Write-Host "En Azure Portal revisa el grupo: $ResourceGroupName" -ForegroundColor Yellow
}
Write-Host ""
