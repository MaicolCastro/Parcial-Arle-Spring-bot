# Despliegue en Azure VM (Ubuntu) con Docker Compose
# Requisitos: Azure CLI (`az`), clave SSH pública, repositorio Git público con este proyecto.
#
# Uso:
#   az login
#   .\azure\deploy-vm-docker-compose.ps1 -ResourceGroupName "rg-peluqueria" -RepoUrl "https://github.com/TU_USUARIO/TU_REPO.git"
# Si no tienes clave SSH, el script intentará crear id_rsa / id_rsa.pub (sin frase de paso).

param(
    [Parameter(Mandatory = $true)][string]$ResourceGroupName,
    [Parameter(Mandatory = $true)][string]$RepoUrl,
    [string]$Location = "eastus",
    [string]$VmName = "vm-peluqueria",
    [string]$VmSize = "Standard_B2s",
    [string]$SshPublicKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub",
    [string]$JwtSecretBase64 = "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDE=",
    [int]$RunCommandTimeoutSeconds = 3600
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Instala Azure CLI: https://aka.ms/installazurecliwindows"
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
        Write-Host "ssh-keygen no creó el archivo esperado. Ejecuta a mano: ssh-keygen -t rsa -b 4096" -ForegroundColor Red
        exit 1
    }
    Write-Host "Clave SSH creada correctamente." -ForegroundColor Green
}
$pub = Get-Content -Raw $SshPublicKeyPath

Write-Host "Comprobando sesión en Azure..." -ForegroundColor Cyan
az account show *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Ejecuta primero: az login"
}

az group create --name $ResourceGroupName --location $Location | Out-Null

Write-Host "Creando VM (3-8 min)..." -ForegroundColor Cyan
az vm create `
    --resource-group $ResourceGroupName `
    --name $VmName `
    --image Ubuntu2204 `
    --size $VmSize `
    --admin-username azureuser `
    --authentication-type ssh `
    --ssh-key-values $pub `
    --public-ip-sku Standard `
    --output none

Write-Host "Abriendo puerto 80 (HTTP)..." -ForegroundColor Cyan
az vm open-port --resource-group $ResourceGroupName --name $VmName --port 80 --output none

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
Write-Host "Timeout del comando remoto: $RunCommandTimeoutSeconds s" -ForegroundColor Gray

az vm run-command invoke `
    --resource-group $ResourceGroupName `
    --name $VmName `
    --command-id RunShellScript `
    --scripts "echo $b64 | base64 -d > /tmp/bootstrap.sh && chmod +x /tmp/bootstrap.sh && /tmp/bootstrap.sh" `
    --timeout-in-seconds $RunCommandTimeoutSeconds `
    -o table

if ($LASTEXITCODE -ne 0) {
    Write-Warning "El comando remoto devolvió error. Conéctate por SSH y revisa: sudo tail -200 /var/log/peluqueria-bootstrap.log"
}

$ip = az vm list-ip-addresses -g $ResourceGroupName -n $VmName --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv
if (-not $ip) {
    $ip = az network public-ip list -g $ResourceGroupName --query "[0].ipAddress" -o tsv
}

Write-Host ""
Write-Host "=== Listo ===" -ForegroundColor Green
Write-Host "Frontend + API (mismo sitio, Nginx -> Gateway): http://$ip"
Write-Host "Credenciales demo: admin@peluqueria.demo / Admin123"
Write-Host "Comprobar contenedores: ssh azureuser@$ip 'sudo docker compose -f /opt/peluqueria-app/docker-compose.yml ps'"
Write-Host "Log en la VM: ssh azureuser@$ip 'sudo tail -100 /var/log/peluqueria-bootstrap.log'"
Write-Host ""
