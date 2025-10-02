# Jenkins Docker Installation

This repository provides a script and configuration to set up Jenkins with Blue Ocean and Docker-in-Docker (DinD) support on Windows using Docker Desktop.

## Prerequisites

### 1. Install Git
- **Where to Get It**: Download from [git-scm.com](https://git-scm.com/download/win).
- **Installation Steps**:
  1. Run the installer.
  2. Accept the default settings (e.g., "Git Bash" and "Git CMD").
  3. Verify installation: Open a Command Prompt or PowerShell and run `git --version`.

### 2. Install Docker Desktop
- **Where to Get It**: Download from [docker.com](https://www.docker.com/products/docker-desktop).
- **Installation Steps**:
  1. Run the installer.
  2. During setup, ensure "Install required Windows components" is checked.
  3. After installation, open Docker Desktop.
  4. Switch to Linux containers (Settings > General > Switch to Linux containers).
  5. Verify installation: Run `docker --version` in Command Prompt or PowerShell.
  6. Ensure WSL 2 backend is enabled (Settings > Resources > WSL Integration).

### 3. Clone the Repository
- Run:
  ```powershell
  git clone https://github.com/Zerocode-sean/jenkins-docker-install
  cd jenkins-docker-install
## Setup Instructions
1. Run the setup script on powershell : 
## .\setup.ps1 
  This creates the network, builds the custom Jenkins image, and starts containers using docker-compose.
  **Verification**

## Check running containers:
## powershelldocker ps by command :
docker image ls

## Access Jenkins UI: 
http://localhost:8080
**Unlock with initial admin password**
docker logs jenkins-blueocean | Select-String "initialAdminPassword"
Post-Installation Setup Wizard

Follow the wizard at http://localhost:8080 to unlock Jenkins, install plugins, and create an admin user.

## Troubleshooting

**UI Inaccessible:**

**Check containers:**
 docker ps.

If exited, check logs: docker logs jenkins-blueocean.
Fix: docker-compose down -v && docker-compose up -d.


**Build Failure:**
 Simplify Dockerfile plugins, rebuild with 
 *docker build -t myjenkins-blueocean:2.516.3-1*
**Network Issues:** 
**Recreate network:**
  *docker network create jenkins*
**Port Conflict:**
*Check netstat -aon | findstr :8080*,
*adjust to* 9000:8080 in docker-compose.yml.
## Startup Delay: Wait 2-5 minutes.
## Firewall: 
**Allow port 8080:** 
*netsh advfirewall firewall add rule name="Jenkins 8080" dir=in action=allow protocol=TCP localport=8080.*
## Logs: 
*docker-compose logs or docker logs jenkins-blueocean.*