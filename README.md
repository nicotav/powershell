# PowerShell Troubleshooting Scripts

A collection of PowerShell scripts designed to assist with common Windows troubleshooting tasks.

## 📁 Project Structure

```
powershell/
├── Core/                    # PowerShell function modules
│   ├── Network/            # Network-related troubleshooting functions
│   ├── System/             # System diagnostics and health checks
│   ├── Storage/            # Disk and storage utilities
│   ├── Services/           # Windows services management
│   ├── Security/           # Security and permissions helpers
│   ├── ActiveDirectory/    # Active Directory management and diagnostics
│   └── ExchangeOnline/     # Exchange Online mailbox and configuration tools
├── Examples.ps1            # Showcase script demonstrating all functions
└── README.md
```

## 🎯 Purpose

This repository provides reusable PowerShell functions to streamline common Windows troubleshooting workflows. Each function is organized by its nature within the `Core/` folder for easy navigation and maintenance.

## 📂 Core Folder Organization

The `Core/` folder contains PowerShell modules segregated by their purpose:

| Folder | Description |
|--------|-------------|
| **Network/** | Network connectivity, DNS, firewall diagnostics |
| **System/** | System info, event logs, performance monitoring |
| **Storage/** | Disk space, file operations, cleanup utilities |
| **Services/** | Service status, start/stop, dependency checks |
| **Security/** | Permissions, user accounts, security audits |
| **ActiveDirectory/** | AD user/computer/group management, replication health |
| **ExchangeOnline/** | Mailbox info, permissions, distribution groups, mail flow |

## 🚀 Getting Started

### Option 1: Clone the Repository

```powershell
# Clone the repo to your local machine
git clone https://github.com/nicotav/powershell.git

# Navigate to the folder
cd powershell

# Run the examples to see all functions in action
.\Examples.ps1
```

### Option 2: Download and Run Directly (No Git Required)

```powershell
# Download the entire repo as a ZIP
Invoke-WebRequest -Uri "https://github.com/nicotav/powershell/archive/refs/heads/main.zip" -OutFile "$env:TEMP\powershell.zip"

# Extract it
Expand-Archive -Path "$env:TEMP\powershell.zip" -DestinationPath "$env:TEMP\powershell-scripts" -Force

# Navigate and run
cd "$env:TEMP\powershell-scripts\powershell-main"
.\Examples.ps1
```

### Option 3: Load a Single Module Directly from GitHub

```powershell
# Load Network functions directly (no download required)
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Network.ps1").Content

# Now use the functions
Test-NetworkConnectivity -Target "google.com"
```

## 📦 Usage

### Load All Functions

```powershell
# After cloning, dot-source all modules
$CorePath = "C:\path\to\powershell\Core"
. "$CorePath\Network\Network.ps1"
. "$CorePath\System\System.ps1"
. "$CorePath\Storage\Storage.ps1"
. "$CorePath\Services\Services.ps1"
. "$CorePath\Security\Security.ps1"
```

### Load Specific Module

```powershell
# Load only what you need
. "C:\path\to\powershell\Core\Network\Network.ps1"

# Use the functions
Test-NetworkConnectivity -Target "8.8.8.8"
Get-DNSResolution -Hostname "google.com"
```

## 📝 Examples

See `Examples.ps1` for a comprehensive showcase of all available functions and their usage patterns.
