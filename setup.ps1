#!/usr/bin/env pwsh
# Jenkins Docker Installation Script for Windows
# Run: .\setup.ps1 -UseCompose $true
# Prerequisites: Docker Desktop (Linux containers mode), PowerShell 5+, Git

param(
    [string]$ImageTag = "2.516.3-1",
    [bool]$UseCompose = $true
)

Write-Host "Starting Jenkins Docker Installation..." -ForegroundColor Green

# Step 1: Ensure Docker is running
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker not found. Install Docker Desktop for Windows and switch to Linux containers (Settings > General)."
    exit 1
}
docker --version

# Step 2: Check port 8080
Write-Host "Checking port 8080 availability..." -ForegroundColor Yellow
$portCheck = netstat -aon | Select-String ":8080"
if ($portCheck) {
    Write-Warning "Port 8080 is in use. Edit docker-compose.yml to use another port (e.g., 9000:8080) and rerun."
    Write-Host "To check process: tasklist | findstr <PID>"
}

# Step 3: Clean up existing resources
Write-Host "Cleaning up existing network and containers..." -ForegroundColor Yellow
docker-compose down -v 2>$null
$containers = docker ps -a -q
if ($containers) {
    docker stop $containers
    docker rm $containers
}
$network = docker network ls -q -f name=jenkins
if ($network) {
    docker network rm $network 2>$null
    if ($LASTEXITCODE -ne 0) {
        docker network prune -f
    }
}

# Step 4: Create bridge network
Write-Host "Creating Jenkins network..." -ForegroundColor Yellow
docker network create jenkins
docker network ls | Select-String "jenkins"

# Step 5: Verify docker-compose.yml
Write-Host "Checking docker-compose.yml..." -ForegroundColor Yellow
if (-not (Test-Path docker-compose.yml)) {
    Write-Error "docker-compose.yml not found in current directory."
    exit 1
}
if (-not (Get-Content docker-compose.yml | Select-String "jenkins-blueocean")) {
    Write-Error "docker-compose.yml missing jenkins-blueocean service. Ensure it includes both jenkins-docker and jenkins-blueocean services."
    exit 1
}

# Step 6: Build custom Jenkins image
Write-Host "Building custom Jenkins image (myjenkins-blueocean:$ImageTag)..." -ForegroundColor Yellow
docker build -t "myjenkins-blueocean:$ImageTag" .
if ($LASTEXITCODE -ne 0) {
    Write-Error "Image build failed. Check logs for plugin or network errors. Simplify plugins in Dockerfile if needed."
    exit 1
}

# Step 7: Setup based on mode
if ($UseCompose) {
    Write-Host "Using docker-compose for setup..." -ForegroundColor Yellow
    docker-compose up -d
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker-compose failed. Check docker-compose.yml or logs: docker-compose logs"
        exit 1
    }
} else {
    Write-Host "Running DinD container..." -ForegroundColor Yellow
    docker run --name jenkins-docker --rm --detach --privileged --network jenkins --network-alias docker `
      --env DOCKER_TLS_CERTDIR=/certs --volume jenkins-docker-certs:/certs/client --volume jenkins-data:/var/jenkins_home `
      --publish 2376:2376 docker:dind
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start DinD container. Ensure 'docker:dind' image is pulled: docker pull docker:dind"
        exit 1
    }

    Write-Host "Running Jenkins container..." -ForegroundColor Yellow
    docker run --name jenkins-blueocean --restart=on-failure --detach --network jenkins `
      --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 `
      --volume jenkins-data:/var/jenkins_home --volume jenkins-docker-certs:/certs/client:ro `
      --publish 8080:8080 --publish 50000:50000 "myjenkins-blueocean:$ImageTag"
}

# Step 8: Verify containers
Write-Host "Verifying containers..." -ForegroundColor Yellow
$jenkinsRunning = docker ps -q -f name=jenkins-blueocean
if (-not $jenkinsRunning) {
    Write-Error "Jenkins-blueocean container not running. Check logs: docker-compose logs jenkins-blueocean"
    docker-compose logs jenkins-blueocean
    exit 1
}

# Step 9: Wait for Jenkins to start and show password
Write-Host "Waiting for Jenkins to initialize (may take 2-5 minutes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
docker logs jenkins-blueocean | Select-String "initialAdminPassword"

# Step 10: Post-install instructions
Write-Host "`n=== Post-Installation ===" -ForegroundColor Green
Write-Host "1. Unlock Jenkins: docker logs jenkins-blueocean | Select-String 'initialAdminPassword'"
Write-Host "   Or: docker exec jenkins-blueocean cat /var/jenkins_home/secrets/initialAdminPassword"
Write-Host "2. Access UI: http://localhost:8080"
Write-Host "3. Follow the setup wizard to install plugins and create an admin user."
Write-Host "4. Customize: Edit Dockerfile for more plugins, rebuild, and rerun."
Write-Host "`nSuccess! Jenkins with Blue Ocean and Docker support is ready." -ForegroundColor Green
Write-Host "Troubleshooting: Check README.md or run 'docker logs jenkins-blueocean'." -ForegroundColor Cyan