@echo off
setlocal enabledelayedexpansion

:menu
cls
echo =====================================
echo          Menu de Opciones
echo =====================================
echo 1. Crear Proyecto Dotnet9
echo 2. Iniciar Proyecto
echo 3. Tools - Herramientas adicionales
echo 0. Salir
echo =====================================
set /p choice=Elige una opcion (0-3):

if %choice%==1 goto crear_proyecto
if %choice%==2 goto iniciar_proyecto
if %choice%==3 goto tools_menu
if %choice%==0 goto salir

:crear_proyecto
cls
echo =====================================
echo          Crear Proyecto WebAPI
echo =====================================

:: Inicializar variables con valores por defecto
set "db_host=localhost"
set "db_name=garagevirtual"
set "db_user=root"
set "db_password="

:: Verificar si existe archivo .env
if exist ".env" (
    echo Archivo .env encontrado. Leyendo credenciales...
    call :leer_env
) else (
    echo No se encontro archivo .env
    echo Usando valores por defecto o ingrese manualmente
    echo.
    set /p "db_host=Ingrese el HOST de la base de datos (Ejemplo: localhost): "
    set /p "db_name=Ingrese el nombre de la base de datos: "
    set /p "db_user=Ingrese el usuario de la base de datos: "
    set /p "db_password=Ingrese la contrasena de la base de datos: "
)

:: Solicitar el nombre del proyecto
echo.
set /p "project_name=Introduce el nombre del proyecto (Ejemplo: MiProyectoAPI): "

:: Crear el proyecto WebAPI con el nombre proporcionado
dotnet new webapi -o %project_name%
cd %project_name%

:: Instalar Swagger
echo Instalando Swagger...
dotnet add package Swashbuckle.AspNetCore --version 8.1.1

:: Instalar paquetes con versiones compatibles
echo Instalando paquetes adicionales...
dotnet add package Microsoft.EntityFrameworkCore --version 9.0.11
dotnet add package Microsoft.EntityFrameworkCore.Relational --version 9.0.11
dotnet add package Microsoft.EntityFrameworkCore.Design --version 9.0.11
dotnet add package Microsoft.EntityFrameworkCore.Tools --version 9.0.11
dotnet add package Microsoft.VisualStudio.Web.CodeGeneration.Design --version 9.0.11
dotnet add package Pomelo.EntityFrameworkCore.MySql --version 9.0.0-preview.2.efcore.9.0.0
dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version 8.0.0

:: Instalar herramienta dotnet-ef globalmente si no existe
echo Verificando instalacion de dotnet-ef...
dotnet tool install --global dotnet-ef --version 9.0.11 2>nul
if %errorlevel% neq 0 (
    echo dotnet-ef ya esta instalado o hubo un error
)

:: Construir cadena de conexión
set "connection_string=server=%db_host%;database=%db_name%;user=%db_user%;"
if not "%db_password%"=="" set "connection_string=%connection_string%password=%db_password%;"

:: Importar el modelo desde MySQL
echo.
echo Importando el modelo desde MySQL...
echo Base de datos: %db_name%
echo Host: %db_host%
echo Usuario: %db_user%

:: Crear nombre del DbContext
set "dbcontext_name=%db_name%Context"
set "dbcontext_name=%dbcontext_name: =%"
set "dbcontext_name=%dbcontext_name:-=%"
set "dbcontext_name=%dbcontext_name:_=%"

:: Ejecutar scaffold
dotnet ef dbcontext scaffold "%connection_string%" Pomelo.EntityFrameworkCore.MySql -o Models -c %dbcontext_name% -f

if %errorlevel% neq 0 (
    echo.
    echo ERROR: No se pudo importar la base de datos
    echo Verifica que:
    echo 1. La base de datos existe
    echo 2. Los datos de conexion son correctos
    echo 3. MySQL esta corriendo
    pause
    goto menu
)

echo.
echo Modelo importado exitosamente desde %db_name%

:: Guardar credenciales
echo %project_name% > "%~dp0proyecto_actual.txt"
echo %db_host% > "%~dp0db_host.txt"
echo %db_name% > "%~dp0db_name.txt"
echo %db_user% > "%~dp0db_user.txt"
echo %db_password% > "%~dp0db_password.txt"
echo %dbcontext_name% > "%~dp0dbcontext_name.txt"

:: Restaurar paquetes
dotnet restore

:: Verificar e instalar dotnet-aspnet-codegenerator si es necesario
call :check_codegenerator
if %errorlevel% neq 0 (
    pause
    goto menu
)

:: Generar controladores para todas las tablas
echo.
echo =====================================
echo Generando controladores para todas las tablas...
echo =====================================

if exist "Models\*.cs" (
    for %%M in (Models\*.cs) do (
        set "modelo=%%~nM"
        if not "!modelo!"=="%dbcontext_name%" (
            if not "!modelo!"=="DesignTimeDbContextFactory" (
                echo Generando controlador para: !modelo!
                dotnet aspnet-codegenerator controller -name !modelo!Controller -async -api -m !modelo! -dc %dbcontext_name% -outDir Controllers -f
                if !errorlevel! neq 0 (
                    echo Error generando controlador para !modelo!
                )
                echo.
            )
        )
    )
) else (
    echo No se encontraron modelos en la carpeta Models
)

:: ============================================================
:: MODIFICAR ARCHIVOS SEGÚN EL MOLDE (SIN DEPENDER DE POWERSHELL)
:: ============================================================
call :modificar_archivos_proyecto

echo.
echo =====================================
echo Proyecto creado exitosamente!
echo - Modelos importados desde: %db_name%
echo - Controladores generados: Ver carpeta Controllers
echo - Archivos configurados segun el molde
echo =====================================
pause
goto menu

:leer_env
for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    set "clave=%%a"
    set "valor=%%b"
    for /f "tokens=* delims= " %%c in ("!clave!") do set "clave=%%c"
    for /f "tokens=* delims= " %%c in ("!valor!") do set "valor=%%c"
    
    if "!clave!"=="HOST" set "db_host=!valor!"
    if "!clave!"=="DB_DATABASE" set "db_name=!valor!"
    if "!clave!"=="DB_USER" set "db_user=!valor!"
    if "!clave!"=="DB_PASSWORD" set "db_password=!valor!"
)
exit /b

:check_codegenerator
:: Verifica si dotnet-aspnet-codegenerator está instalado globalmente. Si no, lo instala.
echo Verificando instalacion de dotnet-aspnet-codegenerator...
dotnet tool list -g 2>nul | findstr /i "dotnet-aspnet-codegenerator" >nul
if %errorlevel% neq 0 (
    echo No encontrado. Instalando dotnet-aspnet-codegenerator version 9.0.0...
    dotnet tool install -g dotnet-aspnet-codegenerator --version 9.0.0 >nul 2>&1
    :: Verificar nuevamente si la instalación fue exitosa
    dotnet tool list -g 2>nul | findstr /i "dotnet-aspnet-codegenerator" >nul
    if %errorlevel% neq 0 (
        echo ERROR: No se pudo instalar dotnet-aspnet-codegenerator.
        echo Intente manualmente: dotnet tool install -g dotnet-aspnet-codegenerator --version 9.0.0
        exit /b 1
    ) else (
        echo dotnet-aspnet-codegenerator instalado correctamente.
    )
) else (
    echo dotnet-aspnet-codegenerator ya instalado.
)
exit /b 0

:iniciar_proyecto
cls
echo =====================================
echo          Iniciando Proyecto WebAPI
echo =====================================

cd /d "%~dp0"
for /d %%F in (*) do (
    if exist "%%F\*.csproj" (
        cd "%%F"
        echo Iniciando servidor en http://localhost:5000
        start cmd /k "dotnet run --urls=http://localhost:5000"
        timeout /t 3 >nul
        start "" "http://localhost:5000"
        goto :fin
    )
)

echo No se encontro ningun proyecto .NET
pause

:fin
cd /d "%~dp0"
goto menu

:tools_menu
cls
echo =====================================
echo          Tools - Herramientas
echo =====================================
echo 1. Crear Base de Datos
echo 2. Eliminar Base de Datos
echo 3. Super Usuario
echo 4. Listar paquetes instalados
echo 5. Regenerar Controladores
echo 6. Instalar/Actualizar dotnet-ef
echo 7. Instalar dotnet-aspnet-codegenerator
echo 8. Ver Paquete dotnet-aspnet-codegenerator
echo 0. Volver al menu principal
echo =====================================
set /p "tool_choice=Elige una opcion (0-6): "

if "%tool_choice%"=="1" goto crear_database
if "%tool_choice%"=="2" goto eliminar_database
if "%tool_choice%"=="3" goto super_usuario
if "%tool_choice%"=="4" goto listar_paquetes
if "%tool_choice%"=="5" goto regenerar_controladores
if "%tool_choice%"=="6" goto instalar_ef
if "%tool_choice%"=="7" goto instalar_codegenerator
if "%tool_choice%"=="8" goto ver_paquete
if "%tool_choice%"=="0" goto menu
goto tools_menu

:crear_database
cls
echo =====================================
echo       Creando Base de Datos
echo =====================================
cd /d "%~dp0"
if exist "src\database\db.js" (
    start cmd /k "echo CREANDO BASE DE DATOS && npm run babel-node src\database\db.js && pause"
) else (
    echo Error: No se encuentra src\database\db.js
    pause
)
goto menu

:eliminar_database
cls
echo =====================================
echo       Eliminando Base de Datos
echo =====================================
cd /d "%~dp0"
if exist "src\database\dbKill.js" (
    start cmd /k "echo ELIMINANDO BASE DE DATOS && npm run babel-node src\database\dbKill.js && pause"
) else (
    echo Error: No se encuentra src\database\dbKill.js
    pause
)
goto menu

:super_usuario
cls
echo =====================================
echo         Super Usuario
echo =====================================
cd /d "%~dp0"
if exist "src\database\SuperUsuario.js" (
    start cmd /k "echo CREANDO SUPER USUARIO && npm run babel-node src\database\SuperUsuario.js && pause"
) else (
    echo Error: No se encuentra src\database\SuperUsuario.js
    pause
)
goto menu

:listar_paquetes
cls
echo =====================================
echo     Listando paquetes instalados
echo =====================================
cd /d "%~dp0"
for /d %%F in (*) do (
    if exist "%%F\*.csproj" (
        start cmd /c "cd /d "%%F" && dotnet list package && timeout /t 60"
        goto :volver
    )
)
echo No se encontro proyecto
pause
:volver
goto menu

:regenerar_controladores
cls
echo =====================================
echo     Regenerar Controladores
echo =====================================
cd /d "%~dp0"
for /d %%F in (*) do (
    if exist "%%F\*.csproj" (
        cd "%%F"
        
        if exist "%~dp0dbcontext_name.txt" (
            set /p dbcontext_name=<"%~dp0dbcontext_name.txt"
        ) else if exist "%~dp0db_name.txt" (
            set /p db_name=<"%~dp0db_name.txt"
            set "dbcontext_name=%db_name%Context"
        )
        
        echo DbContext: %dbcontext_name%
        
        :: Verificar e instalar dotnet-aspnet-codegenerator si es necesario
        call :check_codegenerator
        if %errorlevel% neq 0 (
            pause
            goto menu
        )
        
        echo Generando controladores...
        
        if exist "Models\*.cs" (
            for %%M in (Models\*.cs) do (
                set "modelo=%%~nM"
                if not "!modelo!"=="%dbcontext_name%" (
                    if not "!modelo!"=="DesignTimeDbContextFactory" (
                        echo Generando: !modelo!
                        dotnet aspnet-codegenerator controller -name !modelo!Controller -async -api -m !modelo! -dc %dbcontext_name% -outDir Controllers -f
                    )
                )
            )
        ) else (
            echo No se encontraron modelos en Models
        )
        goto :fin_reg
    )
)
echo No se encontro proyecto
:fin_reg
pause
goto menu

:instalar_ef
cls
echo =====================================
echo     Instalando dotnet-ef
echo =====================================
dotnet tool install --global dotnet-ef --version 9.0.11
if %errorlevel% equ 0 (
    echo dotnet-ef instalado correctamente
) else (
    echo Actualizando dotnet-ef...
    dotnet tool update --global dotnet-ef --version 9.0.11
)
echo.
echo Para usar dotnet-ef, cierra y abre una nueva terminal
pause
goto menu

:instalar_codegenerator
cls
echo =====================================
echo     Instalando dotnet-aspnet-codegenerator
echo =====================================
dotnet tool install -g dotnet-aspnet-codegenerator --version 9.0.0
if %errorlevel% equ 0 (
    echo dotnet-aspnet-codegenerator instalado correctamente
) else (
    echo Actualizando dotnet-aspnet-codegenerator...
    dotnet tool update --global dotnet-aspnet-codegenerator --version 9.0.0
)
echo.
echo Para usar dotnet-aspnet-codegenerator, cierra y abre una nueva terminal
pause
goto menu

:ver_paquete
cls
echo =====================================
echo     Listando paquetes instalados
echo =====================================
cd /d "%~dp0"
for /d %%F in (*) do (
    
        start cmd /c "cd /d "%%F" && dotnet tool list -g && timeout /t 60"
        goto :volver
    
)
echo No se encontro proyecto
pause
:volver
goto menu

:salir
exit

:: ------------------------------------------------------------
:: SUBRUTINA PARA MODIFICAR PROGRAM.CS, APPSETTINGS.JSON Y LAUNCHSETTINGS.JSON
:: SIN USAR POWERSHELL (SOLO ECHO Y REDIRECCION)
:: ------------------------------------------------------------
:modificar_archivos_proyecto
echo.
echo Configurando archivos del proyecto segun el molde...

:: Asegurar que estamos en la carpeta del proyecto
cd /d "%project_name%" 2>nul

:: 1. Construir la cadena de conexion para appsettings.json
set "conn_string=server=%db_host%;database=%db_name%;user=%db_user%"
if not "%db_password%"=="" set "conn_string=%conn_string%;password=%db_password%"

:: 2. Generar appsettings.json completo
echo Generando appsettings.json...
(
echo { 
echo   "Logging": {
echo     "LogLevel": {
echo       "Default": "Information",
echo       "Microsoft.AspNetCore": "Warning"
echo     }
echo   },
echo   "AllowedHosts": "*",
echo   "ConnectionStrings": {
echo     "DefaultConnection": "%conn_string%"
echo   }
echo }
) > appsettings.json

:: 3. Generar launchSettings.json completo (con launchBrowser true y launchUrl "/")
echo Generando launchSettings.json...
if not exist "Properties" mkdir Properties
(
echo {
echo   "$schema": "https://json.schemastore.org/launchsettings.json",
echo   "profiles": {
echo     "http": {
echo       "commandName": "Project",
echo       "dotnetRunMessages": true,
echo       "launchBrowser": true,
echo       "launchUrl": "/",
echo       "applicationUrl": "http://localhost:5222",
echo       "environmentVariables": {
echo         "ASPNETCORE_ENVIRONMENT": "Development"
echo       }
echo     },
echo     "https": {
echo       "commandName": "Project",
echo       "dotnetRunMessages": true,
echo       "launchBrowser": true,
echo       "launchUrl": "/",
echo       "applicationUrl": "https://localhost:7247;http://localhost:5222",
echo       "environmentVariables": {
echo         "ASPNETCORE_ENVIRONMENT": "Development"
echo       }
echo     }
echo   }
echo }
) > Properties\launchSettings.json

:: 4. Generar Program.cs línea por línea (sin bloque de paréntesis)
echo Generando Program.cs...
del Program.cs 2>nul

> Program.cs echo using %project_name%.Models;
>> Program.cs echo using Microsoft.EntityFrameworkCore;
>> Program.cs echo.
>> Program.cs echo var builder = WebApplication.CreateBuilder(args^);
>> Program.cs echo.
>> Program.cs echo var connectionString = builder.Configuration.GetConnectionString("DefaultConnection"^);
>> Program.cs echo builder.Services.AddDbContext^<%dbcontext_name%^>(options =^> options.UseMySql(connectionString, Microsoft.EntityFrameworkCore.ServerVersion.AutoDetect(connectionString)^)^);
>> Program.cs echo.
>> Program.cs echo // Add services to the container.
>> Program.cs echo // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
>> Program.cs echo builder.Services.AddOpenApi(^);
>> Program.cs echo.
>> Program.cs echo // Servicios necesarios
>> Program.cs echo builder.Services.AddAuthorization(^); // ← AGREGAR
>> Program.cs echo builder.Services.AddControllers(^); // ← AGREGAR
>> Program.cs echo.
>> Program.cs echo // Configuracion de Swagger
>> Program.cs echo builder.Services.AddEndpointsApiExplorer(^);
>> Program.cs echo builder.Services.AddSwaggerGen(^);
>> Program.cs echo.
>> Program.cs echo var app = builder.Build(^);
>> Program.cs echo.
>> Program.cs echo // Configure the HTTP request pipeline.
>> Program.cs echo if (app.Environment.IsDevelopment(^)^)
>> Program.cs echo {
>> Program.cs echo     app.UseSwagger(^);
>> Program.cs echo     app.UseSwaggerUI(c =^>
>> Program.cs echo     {
>> Program.cs echo         c.SwaggerEndpoint("/swagger/v1/swagger.json", "Mi API v1"^);
>> Program.cs echo         c.RoutePrefix = string.Empty; // ^<--Accede en /swagger
>> Program.cs echo     }^);
>> Program.cs echo }
>> Program.cs echo.
>> Program.cs echo //// Configure the HTTP request pipeline.
>> Program.cs echo //if (app.Environment.IsDevelopment(^)^)
>> Program.cs echo //{
>> Program.cs echo //    app.MapOpenApi(^);
>> Program.cs echo //}
>> Program.cs echo.
>> Program.cs echo app.UseHttpsRedirection(^);
>> Program.cs echo app.UseAuthorization(^); //Se Agrego
>> Program.cs echo app.MapControllers(^); //Se Agrego
>> Program.cs echo.
>> Program.cs echo app.Run(^);

if exist Program.cs (
    echo Program.cs generado correctamente.
) else (
    echo ERROR: No se pudo generar Program.cs.
    exit /b 1
)

echo Archivos configurados correctamente.
exit /b