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
│   ├── ExchangeOnline/     # Exchange Online mailbox and configuration tools
│   ├── Azure/              # Azure/Entra ID user and policy management
│   ├── Microsoft365/       # Microsoft 365, Teams, SharePoint administration
│   ├── SQL/                # SQL Server database diagnostics
│   ├── IIS/                # IIS web server and app pool management
│   ├── HyperV/             # Hyper-V VM management and monitoring
│   ├── Certificates/       # Certificate expiration and validation
│   ├── GroupPolicy/        # Group Policy reporting and analysis
│   ├── Backup/             # Backup status and VSS management
│   ├── NetworkServices/    # DHCP, DNS server management
│   └── PrintServer/        # Print server and queue management
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
| **System/** | System info, event logs, performance monitoring, maintenance |
| **Storage/** | Disk space, file operations, cleanup utilities |
| **Services/** | Service status, start/stop, dependency checks |
| **Security/** | Permissions, user accounts, security audits, anomaly detection |
| **ActiveDirectory/** | AD user/computer/group management, replication health |
| **ExchangeOnline/** | Mailbox info, permissions, distribution groups, mail flow |
| **Azure/** | Azure/Entra ID users, Conditional Access, MFA, sign-in logs |
| **Microsoft365/** | Teams, SharePoint, OneDrive administration |
| **SQL/** | SQL Server database info, backups, performance |
| **IIS/** | IIS sites, app pools, bindings |
| **HyperV/** | Hyper-V VM status, resources, snapshots |
| **Certificates/** | Certificate expiration monitoring and validation |
| **GroupPolicy/** | GPO reports, links, and analysis |
| **Backup/** | Windows Backup status, VSS writers |
| **NetworkServices/** | DHCP scopes, DNS zones management |
| **PrintServer/** | Printer status, queue management |

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

## � Featured Tools

### Invoke-ComputerMaintenance.ps1
**Complete automated system maintenance script** that performs:
- ⏰ Time synchronization with Microsoft servers
- 🔧 Windows component repair (DISM & SFC)
- 📦 Windows Update + Driver updates
- 🏪 Microsoft Store & Winget package updates
- 🧹 Comprehensive temp file cleanup
- 🔒 Security hardening checks
- 📊 Detailed logging and reporting
- 🔄 Safe restart management

**Usage:** `iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Invoke-ComputerMaintenance.ps1')`

### Invoke-SecurityInspection.ps1
**First-aid security snapshot and anomaly detection tool** that captures:
- 🖥️ Complete system configuration
- 🌐 Network connections and listening ports  
- ⚙️ Running processes and services
- 🚀 Startup items and scheduled tasks
- 👥 User accounts and permissions
- 📦 Installed software and recent changes
- 🔍 Security events and failed logons
- ⚠️ Automated anomaly detection
- 📄 Interactive HTML report generation

**Usage:** `iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Invoke-SecurityInspection.ps1')`

## �📝 Examples

See `Examples.ps1` for a comprehensive showcase of all available functions and their usage patterns.
