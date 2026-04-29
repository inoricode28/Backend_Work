@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo =====================================
echo Crear Proyecto WebAPI
echo =====================================
echo.

REM Leer archivo .env
if exist .env (
    echo Archivo .env encontrado. Leyendo credenciales...
    for /f "tokens=1,* delims==" %%a in (.env) do (
        set "%%a=%%b"
    )
) else (
    echo Archivo .env no encontrado. Usando valores por defecto.
)

REM Configuración de base de datos del .env
if "%DB_HOST%"=="" set "DB_HOST=192.168.1.156"
if "%DB_NAME%"=="" set "DB_NAME=zuika"
if "%DB_USER%"=="" set "DB_USER=nova"
if "%DB_PASSWORD%"=="" set "DB_PASSWORD="

REM Nombre del proyecto
set /p "projectName=Introduce el nombre del proyecto (Ejemplo: MiProyectoAPI): "
if "%projectName%"=="" (
    set "projectName=MiProyectoAPI"
    echo Usando nombre por defecto: %projectName%
)

echo.
echo Creando proyecto WebAPI...
dotnet new webapi -n %projectName%
if errorlevel 1 (
    echo Error al crear el proyecto
    pause
    exit /b 1
)

cd %projectName%

echo.
echo Instalando paquetes necesarios...
dotnet add package Swashbuckle.AspNetCore
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.Relational
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Microsoft.EntityFrameworkCore.Tools
dotnet add package Microsoft.VisualStudio.Web.CodeGeneration.Design
dotnet add package Pomelo.EntityFrameworkCore.MySql

echo.
echo Verificando instalacion de dotnet-aspnet-codegenerator...
dotnet tool list -g | findstr "dotnet-aspnet-codegenerator" >nul
if errorlevel 1 (
    echo Instalando dotnet-aspnet-codegenerator...
    dotnet tool install --global dotnet-aspnet-codegenerator
) else (
    echo dotnet-aspnet-codegenerator ya esta instalado
)

REM Construir connection string
set "connectionString=Server=%DB_HOST%;Database=%DB_NAME%;User=%DB_USER%;Password=%DB_PASSWORD%;"

echo.
echo Conectando a base de datos: %DB_NAME% en %DB_HOST%...
echo Importando modelos desde MySQL...
dotnet ef dbcontext scaffold "%connectionString%" "Pomelo.EntityFrameworkCore.MySql" --context-dir Data --output-dir Models --force --context DbsaigotecContext

if errorlevel 1 (
    echo Error al importar modelos
    pause
    exit /b 1
)

echo Modelos importados exitosamente

echo.
echo =====================================
echo Generando controladores para todas las tablas...
echo =====================================

REM Generar controladores
for %%f in (Models\*.cs) do (
    set "filename=%%~nf"
    if not "!filename!"=="DbsaigotecContext" (
        echo Generando controlador para: !filename!
        dotnet aspnet-codegenerator controller -name "!filename!Controller" -m !filename! -dc DbsaigotecContext -namespace "%projectName%.Controllers" -outDir Controllers --useDefaultLayout --referenceScriptLibraries -f
        if errorlevel 1 (
            echo Error generando controlador para !filename!
        ) else (
            echo ^> Controlador para !filename! creado
        )
    )
)

echo.
echo Configurando Program.cs con CORS y Swagger...

REM Crear Program.cs
(
echo using %projectName%.Data;
echo using Microsoft.EntityFrameworkCore;
echo.
echo var builder = WebApplication.CreateBuilder(args^);
echo.
echo // Configuracion de conexion a MySQL
echo var connectionString = builder.Configuration.GetConnectionString^("DefaultConnection"^) 
echo     ?? "Server=%DB_HOST%;Database=%DB_NAME%;User=%DB_USER%;Password=%DB_PASSWORD%;";
echo.
echo builder.Services.AddDbContext^<DbsaigotecContext^>(options =^>
echo     options.UseMySql^(connectionString, ServerVersion.AutoDetect^(connectionString^)^)^);
echo.
echo // Add services to the container.
echo builder.Services.AddControllers^(^);
echo.
echo // Configuracion de Swagger/OpenAPI
echo builder.Services.AddEndpointsApiExplorer^(^);
echo builder.Services.AddSwaggerGen^(c =^>
echo {
echo     c.SwaggerDoc^("v1", new Microsoft.OpenApi.Models.OpenApiInfo
echo     {
echo         Title = "%projectName% API",
echo         Version = "v1",
echo         Description = "API generada automaticamente desde la base de datos %DB_NAME%"
echo     }^);
echo }^);
echo.
echo // Configuracion CORS - Permitir todos los origenes
echo builder.Services.AddCors^(options =^>
echo {
echo     options.AddPolicy^("AllowAll", policy =^>
echo     {
echo         policy.AllowAnyOrigin^(^)
echo               .AllowAnyMethod^(^)
echo               .AllowAnyHeader^(^);
echo     }^);
echo }^);
echo.
echo var app = builder.Build^(^);
echo.
echo // Configure the HTTP request pipeline.
echo if ^(app.Environment.IsDevelopment^(^)^)
echo {
echo     app.UseSwagger^(^);
echo     app.UseSwaggerUI^(c =^>
echo     {
echo         c.SwaggerEndpoint^("/swagger/v1/swagger.json", "%projectName% API v1"^);
echo         c.RoutePrefix = "swagger";
echo     }^);
echo }
echo.
echo app.UseHttpsRedirection^(^);
echo app.UseCors^("AllowAll"^);
echo app.UseAuthorization^(^);
echo app.MapControllers^(^);
echo.
echo app.Run^(^);
) > Program.cs

echo.
echo Configurando appsettings.json...

(
echo {
echo   "Logging": {
echo     "LogLevel": {
echo       "Default": "Information",
echo       "Microsoft.AspNetCore": "Warning"
echo     }
echo   },
echo   "ConnectionStrings": {
echo     "DefaultConnection": "Server=%DB_HOST%;Database=%DB_NAME%;User=%DB_USER%;Password=%DB_PASSWORD%;"
echo   },
echo   "AllowedHosts": "*"
echo }
) > appsettings.json

echo.
echo Compilando el proyecto...
dotnet build

echo.
echo =====================================
echo Proyecto creado exitosamente
echo - Modelos importados desde: %DB_NAME%
echo - Controladores generados: Ver carpeta Controllers
echo - CORS configurado para aceptar todos los origenes
echo - Swagger disponible en: /swagger
echo =====================================

cd ..

echo.
pause