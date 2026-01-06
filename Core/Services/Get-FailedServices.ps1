#Requires -Version 5.1
<#
.SYNOPSIS
    Lists all services that should be running but are stopped.

.DESCRIPTION
    This standalone snippet identifies services configured to start automatically
    but are currently in a stopped state.

.EXAMPLE
    Get-FailedServices

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Get-FailedServices.ps1')
#>

function Get-FailedServices {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Checking for failed services..." -ForegroundColor Cyan
        Write-Host ""

        $failedServices = Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Stopped' }

        if ($failedServices) {
            Write-Host "✗ Found $($failedServices.Count) failed services:" -ForegroundColor Red
            Write-Host ""

            foreach ($service in $failedServices) {
                Write-Host "• $($service.DisplayName)" -ForegroundColor Red
                Write-Host "  Name: $($service.Name)" -ForegroundColor Gray
                Write-Host "  Status: $($service.Status)" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "✓ No failed services detected" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Error checking failed services: $_" -ForegroundColor Red
    }
}

# Execute function
Get-FailedServices
