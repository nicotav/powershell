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

# Get service name from user
$serviceName = Read-Host "Enter service name to restart"
if ($serviceName) {
    Restart-ServiceSafely -ServiceName $serviceName
}
