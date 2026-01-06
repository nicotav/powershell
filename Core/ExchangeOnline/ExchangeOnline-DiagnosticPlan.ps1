#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Exchange Online diagnostic plan.

.DESCRIPTION
    This diagnostic plan runs a series of Exchange Online health checks:
    1. Connection status
    2. Organization configuration
    3. Recent mailbox activity
    4. Distribution groups summary
    5. Mail flow rules summary

.EXAMPLE
    ExchangeOnline-DiagnosticPlan

.NOTES
    This is a standalone diagnostic plan. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/ExchangeOnline-DiagnosticPlan.ps1')

    Requires: ExchangeOnlineManagement module
    Requires: Exchange Online administrator permissions
#>

# Main diagnostic plan
function Invoke-ExchangeOnlineDiagnosticPlan {
    [CmdletBinding()]
    param()

    # Check if module is available
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Host "✗ ExchangeOnlineManagement module not found" -ForegroundColor Red
        Write-Host "  Run: Install-Module ExchangeOnlineManagement -Force" -ForegroundColor Yellow
        return
    }

    # Check if connected
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
    }
    catch {
        Write-Host "✗ Not connected to Exchange Online" -ForegroundColor Red
        Write-Host "  Run: Connect-ExchangeOnline" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          EXCHANGE ONLINE DIAGNOSTIC PLAN                   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # STEP 1: Organization Configuration
    Write-Host "STEP 1: Organization Configuration" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $org = Get-OrganizationConfig
        Write-Host "Organization Name:     $($org.DisplayName)" -ForegroundColor Green
        Write-Host "Default Domain:        $($org.DefaultDomain)" -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host "✗ Error checking organization: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 2: Mailbox Statistics
    Write-Host "STEP 2: Mailbox Summary" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $mailboxes = Get-Mailbox -ResultSize 1000
        $totalMailboxes = $mailboxes.Count
        $sharedMailboxes = ($mailboxes | Where-Object { $_.RecipientTypeDetails -eq 'SharedMailbox' }).Count
        $roomMailboxes = ($mailboxes | Where-Object { $_.RecipientTypeDetails -eq 'RoomMailbox' }).Count
        
        Write-Host "Total Mailboxes:       $totalMailboxes" -ForegroundColor Green
        Write-Host "  User Mailboxes:      $($totalMailboxes - $sharedMailboxes - $roomMailboxes)" -ForegroundColor Gray
        Write-Host "  Shared Mailboxes:    $sharedMailboxes" -ForegroundColor Gray
        Write-Host "  Room Mailboxes:      $roomMailboxes" -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host "✗ Error checking mailboxes: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 3: Recent Activity
    Write-Host "STEP 3: Recent Mailbox Activity" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $recentActivity = Get-Mailbox -ResultSize 10 | ForEach-Object {
            $stats = Get-MailboxStatistics -Identity $_.PrimarySmtpAddress -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                DisplayName = $_.DisplayName
                Email = $_.PrimarySmtpAddress
                LastLogon = $stats.LastLogonTime
            }
        } | Sort-Object LastLogon -Descending | Select-Object -First 5
        
        Write-Host "Last 5 mailbox logins:" -ForegroundColor Green
        foreach ($item in $recentActivity) {
            Write-Host "  • $($item.DisplayName) - $($item.LastLogon)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "✗ Error checking activity: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 4: Distribution Groups
    Write-Host "STEP 4: Distribution Groups" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $groups = Get-DistributionGroup -ResultSize 100
        Write-Host "Total Groups:          $($groups.Count)" -ForegroundColor Green
        
        if ($groups.Count -gt 0) {
            Write-Host "Sample groups:" -ForegroundColor Gray
            $groups | Select-Object -First 5 | ForEach-Object {
                Write-Host "  • $($_.DisplayName) ($($_.PrimarySmtpAddress))" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "✗ Error checking groups: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 5: Mail Flow Rules
    Write-Host "STEP 5: Mail Flow Rules" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $rules = Get-TransportRule
        $enabledRules = ($rules | Where-Object { $_.State -eq 'Enabled' }).Count
        
        Write-Host "Total Rules:           $($rules.Count)" -ForegroundColor Green
        Write-Host "  Enabled:             $enabledRules" -ForegroundColor Gray
        Write-Host "  Disabled:            $($rules.Count - $enabledRules)" -ForegroundColor Gray
        
        if ($rules.Count -gt 0) {
            Write-Host ""
            Write-Host "Active rules:" -ForegroundColor Gray
            $rules | Where-Object { $_.State -eq 'Enabled' } | Select-Object -First 5 | ForEach-Object {
                Write-Host "  • $($_.Name)" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "✗ Error checking mail flow rules: $_" -ForegroundColor Red
    }
    Write-Host ""

    # STEP 6: Accepted Domains
    Write-Host "STEP 6: Accepted Domains" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    try {
        $domains = Get-AcceptedDomain
        Write-Host "Configured domains:" -ForegroundColor Green
        foreach ($domain in $domains) {
            $typeColor = if ($domain.Default) { 'Green' } else { 'Gray' }
            $defaultMarker = if ($domain.Default) { " (Default)" } else { "" }
            Write-Host "  • $($domain.DomainName)$defaultMarker" -ForegroundColor $typeColor
        }
    }
    catch {
        Write-Host "✗ Error checking domains: $_" -ForegroundColor Red
    }
    Write-Host ""

    # Summary
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DIAGNOSTIC COMPLETE                               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
    Write-Host "  • Review mail flow rules for redundancy" -ForegroundColor Gray
    Write-Host "  • Check mailbox quotas for approaching limits" -ForegroundColor Gray
    Write-Host "  • Audit distribution group memberships" -ForegroundColor Gray
    Write-Host "  • Monitor shared mailbox permissions" -ForegroundColor Gray
    Write-Host ""
}

# Execute diagnostic plan
Write-Host ""

# Check if module is available
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "✗ ExchangeOnlineManagement module not found" -ForegroundColor Red
    Write-Host "  Run: Install-Module ExchangeOnlineManagement -Force" -ForegroundColor Yellow
    exit
}

# Check if connected
try {
    $null = Get-OrganizationConfig -ErrorAction Stop
}
catch {
    Write-Host "✗ Not connected to Exchange Online" -ForegroundColor Red
    Write-Host ""
    $connect = Read-Host "Connect now? (y/n)"
    if ($connect -eq 'y') {
        Connect-ExchangeOnline
    } else {
        Write-Host "Cannot proceed without connection. Exiting." -ForegroundColor Yellow
        exit
    }
}

Invoke-ExchangeOnlineDiagnosticPlan
