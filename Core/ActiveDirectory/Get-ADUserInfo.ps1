#Requires -Version 5.1
<#
.SYNOPSIS
    Gets detailed information about an Active Directory user.

.DESCRIPTION
    This standalone snippet retrieves comprehensive AD user information including
    account status, group memberships, last logon, and password details.

.PARAMETER Username
    The SAM account name or UPN of the user to query.

.EXAMPLE
    Get-ADUserInfo -Username "jsmith"
    Get-ADUserInfo -Username "john.smith@domain.com"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/Get-ADUserInfo.ps1')

    Requires: Active Directory PowerShell module
    Requires: Appropriate AD permissions
#>

function Get-ADUserInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username
    )

    try {
        # Check if AD module is available
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Host "✗ Active Directory module not found" -ForegroundColor Red
            Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
            return
        }

        Import-Module ActiveDirectory -ErrorAction Stop

        Write-Host "Retrieving AD information for: $Username..." -ForegroundColor Cyan
        Write-Host ""

        # Get user object
        $user = Get-ADUser -Identity $Username -Properties * -ErrorAction Stop

        # Basic Information
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          USER INFORMATION                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Display Name:      $($user.DisplayName)" -ForegroundColor Green
        Write-Host "Email:             $($user.EmailAddress)" -ForegroundColor Green
        Write-Host "SAM Account:       $($user.SamAccountName)" -ForegroundColor Green
        Write-Host "UPN:               $($user.UserPrincipalName)" -ForegroundColor Green
        Write-Host "Title:             $($user.Title)" -ForegroundColor Gray
        Write-Host "Department:        $($user.Department)" -ForegroundColor Gray
        Write-Host "Manager:           $($user.Manager)" -ForegroundColor Gray
        Write-Host ""

        # Account Status
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          ACCOUNT STATUS                                    ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $enabledColor = if ($user.Enabled) { 'Green' } else { 'Red' }
        $enabledStatus = if ($user.Enabled) { "✓ Enabled" } else { "✗ Disabled" }
        Write-Host "Status:            $enabledStatus" -ForegroundColor $enabledColor
        
        $lockedColor = if ($user.LockedOut) { 'Red' } else { 'Green' }
        $lockedStatus = if ($user.LockedOut) { "✗ Locked Out" } else { "✓ Not Locked" }
        Write-Host "Lock Status:       $lockedStatus" -ForegroundColor $lockedColor
        
        Write-Host "Created:           $($user.Created)" -ForegroundColor Gray
        Write-Host "Modified:          $($user.Modified)" -ForegroundColor Gray
        Write-Host "Last Logon:        $($user.LastLogonDate)" -ForegroundColor Gray
        Write-Host ""

        # Password Information
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          PASSWORD INFORMATION                              ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Last Password Set: $($user.PasswordLastSet)" -ForegroundColor Gray
        Write-Host "Expires:           $($user.PasswordExpired)" -ForegroundColor Gray
        Write-Host "Never Expires:     $($user.PasswordNeverExpires)" -ForegroundColor Gray
        Write-Host "Cannot Change:     $($user.CannotChangePassword)" -ForegroundColor Gray
        Write-Host ""

        # Group Memberships
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GROUP MEMBERSHIPS                                 ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $groups = Get-ADPrincipalGroupMembership -Identity $Username | Sort-Object Name
        foreach ($group in $groups) {
            Write-Host "  • $($group.Name)" -ForegroundColor Yellow
        }
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving user information: $_" -ForegroundColor Red
    }
}

# Interactive mode - show available users
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          ACTIVE DIRECTORY USER INFO                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if AD module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "✗ Active Directory module not found" -ForegroundColor Red
    Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
    exit
}

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

Write-Host "Fetching recent AD users..." -ForegroundColor Yellow
try {
    $recentUsers = Get-ADUser -Filter * -Properties LastLogonDate | 
                   Where-Object { $_.LastLogonDate } | 
                   Sort-Object LastLogonDate -Descending | 
                   Select-Object -First 20

    Write-Host ""
    Write-Host "Select a user to inspect (showing 20 most recently logged on):" -ForegroundColor Cyan
    $recentUsers | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "  $i. $($_.Name) ($($_.SamAccountName))" -ForegroundColor Gray
        $i++
    }
    Write-Host "  0. Enter custom username..." -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option (0-20)"
    if ($choice -eq "0") {
        $username = Read-Host "Enter username (SAM or UPN)"
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 20) {
        $username = ($recentUsers)[[int]$choice - 1].SamAccountName
    } else {
        $username = $choice
    }

    if ($username) {
        Write-Host ""
        Get-ADUserInfo -Username $username
    } else {
        Write-Host "No username provided. Exiting." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error fetching users: $_" -ForegroundColor Red
    Write-Host ""
    $username = Read-Host "Enter username directly"
    if ($username) {
        Get-ADUserInfo -Username $username
    }
}
