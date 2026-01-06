#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive services diagnostic plan combining multiple tools.

.DESCRIPTION
    This diagnostic plan runs service health checks in logical order:
    1. Failed services detection
    2. Critical services status
    3. Summary report

.EXAMPLE
    Invoke-ServicesDiagnosticPlan

.NOTES
    This is a standalone diagnostic plan. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Services-DiagnosticPlan.ps1')
#>

# Define all functions needed for this plan
function Get-FailedServices {
    [CmdletBinding()]
    param()

    $failedServices = Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Stopped' }
    
    if ($failedServices) {
        Write-Host "✗ Failed Services: $($failedServices.Count)" -ForegroundColor Red
        foreach ($service in $failedServices | Select-Object -First 5) {
            Write-Host "  • $($service.DisplayName)" -ForegroundColor Red
        }
        return $false
    } else {
        Write-Host "✓ No failed services" -ForegroundColor Green
        return $true
    }
}

function Get-CriticalServices {
    [CmdletBinding()]
    param()

    $criticalServices = @('spooler', 'Winlogon', 'Windows Update')
    
    Write-Host "Critical Service Status:" -ForegroundColor Green
    foreach ($serviceName in $criticalServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $statusColor = if ($service.Status -eq 'Running') { 'Green' } else { 'Red' }
            Write-Host "  $($service.DisplayName): $($service.Status)" -ForegroundColor $statusColor
        }
    }
}

# Main diagnostic plan
function Invoke-ServicesDiagnosticPlan {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          SERVICES DIAGNOSTIC PLAN                          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "STEP 1: Failed Services Check" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    Get-FailedServices
    Write-Host ""

    Write-Host "STEP 2: Critical Services Status" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    Get-CriticalServices
    Write-Host ""

    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DIAGNOSTIC COMPLETE                               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Execute diagnostic plan
Invoke-ServicesDiagnosticPlan
