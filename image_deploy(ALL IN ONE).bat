@echo off
cd /d "%~dp0.\images"
echo Loading frontend...
docker load -i frontend-image.tar
echo Frontend load completed.

echo Loading database...
docker load -i postgres.tar
echo Database load completed.

echo Loading backend...
docker load -i backend-image.tar
echo Backend load completed.

docker-compose up --build -d

pause
