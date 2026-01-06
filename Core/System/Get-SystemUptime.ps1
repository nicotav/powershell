#Requires -Version 5.1
<#
.SYNOPSIS
    Gets the system uptime since last boot.

.DESCRIPTION
    This standalone snippet calculates and displays how long the system
    has been running since the last restart.

.EXAMPLE
    Get-SystemUptime

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Get-SystemUptime.ps1')
#>

function Get-SystemUptime {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Calculating system uptime..." -ForegroundColor Cyan
        Write-Host ""

        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $uptime = (Get-Date) - ([datetime]$os.LastBootUpTime)

        Write-Host "Last Boot Time: $($os.LastBootUpTime)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes, $($uptime.Seconds) seconds" -ForegroundColor Green
        Write-Host ""

        if ($uptime.Days -gt 30) {
            Write-Host "⚠ System has not been rebooted in over 30 days" -ForegroundColor Yellow
        } elseif ($uptime.Days -gt 7) {
            Write-Host "ℹ System uptime is moderate" -ForegroundColor Cyan
        } else {
            Write-Host "✓ Recent system restart" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Error calculating uptime: $_" -ForegroundColor Red
    }
}

# Execute function
Get-SystemUptime
