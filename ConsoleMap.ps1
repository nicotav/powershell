#Requires -Version 5.1
<#
.SYNOPSIS
    Displays a visual map of the PowerShell Troubleshooting Scripts repository.

.DESCRIPTION
    This script provides a quick visual reference of the repository structure
    and available functions in the console.

.NOTES
    Repository: https://github.com/nicotav/powershell
    Author: Nicolas
    Date: January 2026
#>

# Define colors for better readability
$colors = @{
    Title       = "Cyan"
    Category    = "Yellow"
    Function    = "Green"
    Path        = "Magenta"
    Border      = "DarkGray"
}

# Clear screen for fresh display
Clear-Host

# Title and Header
Write-Host "" -ForegroundColor $colors.Border
Write-Host ("╔" + ("═" * 78) + "╗") -ForegroundColor $colors.Border
Write-Host ("║" + (" " * 78) + "║") -ForegroundColor $colors.Border
Write-Host ("║" + "  PowerShell Troubleshooting Scripts - Interactive Map".PadRight(78) + "║") -ForegroundColor $colors.Title
Write-Host ("║" + "  Repository: github.com/nicotav/powershell".PadRight(78) + "║") -ForegroundColor $colors.Path
Write-Host ("║" + (" " * 78) + "║") -ForegroundColor $colors.Border
Write-Host ("╚" + ("═" * 78) + "╝") -ForegroundColor $colors.Border
Write-Host ""

# Repository Structure
Write-Host "📁 REPOSITORY STRUCTURE" -ForegroundColor $colors.Category
Write-Host "├─ powershell/" -ForegroundColor $colors.Path
Write-Host "│  ├─ Core/" -ForegroundColor $colors.Path
Write-Host "│  │  ├─ Network/" -ForegroundColor $colors.Path
Write-Host "│  │  │  └─ Network.ps1" -ForegroundColor $colors.Function
Write-Host "│  │  ├─ System/" -ForegroundColor $colors.Path
Write-Host "│  │  │  └─ System.ps1" -ForegroundColor $colors.Function
Write-Host "│  │  ├─ Storage/" -ForegroundColor $colors.Path
Write-Host "│  │  │  └─ Storage.ps1" -ForegroundColor $colors.Function
Write-Host "│  │  ├─ Services/" -ForegroundColor $colors.Path
Write-Host "│  │  │  └─ Services.ps1" -ForegroundColor $colors.Function
Write-Host "│  │  └─ Security/" -ForegroundColor $colors.Path
Write-Host "│  │     └─ Security.ps1" -ForegroundColor $colors.Function
Write-Host "│  ├─ Examples.ps1" -ForegroundColor $colors.Function
Write-Host "│  ├─ ConsoleMap.ps1" -ForegroundColor $colors.Function
Write-Host "│  └─ README.md" -ForegroundColor $colors.Function
Write-Host ""

# Network Functions
Write-Host "🌐 NETWORK FUNCTIONS" -ForegroundColor $colors.Category
Write-Host "  Test-NetworkConnectivity      - Test connectivity to target host" -ForegroundColor $colors.Function
Write-Host "  Get-DNSResolution              - Resolve DNS for a hostname" -ForegroundColor $colors.Function
Write-Host "  Get-FirewallStatus             - Check Windows Firewall status" -ForegroundColor $colors.Function
Write-Host ""

# System Functions
Write-Host "🖥️  SYSTEM FUNCTIONS" -ForegroundColor $colors.Category
Write-Host "  Get-SystemInfo                 - Retrieve system information" -ForegroundColor $colors.Function
Write-Host "  Get-EventLogErrors             - Get event log errors" -ForegroundColor $colors.Function
Write-Host "  Get-SystemUptime               - Check system uptime" -ForegroundColor $colors.Function
Write-Host "  Get-PerformanceSnapshot        - Take performance metrics snapshot" -ForegroundColor $colors.Function
Write-Host ""

# Storage Functions
Write-Host "💾 STORAGE FUNCTIONS" -ForegroundColor $colors.Category
Write-Host "  Get-DiskSpaceReport            - Generate disk space report" -ForegroundColor $colors.Function
Write-Host "  Find-LargeFiles                - Find large files in a path" -ForegroundColor $colors.Function
Write-Host "  Clear-TempFiles                - Clear temporary files" -ForegroundColor $colors.Function
Write-Host ""

# Services Functions
Write-Host "⚙️  SERVICES FUNCTIONS" -ForegroundColor $colors.Category
Write-Host "  Get-ServiceStatus              - Check service status" -ForegroundColor $colors.Function
Write-Host "  Get-FailedServices             - List failed services" -ForegroundColor $colors.Function
Write-Host "  Get-ServiceDependencies        - Analyze service dependencies" -ForegroundColor $colors.Function
Write-Host "  Restart-ServiceSafely          - Restart service with dependencies" -ForegroundColor $colors.Function
Write-Host ""

# Security Functions
Write-Host "🔒 SECURITY FUNCTIONS" -ForegroundColor $colors.Category
Write-Host "  Get-UserPermissions            - Check user permissions" -ForegroundColor $colors.Function
Write-Host "  Get-LocalAdminMembers          - List local administrators" -ForegroundColor $colors.Function
Write-Host "  Get-SecurityAuditReport        - Generate security audit" -ForegroundColor $colors.Function
Write-Host "  Test-PasswordPolicy            - Check password policy" -ForegroundColor $colors.Function
Write-Host ""

# Quick Start Guide
Write-Host ("╔" + ("═" * 78) + "╗") -ForegroundColor $colors.Border
Write-Host ("║ QUICK START GUIDE" + (" " * 61) + "║") -ForegroundColor $colors.Border
Write-Host ("╚" + ("═" * 78) + "╝") -ForegroundColor $colors.Border
Write-Host ""

Write-Host "Option 1: Load All Functions" -ForegroundColor $colors.Category
Write-Host "  " + "`$base = 'https://raw.githubusercontent.com/nicotav/powershell/main/Core'" -ForegroundColor $colors.Function
Write-Host "  " + "@('Network/Network', 'System/System', 'Storage/Storage', 'Services/Services', 'Security/Security') | %{ iex (irm `"$`$base/$_.ps1`") }" -ForegroundColor $colors.Function
Write-Host ""

Write-Host "Option 2: Load Specific Module" -ForegroundColor $colors.Category
Write-Host "  " + "iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Network.ps1')" -ForegroundColor $colors.Function
Write-Host ""

Write-Host "Option 3: Run Examples" -ForegroundColor $colors.Category
Write-Host "  " + "iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Examples.ps1')" -ForegroundColor $colors.Function
Write-Host ""

Write-Host "Option 4: Clone Repository" -ForegroundColor $colors.Category
Write-Host "  " + "git clone https://github.com/nicotav/powershell.git" -ForegroundColor $colors.Function
Write-Host ""

# Footer
Write-Host ("╔" + ("═" * 78) + "╗") -ForegroundColor $colors.Border
Write-Host ("║ For more help, run: Get-Help Get-NetworkConnectivity -Full" + (" " * 13) + "║") -ForegroundColor $colors.Border
Write-Host ("║ Repository: https://github.com/nicotav/powershell" + (" " * 27) + "║") -ForegroundColor $colors.Border
Write-Host ("╚" + ("═" * 78) + "╝") -ForegroundColor $colors.Border
Write-Host ""
