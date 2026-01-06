#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Active Directory diagnostic plan.

.DESCRIPTION
    This diagnostic plan runs a series of AD health checks:
    1. Domain controller availability
    2. Replication status
    3. Recent user activity
    4. Recent computer activity
    5. Critical group memberships

.EXAMPLE
    ActiveDirectory-DiagnosticPlan

.NOTES
    This is a standalone diagnostic plan. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/ActiveDirectory-DiagnosticPlan.ps1')

    Requires: Active Directory PowerShell module
    Requires: Domain Controller or RSAT tools
    Requires: Appropriate AD permissions
#>

# Main diagnostic plan
function Invoke-ActiveDirectoryDiagnosticPlan {
    [CmdletBinding()]
    param()

    # Check if AD module is available
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "✗ Active Directory module not found" -ForegroundColor Red
        Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
        return
    }

    Import-Module ActiveDirectory -ErrorAction Stop

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          ACTIVE DIRECTORY DIAGNOSTIC PLAN                  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # STEP 1: Domain Controllers
    Write-Host "STEP 1: Domain Controllers Check" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $dcs = Get-ADDomainController -Filter * | Sort-Object Name
        Write-Host "Found $($dcs.Count) domain controller(s):" -ForegroundColor Green
        foreach ($dc in $dcs) {
            $online = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue
            $status = if ($online) { "✓ Online" } else { "✗ Offline" }
            $color = if ($online) { 'Green' } else { 'Red' }
            Write-Host "  $($dc.Name): $status" -ForegroundColor $color
        }
    }
    catch {
        Write-Host "✗ Error checking domain controllers: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 2: Replication Status
    Write-Host "STEP 2: Replication Status" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $replIssues = 0
        foreach ($dc in $dcs) {
            try {
                $replStatus = Get-ADReplicationPartnerMetadata -Target $dc.Name -ErrorAction Stop
                $failures = $replStatus | Where-Object { $_.LastReplicationResult -ne 0 }
                if ($failures) {
                    $replIssues++
                    Write-Host "  ✗ $($dc.Name): Replication issues detected" -ForegroundColor Red
                } else {
                    Write-Host "  ✓ $($dc.Name): Replication OK" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  ⚠ $($dc.Name): Could not check replication" -ForegroundColor Yellow
            }
        }
        
        if ($replIssues -eq 0) {
            Write-Host "✓ All replication partners healthy" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Error checking replication: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 3: Recent User Logins
    Write-Host "STEP 3: Recent User Activity" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $cutoffDate = (Get-Date).AddDays(-7)
        $recentUsers = Get-ADUser -Filter { LastLogonDate -gt $cutoffDate } -Properties LastLogonDate | 
                       Sort-Object LastLogonDate -Descending | 
                       Select-Object -First 10
        
        Write-Host "Users logged in within last 7 days (top 10):" -ForegroundColor Green
        foreach ($user in $recentUsers) {
            Write-Host "  • $($user.Name) - Last login: $($user.LastLogonDate)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "✗ Error checking user activity: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 4: Disabled Accounts
    Write-Host "STEP 4: Disabled Accounts Check" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $disabledUsers = (Get-ADUser -Filter { Enabled -eq $false }).Count
        $disabledComputers = (Get-ADComputer -Filter { Enabled -eq $false }).Count
        
        Write-Host "Disabled user accounts:     $disabledUsers" -ForegroundColor Gray
        Write-Host "Disabled computer accounts: $disabledComputers" -ForegroundColor Gray
    }
    catch {
        Write-Host "✗ Error checking disabled accounts: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 5: Critical Groups
    Write-Host "STEP 5: Critical Group Memberships" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $criticalGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins")
        
        foreach ($groupName in $criticalGroups) {
            try {
                $members = Get-ADGroupMember -Identity $groupName -ErrorAction Stop
                Write-Host "$groupName ($($members.Count) members):" -ForegroundColor Cyan
                foreach ($member in $members) {
                    Write-Host "  • $($member.Name)" -ForegroundColor Gray
                }
            }
            catch {
                Write-Host "  ⚠ Could not retrieve $groupName" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "✗ Error checking critical groups: $_" -ForegroundColor Red
    }
    Write-Host ""

    # Summary
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DIAGNOSTIC COMPLETE                               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
    Write-Host "  • Monitor disabled accounts for security cleanup" -ForegroundColor Gray
    Write-Host "  • Review critical group memberships regularly" -ForegroundColor Gray
    Write-Host "  • Ensure all DCs are online and replicating" -ForegroundColor Gray
    Write-Host "  • Check for stale computer accounts (>90 days)" -ForegroundColor Gray
    Write-Host ""
}

# Execute diagnostic plan
Write-Host ""
Invoke-ActiveDirectoryDiagnosticPlan
