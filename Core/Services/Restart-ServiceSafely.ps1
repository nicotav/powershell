#Requires -Version 5.1
<#
.SYNOPSIS
    Restarts a service with proper dependency handling.

.DESCRIPTION
    This standalone snippet safely restarts a Windows service, stopping
    dependent services first if needed.

.PARAMETER ServiceName
    The name of the service to restart. Required.

.PARAMETER Force
    Force restart even if dependent services exist.

.EXAMPLE
    Restart-ServiceSafely -ServiceName "Spooler"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Restart-ServiceSafely.ps1')

    Requires administrator privileges.
#>

function Restart-ServiceSafely {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        Write-Host "Preparing to restart service: $ServiceName..." -ForegroundColor Cyan
        Write-Host ""

        $service = Get-Service -Name $ServiceName -ErrorAction Stop

        # Check for dependent services
        $dependencies = Get-Service -Name $ServiceName -DependentServices
        
        if ($dependencies -and -not $Force) {
            Write-Host "⚠ The following services depend on $ServiceName:" -ForegroundColor Yellow
            foreach ($dep in $dependencies) {
                Write-Host "  • $($dep.DisplayName)" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host "These services will be stopped and restarted. Continue? (Y/N)" -ForegroundColor Yellow
            $response = Read-Host
            if ($response -ne 'Y') {
                Write-Host "Cancelled." -ForegroundColor Gray
                return
            }
        }

        Write-Host "Restarting $($service.DisplayName)..." -ForegroundColor Cyan
        
        if ($PSCmdlet.ShouldProcess($service.Name, "Restart")) {
            Restart-Service -Name $ServiceName -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            $status = (Get-Service -Name $ServiceName).Status
            if ($status -eq 'Running') {
                Write-Host "✓ Service restarted successfully" -ForegroundColor Green
            } else {
                Write-Host "⚠ Service status: $status" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "✗ Error restarting service: $_" -ForegroundColor Red
    }
}

# Interactive mode - show available services (requires admin)
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          SAFE SERVICE RESTART                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Fetching running services..."-ForegroundColor Yellow
$runningServices = Get-Service | Where-Object { $_.Status -eq 'Running' } | Sort-Object DisplayName

Write-Host ""
Write-Host "Select a service to restart (showing first 20):" -ForegroundColor Cyan
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
    Restart-ServiceSafely -ServiceName $serviceName
} else {
    Write-Host "No service name provided. Exiting." -ForegroundColor Yellow
}
