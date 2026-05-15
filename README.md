# Peluquería — Microservicios (Spring Boot + React + Docker + Azure)

Monorepo listo para el parcial: **autenticación JWT** (registro/login), roles **ADMIN** / **USER**, dos microservicios de dominio (**citas** en PostgreSQL y **catálogo de servicios** en MySQL), **API Gateway**, frontend **React**, **Docker Compose** y script de **despliegue en Azure VM** con Docker.

## Arquitectura

| Servicio        | Puerto | Base de datos   | Responsabilidad                                      |
|----------------|--------|-----------------|------------------------------------------------------|
| `api-gateway`  | 8080   | —               | Enruta `/api/auth`, `/api/citas`, `/api/servicios` |
| `ms-auth`      | 8081   | MySQL (`auth_db`) | Registro, login, JWT, usuarios y roles            |
| `ms-citas`     | 8082   | PostgreSQL      | CRUD de citas / reservas                            |
| `ms-servicios` | 8083   | MySQL (`servicios_db`) | CRUD de servicios (ADMIN escribe; USER lee)   |
| `frontend`     | 80     | —               | Nginx + SPA React; proxy `/api` → gateway          |

**MySQL** aloja dos bases distintas en el mismo servidor Docker (`auth_db` y `servicios_db`). **PostgreSQL** aloja `citas_db`.

Capas por microservicio: **Controller → Service → Repository → Entity / DTO**.

## Requisitos locales

- JDK 17, Maven 3.9+
- Node.js 20+
- Docker Desktop (Windows)

## Levantar todo con Docker

En la raíz del proyecto:

```powershell
docker compose up -d --build
```

- Frontend: **http://localhost** (Nginx sirve la SPA y enruta `/api` al gateway).
- API (gateway): **http://localhost:8080** — la raíz `/` responde con un **JSON informativo** (no hay interfaz web en el gateway). La API está bajo `/api/...`.

Comprueba salud:

```powershell
docker compose ps
```

## Credenciales de acceso al frontend

Si la tabla de usuarios está **vacía** (primera vez con Docker o MySQL nuevo), se crea automáticamente un usuario demo:

| Campo | Valor |
|--------|--------|
| **Email** | `admin@peluqueria.demo` |
| **Contraseña** | `Admin123` |

Puedes **registrarte** con otro email: esas cuentas serán **USER** mientras exista el usuario demo **ADMIN** (o en una base totalmente vacía sin demo, el **primer registro** sigue siendo **ADMIN** por la lógica de `ms-auth`).

## Desarrollo sin Docker (opcional)

1. Arranca MySQL (3306) y PostgreSQL (5432) con las credenciales por defecto del `application.yml` o variables de entorno.
2. Backend: en `backend`, `mvn spring-boot:run -pl ms-auth` (y análogo para `ms-citas`, `ms-servicios`, `api-gateway`) o ejecuta los JAR generados con `mvn package`.
3. Frontend: en `frontend`, `npm install` y `npm run dev` (Vite proxy `/api` → `http://localhost:8080`).

## Variables de entorno importantes

Copia `.env.example` a `.env` y ajusta (no subas `.env` a Git):

- `JWT_SECRET_BASE64`: Base64 de **al menos 32 bytes**; el mismo valor en **todos** los servicios que validan el JWT (auth, citas, servicios).
- `MYSQL_ROOT_PASSWORD`, `POSTGRES_PASSWORD`
- `CORS_ALLOWED_ORIGIN_PATTERNS` (solo si el frontend y el gateway están en orígenes distintos).

## Producción y seguridad

- Cambia **siempre** `JWT_SECRET_BASE64` y contraseñas de bases de datos en entornos reales.
- Los perfiles `prod` usan `spring.jpa.hibernate.ddl-auto=update` para simplificar el despliegue académico; en un producto real conviene **Flyway/Liquibase** y `validate`.
- Expón solo el **puerto 80** (frontend) o el **gateway** detrás de HTTPS (Application Gateway / CDN).

## Despliegue automático en Azure (consola)

Guía detallada paso a paso (errores comunes, SSH, Moodle): **[azure/PASO-A-PASO-AZURE.md](azure/PASO-A-PASO-AZURE.md)**.

Resumen:

```powershell
az login
cd "c:\proyectos\Parcial Arle"
.\azure\deploy-vm-docker-compose.ps1 `
  -ResourceGroupName "rg-peluqueria-tuapellido" `
  -RepoUrl "https://github.com/TU_USUARIO/TU_REPO.git"
```

Requisitos: Azure CLI, `az login`, clave SSH en `%USERPROFILE%\.ssh\id_rsa.pub`, repo **público** en GitHub. La primera construcción en la VM puede tardar **15–45 min**; el script usa timeout de **1 h** y **swap** en la VM para reducir fallos al compilar.

Al terminar abre **http://TU_IP** (frontend + `/api` vía Nginx al gateway).

Si despliegas frontend y backend en **hosts distintos**, construye el frontend con `VITE_API_URL` y ajusta CORS en el gateway (ver guía en `azure/PASO-A-PASO-AZURE.md`).

## Entrega académica (Moodle)

1. Subir el código a **GitHub público**.
2. Desplegar (Azure u otro proveedor) y dejar **URLs accesibles**.
3. En Moodle: enlace a GitHub, URL del backend (o gateway) y URL del frontend.

## Estructura del repositorio

```
backend/
  pom.xml                 # multi-módulo Maven
  shared-jwt/             # JWT HS256 compartido
  ms-auth/
  ms-citas/
  ms-servicios/
  api-gateway/
frontend/                 # React + Vite + TypeScript
docker/
  mysql-init/
docker-compose.yml
azure/
  deploy-vm-docker-compose.ps1
```

## Licencia

Uso académico / parcial.
