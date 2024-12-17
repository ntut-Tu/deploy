@echo off
echo Starting the build process...

REM Step 1: Navigate to frontend directory and build Docker image
echo Building frontend Docker image...
cd /d "%~dp0..\cloth_shop_web"
call npm install
call npm run build
echo ------------ frontend docker build ------------
docker build --progress=plain --no-cache -t  frontend-image .
echo ------------ frontend docker build end ------------

REM Step 2: Navigate to backend directory and build Docker image (JAR deployment)
echo Building backend Docker image...
cd /d "%~dp0..\cloth_shop_server"
call mvnw.cmd clean package -Ph2
docker build -t backend-image .

REM Step 3: Navigate to deploy directory and start Docker Compose
echo Starting Docker Compose...
cd /d "%~dp0"
docker-compose up --build -d

echo Build and deployment completed!
pause
