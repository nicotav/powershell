#Requires -Version 5.1
<#
.SYNOPSIS
    Showcase script demonstrating all available troubleshooting functions.

.DESCRIPTION
    This script provides examples of how to use each function from the Core modules.
    Run this script to see all available functions and their usage patterns.

.NOTES
    Author: Your Name
    Date: January 2026
    Version: 1.0.0
#>

#region Module Import
# Import all Core modules
$CorePath = Join-Path -Path $PSScriptRoot -ChildPath "Core"

. "$CorePath\Network\Network.ps1"
. "$CorePath\System\System.ps1"
. "$CorePath\Storage\Storage.ps1"
. "$CorePath\Services\Services.ps1"
. "$CorePath\Security\Security.ps1"

Write-Host "All Core modules loaded successfully!" -ForegroundColor Green
Write-Host ""
#endregion

#region Network Examples
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host "NETWORK TROUBLESHOOTING EXAMPLES" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host ""

# Example 1: Test basic connectivity
Write-Host "Example: Test network connectivity to google.com" -ForegroundColor Magenta
Test-NetworkConnectivity -Target "google.com"
Write-Host ""

# Example 2: Test connectivity with port
Write-Host "Example: Test connectivity to a specific port" -ForegroundColor Magenta
Test-NetworkConnectivity -Target "google.com" -Port 443
Write-Host ""

# Example 3: DNS Resolution
Write-Host "Example: Resolve DNS for a hostname" -ForegroundColor Magenta
Get-DNSResolution -Hostname "microsoft.com"
Write-Host ""

# Example 4: Firewall Status
Write-Host "Example: Check firewall status" -ForegroundColor Magenta
Get-FirewallStatus
Write-Host ""
#endregion

#region System Examples
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host "SYSTEM DIAGNOSTICS EXAMPLES" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host ""

# Example 1: Get system information
Write-Host "Example: Get comprehensive system information" -ForegroundColor Magenta
Get-SystemInfo
Write-Host ""

# Example 2: Get event log errors
Write-Host "Example: Get recent errors from System event log" -ForegroundColor Magenta
Get-EventLogErrors -LogName "System" -Hours 24
Write-Host ""

# Example 3: Get system uptime
Write-Host "Example: Check system uptime" -ForegroundColor Magenta
Get-SystemUptime
Write-Host ""

# Example 4: Performance snapshot
Write-Host "Example: Take a performance snapshot" -ForegroundColor Magenta
Get-PerformanceSnapshot
Write-Host ""
#endregion

#region Storage Examples
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host "STORAGE UTILITY EXAMPLES" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host ""

# Example 1: Disk space report
Write-Host "Example: Generate disk space report" -ForegroundColor Magenta
Get-DiskSpaceReport -ThresholdPercent 20
Write-Host ""

# Example 2: Find large files
Write-Host "Example: Find large files in a directory" -ForegroundColor Magenta
Find-LargeFiles -Path "C:\Windows\Temp" -MinSizeMB 50 -TopN 10
Write-Host ""

# Example 3: Clear temp files (WhatIf mode)
Write-Host "Example: Preview temp file cleanup" -ForegroundColor Magenta
Clear-TempFiles -WhatIf
Write-Host ""
#endregion

#region Services Examples
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host "SERVICES MANAGEMENT EXAMPLES" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host ""

# Example 1: Check service status
Write-Host "Example: Check Print Spooler service status" -ForegroundColor Magenta
Get-ServiceStatus -ServiceName "Spooler"
Write-Host ""

# Example 2: Find failed services
Write-Host "Example: Find services that should be running but aren't" -ForegroundColor Magenta
Get-FailedServices
Write-Host ""

# Example 3: Service dependencies
Write-Host "Example: Get service dependency tree" -ForegroundColor Magenta
Get-ServiceDependencies -ServiceName "Spooler"
Write-Host ""
#endregion

#region Security Examples
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host "SECURITY HELPER EXAMPLES" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host ""

# Example 1: Check user permissions
Write-Host "Example: Check permissions on a folder" -ForegroundColor Magenta
Get-UserPermissions -Path "C:\Windows"
Write-Host ""

# Example 2: List local administrators
Write-Host "Example: List local administrator accounts" -ForegroundColor Magenta
Get-LocalAdminMembers
Write-Host ""

# Example 3: Security audit
Write-Host "Example: Generate security audit report" -ForegroundColor Magenta
Get-SecurityAuditReport
Write-Host ""

# Example 4: Password policy
Write-Host "Example: Check password policy" -ForegroundColor Magenta
Test-PasswordPolicy
Write-Host ""
#endregion

Write-Host "=" * 60 -ForegroundColor Green
Write-Host "All examples completed!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
