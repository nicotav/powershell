#Requires -Version 5.1
<#
.SYNOPSIS
    Gets detailed status information for a Windows service.

.DESCRIPTION
    This standalone snippet retrieves and displays detailed status information
    for a specified Windows service.

.PARAMETER ServiceName
    The name of the service to check. Required.

.EXAMPLE
    Get-ServiceStatus -ServiceName "Spooler"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Get-ServiceStatus.ps1')
#>

function Get-ServiceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )

    try {
        Write-Host "Checking status of service: $ServiceName..." -ForegroundColor Cyan
        Write-Host ""

        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        $status = $service.Status

        $statusColor = switch ($status) {
            'Running' { 'Green' }
            'Stopped' { 'Red' }
            default { 'Yellow' }
        }

        Write-Host "Service Name: $($service.DisplayName)" -ForegroundColor Magenta
        Write-Host "Status: $status" -ForegroundColor $statusColor
        Write-Host "Startup Type: $($service.StartType)" -ForegroundColor Green
        Write-Host "Service Name (Key): $($service.Name)" -ForegroundColor Gray
        Write-Host ""

        if ($status -eq 'Running') {
            Write-Host "✓ Service is running" -ForegroundColor Green
        } else {
            Write-Host "✗ Service is not running" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Error checking service: $_" -ForegroundColor Red
    }
}

# Interactive mode - show available services
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          SERVICE STATUS CHECKER                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Fetching services..." -ForegroundColor Yellow
$allServices = Get-Service | Sort-Object DisplayName

Write-Host ""
Write-Host "Select a service to check (showing first 20):" -ForegroundColor Cyan
$allServices | Select-Object -First 20 | ForEach-Object -Begin { $i = 1 } -Process {
    $statusColor = if ($_.Status -eq 'Running') { 'Green' } else { 'Yellow' }
    Write-Host "  $i. $($_.DisplayName) - $($_.Status)" -ForegroundColor $statusColor
    $i++
}
Write-Host "  0. Enter custom service name..." -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Select option (0-20)"
if ($choice -eq "0") {
    $serviceName = Read-Host "Enter service name"
} elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 20) {
    $serviceName = ($allServices | Select-Object -First 20)[[int]$choice - 1].Name
} else {
    $serviceName = $choice
}

if ($serviceName) {
    Write-Host ""
    Get-ServiceStatus -ServiceName $serviceName
} else {
    Write-Host "No service name provided. Exiting." -ForegroundColor Yellow
}
