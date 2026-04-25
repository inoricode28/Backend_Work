@echo off
setlocal enabledelayedexpansion

:menu
cls
echo =====================================
echo          Menu de Opciones
echo =====================================
echo 1. Crear Proyecto Dotnet2
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

:: Paso 2: Instalar Swagger
echo Instalando Swagger...
dotnet add package Swashbuckle.AspNetCore --version 2.2.0

:: Paso 3: Instalar Paquetes
echo Instalando paquetes adicionales...
dotnet add package Microsoft.AspNetCore.Authentication.Cookies --version 2.2.0
dotnet add package Microsoft.EntityFrameworkCore.Relational --version 2.2.6
dotnet add package Microsoft.VisualStudio.Web.CodeGeneration.Design --version 2.2.3
dotnet add package Pomelo.EntityFrameworkCore.MySql --version 2.2.0
dotnet add package Microsoft.EntityFrameworkCore.Design --version 2.2.6

:: Construir cadena de conexión
set "connection_string=server=%db_host%;database=%db_name%;user=%db_user%;"
if not "%db_password%"=="" set "connection_string=%connection_string%password=%db_password%;"

:: Paso 4: Importar el modelo desde MySQL
echo.
echo Importando el modelo desde MySQL...
echo Base de datos: %db_name%
echo Host: %db_host%
echo Usuario: %db_user%

:: Crear nombre del DbContext
set "dbcontext_name=Db%db_name%Contex"
set "dbcontext_name=%dbcontext_name: =%"
set "dbcontext_name=%dbcontext_name:-=%"
set "dbcontext_name=%dbcontext_name:_=%"

dotnet ef dbcontext scaffold "%connection_string%" Pomelo.EntityFrameworkCore.MySql -o Models -c %dbcontext_name% -f

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

:: Paso 5: Generar controladores para todas las tablas
echo.
echo =====================================
echo Generando controladores para todas las tablas...
echo =====================================

if exist "Models\*.cs" (
    for %%M in (Models\*.cs) do (
        set "modelo=%%~nM"
        if not "!modelo!"=="%dbcontext_name%" (
            if not "!modelo!"=="DbContext" (
                if not "!modelo!"=="DesignTimeDbContextFactory" (
                    echo Generando controlador para: !modelo!
                    dotnet aspnetcodegenerator controller -name !modelo!Controller -async -api -m !modelo! -dc %dbcontext_name% -outDir Controllers -f
                    echo.
                )
            )
        )
    )
) else (
    echo No se encontraron modelos en la carpeta Models
)

echo.
echo =====================================
echo Proyecto creado exitosamente!
echo - Modelos importados desde: %db_name%
echo - Controladores generados: Ver carpeta Controllers
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

:iniciar_proyecto
cls
echo =====================================
echo          Iniciando Proyecto WebAPI
echo =====================================

cd /d "%~dp0"
for /d %%F in (*) do (
    if exist "%%F\*.csproj" (
        cd "%%F"
        start cmd /k "dotnet run"
        timeout /t 10 >nul
        start "" "http://localhost:5000/api-docs/"
        goto :fin
    )
)

echo No se encontro ningun proyecto .NET
dir /b /ad
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
echo 0. Volver al menu principal
echo =====================================
set /p "tool_choice=Elige una opcion (0-5): "

if "%tool_choice%"=="1" goto crear_database
if "%tool_choice%"=="2" goto eliminar_database
if "%tool_choice%"=="3" goto super_usuario
if "%tool_choice%"=="4" goto listar_paquetes
if "%tool_choice%"=="5" goto regenerar_controladores
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
goto tools_menu

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
goto tools_menu

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
goto tools_menu

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
goto tools_menu

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
            set "dbcontext_name=Db%db_name%Contex"
        )
        
        echo DbContext: %dbcontext_name%
        echo Generando controladores...
        
        for %%M in (Models\*.cs) do (
            set "modelo=%%~nM"
            if not "!modelo!"=="%dbcontext_name%" (
                if not "!modelo!"=="DbContext" (
                    echo Generando: !modelo!
                    dotnet aspnet-codegenerator controller -name !modelo!Controller -async -api -m !modelo! -dc %dbcontext_name% -outDir Controllers -f
                )
            )
        )
        goto :fin_reg
    )
)
echo No se encontro proyecto
:fin_reg
pause
goto tools_menu

:salir
exit