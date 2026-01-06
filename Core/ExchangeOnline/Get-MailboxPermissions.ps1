#Requires -Version 5.1
<#
.SYNOPSIS
    Gets permissions assigned to an Exchange Online mailbox.

.DESCRIPTION
    This standalone snippet displays Full Access, Send As, and Send on Behalf
    permissions for a mailbox.

.PARAMETER Identity
    The email address of the mailbox to check.

.EXAMPLE
    Get-MailboxPermissions -Identity "user@domain.com"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/Get-MailboxPermissions.ps1')

    Requires: ExchangeOnlineManagement module
    Requires: Exchange Online administrator permissions
#>

function Get-MailboxPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    try {
        # Check if connected
        try {
            $null = Get-OrganizationConfig -ErrorAction Stop
        }
        catch {
            Write-Host "✗ Not connected to Exchange Online" -ForegroundColor Red
            Write-Host "  Run: Connect-ExchangeOnline" -ForegroundColor Yellow
            return
        }

        Write-Host "Retrieving permissions for: $Identity..." -ForegroundColor Cyan
        Write-Host ""

        # Get mailbox
        $mailbox = Get-Mailbox -Identity $Identity -ErrorAction Stop

        # Full Access Permissions
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          FULL ACCESS PERMISSIONS                           ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $fullAccess = Get-MailboxPermission -Identity $Identity | 
                      Where-Object { $_.AccessRights -contains "FullAccess" -and $_.IsInherited -eq $false -and $_.User -notlike "NT AUTHORITY\*" }
        
        if ($fullAccess) {
            foreach ($perm in $fullAccess) {
                Write-Host "  • $($perm.User)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  No explicit Full Access permissions" -ForegroundColor Gray
        }
        Write-Host ""

        # Send As Permissions
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SEND AS PERMISSIONS                               ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $sendAs = Get-RecipientPermission -Identity $Identity | 
                  Where-Object { $_.AccessRights -contains "SendAs" -and $_.Trustee -ne "NT AUTHORITY\SELF" }
        
        if ($sendAs) {
            foreach ($perm in $sendAs) {
                Write-Host "  • $($perm.Trustee)" -ForegroundColor Magenta
            }
        } else {
            Write-Host "  No Send As permissions" -ForegroundColor Gray
        }
        Write-Host ""

        # Send on Behalf Permissions
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SEND ON BEHALF PERMISSIONS                        ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        if ($mailbox.GrantSendOnBehalfTo) {
            foreach ($user in $mailbox.GrantSendOnBehalfTo) {
                Write-Host "  • $user" -ForegroundColor Cyan
            }
        } else {
            Write-Host "  No Send on Behalf permissions" -ForegroundColor Gray
        }
        Write-Host ""

        # Folder Permissions (Calendar)
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          CALENDAR PERMISSIONS                              ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        try {
            $calendarPath = "$($Identity):\Calendar"
            $calPerms = Get-MailboxFolderPermission -Identity $calendarPath -ErrorAction Stop | 
                        Where-Object { $_.User -ne "Default" -and $_.User -ne "Anonymous" }
            
            if ($calPerms) {
                foreach ($perm in $calPerms) {
                    Write-Host "  • $($perm.User): $($perm.AccessRights)" -ForegroundColor Green
                }
            } else {
                Write-Host "  No custom calendar permissions" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "  Could not retrieve calendar permissions" -ForegroundColor Yellow
        }
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving permissions: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          EXCHANGE ONLINE MAILBOX PERMISSIONS               ║" -ForegroundColor Cyan
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
        exit
    }
}

Write-Host "Fetching mailboxes..." -ForegroundColor Yellow
try {
    $mailboxes = Get-Mailbox -ResultSize 20 | Sort-Object DisplayName

    Write-Host ""
    Write-Host "Select a mailbox to check permissions (showing first 20):" -ForegroundColor Cyan
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
        Get-MailboxPermissions -Identity $identity
    } else {
        Write-Host "No email address provided. Exiting." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
}
