@echo off
echo Starting the build process...

echo ------------ frontend docker build end ------------

REM Step 2: Navigate to backend directory and build Docker image (JAR deployment)
echo Building backend Docker image...
cd /d "%~dp0..\cloth_shop_server"
call mvnw.cmd clean package 
docker build -t backend-image .

REM Step 3: Navigate to deploy directory and start Docker Compose
echo Starting Docker Compose...
cd /d "%~dp0"
echo Current directory is: %cd%
docker-compose up --build -d

echo Build and deployment completed!
pause
