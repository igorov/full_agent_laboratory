@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
:: CONFIGURACIÓN — Edita estas variables antes de ejecutar
:: ==============================================================================

set GCP_PROJECT=pragmatic-ratio-478805-u2
set GCP_REGION=us-central1
set AR_REPOSITORY=repo
set IMAGE_NAME=agent-api
set CLOUD_RUN_SERVICE=agent-api-service
set CLOUD_RUN_PORT=8080
set ENV_FILE=..\.env

:: ==============================================================================
:: PRIMERA VEZ: autenticar Docker con Artifact Registry
:: Descomenta la siguiente línea si es la primera vez que usas este repositorio
:: ==============================================================================
:: gcloud auth configure-docker "%GCP_REGION%-docker.pkg.dev" --quiet

:: ==============================================================================
:: NO EDITAR DESDE AQUÍ
:: ==============================================================================

:: Tag único basado en fecha y hora: YYYYMMDD-HHmmss
for /f "tokens=1-6 delims=/:. " %%a in ("%date% %time%") do (
    set _YY=%%a
    set _MM=%%b
    set _DD=%%c
    set _HH=%%d
    set _MIN=%%e
    set _SS=%%f
)
:: Formato: YYYYMMDD-HHmmss
set IMAGE_TAG=%_YY%%_MM%%_DD%-%_HH%%_MIN%%_SS%
:: Eliminar posibles espacios del HH cuando es hora de un dígito
set IMAGE_TAG=%IMAGE_TAG: =0%

set AR_HOSTNAME=%GCP_REGION%-docker.pkg.dev
set FULL_IMAGE=%AR_HOSTNAME%/%GCP_PROJECT%/%AR_REPOSITORY%/%IMAGE_NAME%:%IMAGE_TAG%

echo ============================================================
echo   BUILD ^& DEPLOY — agent-api ^> Cloud Run
echo ============================================================
echo   Proyecto  : %GCP_PROJECT%
echo   Region    : %GCP_REGION%
echo   Imagen    : %FULL_IMAGE%
echo   Servicio  : %CLOUD_RUN_SERVICE%
echo ============================================================

:: 1. Configurar proyecto activo en gcloud
echo.
echo [1/4] Configurando proyecto GCP...
gcloud config set project %GCP_PROJECT%
if errorlevel 1 ( echo ERROR en gcloud config set project & exit /b 1 )

:: 2. Construir imagen Docker
echo.
echo [2/4] Construyendo imagen Docker...
docker build -t "%FULL_IMAGE%" ..
if errorlevel 1 ( echo ERROR al construir imagen Docker & exit /b 1 )

:: 3. Subir imagen a Artifact Registry
echo.
echo [3/4] Subiendo imagen a Artifact Registry...
docker push "%FULL_IMAGE%"
if errorlevel 1 ( echo ERROR al hacer push de la imagen & exit /b 1 )

:: 4. Leer .env y construir el argumento --set-env-vars para Cloud Run
echo.
echo [4/4] Desplegando en Cloud Run...

if not exist "%ENV_FILE%" (
    echo ERROR: No se encontro el archivo %ENV_FILE%
    exit /b 1
)

:: Lee el .env, ignora comentarios y líneas vacías, construye KEY=VALUE,...
set ENV_VARS=
for /f "usebackq tokens=* delims=" %%L in ("%ENV_FILE%") do (
    set LINE=%%L
    :: Ignorar líneas vacías o comentarios
    if not "!LINE!"=="" (
        if not "!LINE:~0,1!"=="#" (
            if "!ENV_VARS!"=="" (
                set ENV_VARS=!LINE!
            ) else (
                set ENV_VARS=!ENV_VARS!,!LINE!
            )
        )
    )
)

gcloud run deploy %CLOUD_RUN_SERVICE% ^
  --image "%FULL_IMAGE%" ^
  --region %GCP_REGION% ^
  --platform managed ^
  --allow-unauthenticated ^
  --port %CLOUD_RUN_PORT% ^
  --set-env-vars "!ENV_VARS!"
if errorlevel 1 ( echo ERROR al desplegar en Cloud Run & exit /b 1 )

echo.
echo ============================================================
echo   Despliegue completado exitosamente
echo   Imagen : %FULL_IMAGE%
echo ============================================================

endlocal
