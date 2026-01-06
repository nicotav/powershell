#Requires -Version 5.1
<#
.SYNOPSIS
    Gets the dependency tree for a Windows service.

.DESCRIPTION
    This standalone snippet displays all services that depend on a specified
    service, and all services it depends on.

.PARAMETER ServiceName
    The name of the service to analyze. Required.

.EXAMPLE
    Get-ServiceDependencies -ServiceName "Spooler"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Get-ServiceDependencies.ps1')
#>

function Get-ServiceDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )

    try {
        Write-Host "Analyzing dependencies for: $ServiceName..." -ForegroundColor Cyan
        Write-Host ""

        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        
        Write-Host "SERVICE DETAILS" -ForegroundColor Yellow
        Write-Host "  Display Name: $($service.DisplayName)" -ForegroundColor Green
        Write-Host "  Status: $($service.Status)" -ForegroundColor Green
        Write-Host ""

        # Services it depends on
        $dependencies = Get-Service -Name $ServiceName -DependentServices
        if ($dependencies) {
            Write-Host "SERVICES THAT DEPEND ON THIS:" -ForegroundColor Yellow
            foreach ($dep in $dependencies) {
                $statusColor = if ($dep.Status -eq 'Running') { 'Green' } else { 'Red' }
                Write-Host "  • $($dep.DisplayName) ($($dep.Status))" -ForegroundColor $statusColor
            }
        } else {
            Write-Host "SERVICES THAT DEPEND ON THIS:" -ForegroundColor Yellow
            Write-Host "  None" -ForegroundColor Gray
        }
        Write-Host ""

        # Services it depends on
        $serviceObj = Get-Service -Name $ServiceName
        $requiredServices = $serviceObj.RequiredServices
        if ($requiredServices) {
            Write-Host "SERVICES THIS ONE DEPENDS ON:" -ForegroundColor Yellow
            foreach ($req in $requiredServices) {
                $statusColor = if ($req.Status -eq 'Running') { 'Green' } else { 'Red' }
                Write-Host "  • $($req.DisplayName) ($($req.Status))" -ForegroundColor $statusColor
            }
        } else {
            Write-Host "SERVICES THIS ONE DEPENDS ON:" -ForegroundColor Yellow
            Write-Host "  None" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "✗ Error analyzing dependencies: $_" -ForegroundColor Red
    }
}

# Interactive mode - show available services
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          SERVICE DEPENDENCIES ANALYZER                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Fetching running services..." -ForegroundColor Yellow
$runningServices = Get-Service | Where-Object { $_.Status -eq 'Running' } | Sort-Object DisplayName

Write-Host ""
Write-Host "Select a service to analyze (showing first 20):" -ForegroundColor Cyan
$runningServices | Select-Object -First 20 | ForEach-Object -Begin { $i = 1 } -Process {
    Write-Host "  $i. $($_.DisplayName) ($($_.Name))" -ForegroundColor Gray
    $i++
}
Write-Host "  0. Enter custom service name..." -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Select option (0-20)"
if ($choice -eq "0") {
    $serviceName = Read-Host "Enter service name"
} elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 20) {
    $serviceName = ($runningServices | Select-Object -First 20)[[int]$choice - 1].Name
} else {
    $serviceName = $choice
}

if ($serviceName) {
    Write-Host ""
    Get-ServiceDependencies -ServiceName $serviceName
} else {
    Write-Host "No service name provided. Exiting." -ForegroundColor Yellow
}
