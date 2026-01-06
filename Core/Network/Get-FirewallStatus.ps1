#Requires -Version 5.1
<#
.SYNOPSIS
    Gets the current Windows Firewall status and profiles.

.DESCRIPTION
    This standalone snippet displays the status of Windows Firewall
    for all profiles (Domain, Private, Public).

.EXAMPLE
    Get-FirewallStatus

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Get-FirewallStatus.ps1')
#>

function Get-FirewallStatus {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Checking Windows Firewall status..." -ForegroundColor Cyan
        Write-Host ""

        $profiles = Get-NetFirewallProfile

        foreach ($fwProfile in $profiles) {
            $status = if ($fwProfile.Enabled) { "✓ ENABLED" } else { "✗ DISABLED" }
            $statusColor = if ($fwProfile.Enabled) { "Green" } else { "Yellow" }

            Write-Host "$($fwProfile.Name) Profile: $status" -ForegroundColor $statusColor
            Write-Host "  Default Inbound Action: $($fwProfile.DefaultInboundAction)" -ForegroundColor Gray
            Write-Host "  Default Outbound Action: $($fwProfile.DefaultOutboundAction)" -ForegroundColor Gray
            Write-Host ""
        }

        Write-Host "Firewall enabled rules:" -ForegroundColor Cyan
        $enabledRules = @(Get-NetFirewallRule -Enabled $true | Measure-Object).Count
        Write-Host "  $enabledRules rules active" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error checking firewall status: $_" -ForegroundColor Red
    }
}

# Execute function
Get-FirewallStatus
