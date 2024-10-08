@echo off
echo Starting the build process...

REM Step 1: Navigate to frontend directory and build Docker image
echo Building frontend Docker image...
cd /d "%~dp0..\cloth_shop_web"
call npm install
call npm run build
docker build -t your-frontend-image .

REM Step 2: Navigate to backend directory and build Docker image (JAR deployment)
echo Building backend Docker image...
cd /d "%~dp0..\cloth_shop_server"
call mvn clean package
docker build -t your-backend-image .

REM Step 3: Navigate to deploy directory and start Docker Compose
echo Starting Docker Compose...
cd /d "%~dp0"
docker-compose up --build -d

echo Build and deployment completed!
pause
