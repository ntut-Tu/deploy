@echo off
set /p projectType="Enter the project to update (web/server): "

if /I "%projectType%"=="web" (
    echo Updating frontend...
    cd /d "%~dp0..\cloth_shop_web"
    call npm install
    call npm run build
    docker build -t frontend-image .
    echo Frontend build completed.
    echo Restarting frontend container...
    docker-compose -f "%~dp0docker-compose.yml" up --build -d frontend
    echo Frontend container restarted.
) else if /I "%projectType%"=="server" (
    echo Updating server...
    cd /d "%~dp0..\cloth_shop_server"
    call mvnw.cmd clean package
    docker build -t backend-image .
    echo Backend build completed.
    echo Restarting backend container...
    docker-compose -f "%~dp0docker-compose.yml" up --build -d backend db
    echo Backend container restarted.
) else (
    echo Invalid input! Please enter either 'frontend', 'server'.
)

pause
