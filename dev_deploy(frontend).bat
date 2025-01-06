@echo off
echo Updating frontend...
cd /d "%~dp0..\cloth_shop_web"
call npm install
call npm run build
docker build -t frontend-image .
echo Frontend build completed.
echo Restarting frontend container...
cd /d "%~dp0"
docker-compose up --build -d
echo Frontend container restarted.

pause
