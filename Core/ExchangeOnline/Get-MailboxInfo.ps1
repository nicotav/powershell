#Requires -Version 5.1
<#
.SYNOPSIS
    Gets detailed information about an Exchange Online mailbox.

.DESCRIPTION
    This standalone snippet retrieves comprehensive mailbox information including
    size, quotas, permissions, and settings.

.PARAMETER Identity
    The email address or UPN of the mailbox to query.

.EXAMPLE
    Get-MailboxInfo -Identity "user@domain.com"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/Get-MailboxInfo.ps1')

    Requires: ExchangeOnlineManagement module
    Requires: Exchange Online administrator permissions
    Run: Install-Module ExchangeOnlineManagement -Force
#>

function Get-MailboxInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    try {
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

        Write-Host "Retrieving mailbox information for: $Identity..." -ForegroundColor Cyan
        Write-Host ""

        # Get mailbox
        $mailbox = Get-Mailbox -Identity $Identity -ErrorAction Stop
        $stats = Get-MailboxStatistics -Identity $Identity -ErrorAction Stop

        # Basic Information
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          MAILBOX INFORMATION                               ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Display Name:      $($mailbox.DisplayName)" -ForegroundColor Green
        Write-Host "Email Address:     $($mailbox.PrimarySmtpAddress)" -ForegroundColor Green
        Write-Host "Alias:             $($mailbox.Alias)" -ForegroundColor Gray
        Write-Host "User Principal:    $($mailbox.UserPrincipalName)" -ForegroundColor Gray
        Write-Host ""

        # Mailbox Size
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          MAILBOX SIZE & QUOTAS                             ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $sizeGB = [math]::Round($stats.TotalItemSize.Value.ToBytes() / 1GB, 2)
        Write-Host "Total Size:        $sizeGB GB" -ForegroundColor Yellow
        Write-Host "Item Count:        $($stats.ItemCount)" -ForegroundColor Gray
        Write-Host "Deleted Items:     $($stats.DeletedItemCount)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Quota (Warning):   $($mailbox.IssueWarningQuota)" -ForegroundColor Gray
        Write-Host "Quota (Send):      $($mailbox.ProhibitSendQuota)" -ForegroundColor Gray
        Write-Host "Quota (Max):       $($mailbox.ProhibitSendReceiveQuota)" -ForegroundColor Gray
        Write-Host ""

        # Mailbox Features
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          MAILBOX FEATURES                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $archiveStatus = if ($mailbox.ArchiveStatus -eq 'Active') { "✓ Enabled" } else { "✗ Disabled" }
        $archiveColor = if ($mailbox.ArchiveStatus -eq 'Active') { 'Green' } else { 'Yellow' }
        Write-Host "Archive:           $archiveStatus" -ForegroundColor $archiveColor
        
        $litigationStatus = if ($mailbox.LitigationHoldEnabled) { "✓ Enabled" } else { "✗ Disabled" }
        $litigationColor = if ($mailbox.LitigationHoldEnabled) { 'Yellow' } else { 'Gray' }
        Write-Host "Litigation Hold:   $litigationStatus" -ForegroundColor $litigationColor
        
        Write-Host "Hidden from GAL:   $($mailbox.HiddenFromAddressListsEnabled)" -ForegroundColor Gray
        Write-Host ""

        # Email Addresses
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          EMAIL ADDRESSES                                   ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($address in $mailbox.EmailAddresses) {
            if ($address -like "smtp:*") {
                $email = $address -replace "smtp:", ""
                if ($address -like "SMTP:*") {
                    Write-Host "  • $email (Primary)" -ForegroundColor Green
                } else {
                    Write-Host "  • $email" -ForegroundColor Gray
                }
            }
        }
        Write-Host ""

        # Last Access
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          ACTIVITY                                          ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Last Logon:        $($stats.LastLogonTime)" -ForegroundColor Gray
        Write-Host "Last Logoff:       $($stats.LastLogoffTime)" -ForegroundColor Gray
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving mailbox information: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          EXCHANGE ONLINE MAILBOX INFO                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
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
    Write-Host "✓ Connected to Exchange Online" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "✗ Not connected to Exchange Online" -ForegroundColor Red
    Write-Host ""
    $connect = Read-Host "Connect now? (y/n)"
    if ($connect -eq 'y') {
        Connect-ExchangeOnline
        Write-Host ""
    } else {
        Write-Host "Cannot proceed without connection. Exiting." -ForegroundColor Yellow
        exit
    }
}

Write-Host "Fetching recent mailboxes..." -ForegroundColor Yellow
try {
    $mailboxes = Get-Mailbox -ResultSize 20 | Sort-Object DisplayName

    Write-Host ""
    Write-Host "Select a mailbox to inspect (showing first 20):" -ForegroundColor Cyan
    $mailboxes | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "  $i. $($_.DisplayName) ($($_.PrimarySmtpAddress))" -ForegroundColor Gray
        $i++
    }
    Write-Host "  0. Enter custom email address..." -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option (0-20)"
    if ($choice -eq "0") {
        $identity = Read-Host "Enter email address"
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 20) {
        $identity = ($mailboxes)[[int]$choice - 1].PrimarySmtpAddress
    } else {
        $identity = $choice
    }

    if ($identity) {
        Write-Host ""
        Get-MailboxInfo -Identity $identity
    } else {
        Write-Host "No email address provided. Exiting." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error fetching mailboxes: $_" -ForegroundColor Red
    Write-Host ""
    $identity = Read-Host "Enter email address directly"
    if ($identity) {
        Get-MailboxInfo -Identity $identity
    }
}
