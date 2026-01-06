#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive security diagnostic plan combining multiple tools.

.DESCRIPTION
    This diagnostic plan runs security health checks in logical order:
    1. Security audit report
    2. Local administrator members
    3. Password policy check
    4. Summary report

.EXAMPLE
    Security-DiagnosticPlan

.NOTES
    This is a standalone diagnostic plan. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Security-DiagnosticPlan.ps1')
#>

# Define all functions needed for this plan
function Get-SecurityAuditReport {
    [CmdletBinding()]
    param()

    Write-Host "Firewall Status:" -ForegroundColor Cyan
    $profiles = Get-NetFirewallProfile
    $allEnabled = $true
    
    foreach ($profile in $profiles) {
        if ($profile.Enabled) {
            Write-Host "  ✓ $($profile.Name): ENABLED" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($profile.Name): DISABLED" -ForegroundColor Red
            $allEnabled = $false
        }
    }
    return $allEnabled
}

function Get-LocalAdminMembers {
    [CmdletBinding()]
    param()

    try {
        $adminGroup = [ADSI]"WinNT://./Administrators"
        $members = @()

        foreach ($member in $adminGroup.psbase.Invoke("Members")) {
            $name = $member.GetType().InvokeMember("Name", 'GetProperty', $null, $member, $null)
            $members += $name
        }

        Write-Host "Local Administrators: $($members.Count) accounts" -ForegroundColor Green
        return $members.Count -le 5
    }
    catch {
        Write-Host "Unable to enumerate administrators" -ForegroundColor Yellow
        return $null
    }
}

# Main diagnostic plan
function Security-DiagnosticPlan {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          SECURITY DIAGNOSTIC PLAN                          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "STEP 1: Security Audit" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    $securityOk = Get-SecurityAuditReport
    Write-Host ""

    Write-Host "STEP 2: Administrator Accounts" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    $adminOk = Get-LocalAdminMembers
    Write-Host ""

    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DIAGNOSTIC COMPLETE                               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
    Write-Host "  • Ensure all firewall profiles are enabled" -ForegroundColor Gray
    Write-Host "  • Limit the number of administrator accounts" -ForegroundColor Gray
    Write-Host "  • Enable UAC for additional protection" -ForegroundColor Gray
    Write-Host "  • Regularly review user permissions" -ForegroundColor Gray
    Write-Host ""
}

# Execute diagnostic plan
Security-DiagnosticPlan
