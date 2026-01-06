#Requires -Version 5.1
<#
.SYNOPSIS
    Gets members of an Exchange Online distribution group.

.DESCRIPTION
    This standalone snippet displays all members of a distribution group
    or mail-enabled security group.

.PARAMETER GroupName
    The email address or name of the distribution group.

.EXAMPLE
    Get-DistributionGroupMembers -GroupName "team@domain.com"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/Get-DistributionGroupMembers.ps1')

    Requires: ExchangeOnlineManagement module
    Requires: Exchange Online administrator permissions
#>

function Get-DistributionGroupMembers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupName
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

        Write-Host "Retrieving distribution group: $GroupName..." -ForegroundColor Cyan
        Write-Host ""

        # Get group
        $group = Get-DistributionGroup -Identity $GroupName -ErrorAction Stop

        # Group Information
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GROUP INFORMATION                                 ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Display Name:      $($group.DisplayName)" -ForegroundColor Green
        Write-Host "Email Address:     $($group.PrimarySmtpAddress)" -ForegroundColor Green
        Write-Host "Group Type:        $($group.RecipientTypeDetails)" -ForegroundColor Gray
        Write-Host "Hidden from GAL:   $($group.HiddenFromAddressListsEnabled)" -ForegroundColor Gray
        Write-Host ""

        # Get members
        $members = Get-DistributionGroupMember -Identity $GroupName -ResultSize Unlimited | Sort-Object DisplayName

        # Display members
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GROUP MEMBERS ($($members.Count))                              " -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        if ($members) {
            $users = @()
            $groups = @()
            $contacts = @()

            foreach ($member in $members) {
                switch -Wildcard ($member.RecipientTypeDetails) {
                    "*Mailbox" { $users += $member }
                    "*Group" { $groups += $member }
                    "*Contact" { $contacts += $member }
                    default { $users += $member }
                }
            }

            if ($users) {
                Write-Host "USERS ($($users.Count)):" -ForegroundColor Yellow
                foreach ($user in $users) {
                    Write-Host "  • $($user.DisplayName) ($($user.PrimarySmtpAddress))" -ForegroundColor Green
                }
                Write-Host ""
            }

            if ($groups) {
                Write-Host "NESTED GROUPS ($($groups.Count)):" -ForegroundColor Yellow
                foreach ($grp in $groups) {
                    Write-Host "  • $($grp.DisplayName) ($($grp.PrimarySmtpAddress))" -ForegroundColor Cyan
                }
                Write-Host ""
            }

            if ($contacts) {
                Write-Host "EXTERNAL CONTACTS ($($contacts.Count)):" -ForegroundColor Yellow
                foreach ($contact in $contacts) {
                    Write-Host "  • $($contact.DisplayName) ($($contact.PrimarySmtpAddress))" -ForegroundColor Magenta
                }
                Write-Host ""
            }
        } else {
            Write-Host "No members found in this group." -ForegroundColor Gray
            Write-Host ""
        }

        # Management
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GROUP MANAGEMENT                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Managed By:" -ForegroundColor Yellow
        if ($group.ManagedBy) {
            foreach ($manager in $group.ManagedBy) {
                Write-Host "  • $manager" -ForegroundColor Gray
            }
        } else {
            Write-Host "  No managers defined" -ForegroundColor Gray
        }
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving distribution group: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          DISTRIBUTION GROUP MEMBERS                        ║" -ForegroundColor Cyan
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

Write-Host "Fetching distribution groups..." -ForegroundColor Yellow
try {
    $groups = Get-DistributionGroup -ResultSize 30 | Sort-Object DisplayName

    Write-Host ""
    Write-Host "Select a distribution group (showing first 30):" -ForegroundColor Cyan
    $groups | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "  $i. $($_.DisplayName) ($($_.PrimarySmtpAddress))" -ForegroundColor Gray
        $i++
    }
    Write-Host "  0. Enter custom group email..." -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option (0-30)"
    if ($choice -eq "0") {
        $groupName = Read-Host "Enter group email address or name"
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 30) {
        $groupName = ($groups)[[int]$choice - 1].PrimarySmtpAddress
    } else {
        $groupName = $choice
    }

    if ($groupName) {
        Write-Host ""
        Get-DistributionGroupMembers -GroupName $groupName
    } else {
        Write-Host "No group name provided. Exiting." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
}
