#Requires -Version 5.1
<#
.SYNOPSIS
    Generates a basic security audit report for the system.

.DESCRIPTION
    This standalone snippet performs basic security checks including
    firewall status, UAC settings, and Windows Defender status.

.EXAMPLE
    Get-SecurityAuditReport

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Get-SecurityAuditReport.ps1')
#>

function Get-SecurityAuditReport {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Generating security audit report..." -ForegroundColor Cyan
        Write-Host ""

        Write-Host "SECURITY COMPONENTS" -ForegroundColor Yellow
        
        # Firewall Status
        Write-Host ""
        Write-Host "Windows Firewall:" -ForegroundColor Cyan
        $profiles = Get-NetFirewallProfile
        foreach ($fwProfile in $profiles) {
            $status = if ($fwProfile.Enabled) { "✓ ENABLED" } else { "✗ DISABLED" }
            $statusColor = if ($fwProfile.Enabled) { "Green" } else { "Red" }
            Write-Host "  $($fwProfile.Name): $status" -ForegroundColor $statusColor
        }

        # UAC Status
        Write-Host ""
        Write-Host "User Access Control (UAC):" -ForegroundColor Cyan
        try {
            $uacValue = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction Stop
            $uacEnabled = if ($uacValue.EnableLUA -eq 1) { "✓ ENABLED" } else { "✗ DISABLED" }
            $uacColor = if ($uacValue.EnableLUA -eq 1) { "Green" } else { "Red" }
            Write-Host "  Status: $uacEnabled" -ForegroundColor $uacColor
        }
        catch {
            Write-Host "  Status: Unable to determine" -ForegroundColor Yellow
        }

        # Password Policy
        Write-Host ""
        Write-Host "Password Policy:" -ForegroundColor Cyan
        try {
            $passwordPolicy = Get-LocalUser | Where-Object { $_.Enabled } | Measure-Object
            Write-Host "  Active User Accounts: $($passwordPolicy.Count)" -ForegroundColor Green
        }
        catch {
            Write-Host "  Unable to retrieve policy" -ForegroundColor Yellow
        }

        # Antivirus Status
        Write-Host ""
        Write-Host "Windows Defender:" -ForegroundColor Cyan
        try {
            $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
            $defenderEnabled = if ($defenderStatus.AntivirusEnabled) { "✓ ENABLED" } else { "✗ DISABLED" }
            $defenderColor = if ($defenderStatus.AntivirusEnabled) { "Green" } else { "Red" }
            Write-Host "  Antivirus: $defenderEnabled" -ForegroundColor $defenderColor
            Write-Host "  Real-time Protection: $(if ($defenderStatus.RealTimeProtectionEnabled) { '✓ ENABLED' } else { '✗ DISABLED' })" -ForegroundColor $(if ($defenderStatus.RealTimeProtectionEnabled) { 'Green' } else { 'Red' })
        }
        catch {
            Write-Host "  Defender information unavailable" -ForegroundColor Yellow
        }

        Write-Host ""
    }
    catch {
        Write-Host "✗ Error generating security report: $_" -ForegroundColor Red
    }
}

# Execute function
Get-SecurityAuditReport
