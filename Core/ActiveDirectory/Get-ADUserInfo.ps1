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
        Write-Host "Bad Pwd Count:     $($user.BadLogonCount)" -ForegroundColor $(if ($user.BadLogonCount -gt 0) { 'Red' } else { 'Gray' })
        Write-Host "Last Bad Pwd:      $($user.LastBadPasswordAttempt)" -ForegroundColor Gray
        Write-Host ""

        # Authentication & Logon Details
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          AUTHENTICATION & LOGON                            ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Smart Card Req:    $($user.SmartcardLogonRequired)" -ForegroundColor Gray
        Write-Host "Delegation Trust:  $($user.TrustedForDelegation)" -ForegroundColor Gray
        Write-Host "Acct Expires:      $(if ($user.AccountExpirationDate) { $user.AccountExpirationDate } else { 'Never' })" -ForegroundColor Gray
        Write-Host "Logon Workstations:$(if ($user.LogonWorkstations) { $user.LogonWorkstations } else { ' Any' })" -ForegroundColor Gray
        Write-Host ""

        # Extended Security Info
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SECURITY INFORMATION                              ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Protected:         $($user.ProtectedFromAccidentalDeletion)" -ForegroundColor Gray
        Write-Host "Reversible Pwd:    $($user.AllowReversiblePasswordEncryption)" -ForegroundColor $(if ($user.AllowReversiblePasswordEncryption) { 'Red' } else { 'Gray' })
        Write-Host "Pre-Auth Not Req:  $($user.DoesNotRequirePreAuth)" -ForegroundColor $(if ($user.DoesNotRequirePreAuth) { 'Red' } else { 'Gray' })
        Write-Host "DES Keys Only:     $($user.UseDESKeyOnly)" -ForegroundColor $(if ($user.UseDESKeyOnly) { 'Red' } else { 'Gray' })
        
        if ($user.SIDHistory) {
            Write-Host "SID History:       YES (Migrated account)" -ForegroundColor Yellow
        }
        Write-Host ""

        # Object Metadata
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          OBJECT METADATA                                   ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Distinguished Name:" -ForegroundColor Gray
        Write-Host "  $($user.DistinguishedName)" -ForegroundColor DarkGray
        Write-Host "OU Path:           $($user.CanonicalName)" -ForegroundColor Gray
        Write-Host "Object GUID:       $($user.ObjectGUID)" -ForegroundColor DarkGray
        Write-Host "Object SID:        $($user.SID)" -ForegroundColor DarkGray
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

        # Direct Reports (if manager)
        $directReports = $user.DirectReports
        if ($directReports) {
            Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║          DIRECT REPORTS                                    ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "This user manages $($directReports.Count) employee(s):" -ForegroundColor Green
            foreach ($report in $directReports) {
                $reportUser = Get-ADUser -Identity $report -Properties DisplayName
                Write-Host "  • $($reportUser.DisplayName) ($($reportUser.SamAccountName))" -ForegroundColor Yellow
            }
            Write-Host ""
        }

        # Quick Actions Menu
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          QUICK ACTIONS                                     ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Unlock Account" -ForegroundColor Gray
        Write-Host "2. Reset Password" -ForegroundColor Gray
        Write-Host "3. Enable/Disable Account" -ForegroundColor Gray
        Write-Host "4. Add to Group" -ForegroundColor Gray
        Write-Host "5. Export to JSON" -ForegroundColor Gray
        Write-Host "6. Copy DN to Clipboard" -ForegroundColor Gray
        Write-Host "0. Exit" -ForegroundColor Gray
        Write-Host ""
        
        $action = Read-Host "Select action (0-6)"
        
        switch ($action) {
            "1" {
                if ($user.LockedOut) {
                    Unlock-ADAccount -Identity $Username
                    Write-Host "✓ Account unlocked successfully" -ForegroundColor Green
                } else {
                    Write-Host "Account is not locked" -ForegroundColor Yellow
                }
            }
            "2" {
                Write-Host ""
                $newPwd = Read-Host "Enter new password" -AsSecureString
                Set-ADAccountPassword -Identity $Username -NewPassword $newPwd -Reset
                Set-ADUser -Identity $Username -ChangePasswordAtLogon $true
                Write-Host "✓ Password reset. User must change at next logon." -ForegroundColor Green
            }
            "3" {
                if ($user.Enabled) {
                    Disable-ADAccount -Identity $Username
                    Write-Host "✓ Account disabled" -ForegroundColor Green
                } else {
                    Enable-ADAccount -Identity $Username
                    Write-Host "✓ Account enabled" -ForegroundColor Green
                }
            }
            "4" {
                Write-Host ""
                $groupName = Read-Host "Enter group name"
                Add-ADGroupMember -Identity $groupName -Members $Username
                Write-Host "✓ Added to group: $groupName" -ForegroundColor Green
            }
            "5" {
                $exportPath = "$env:USERPROFILE\Desktop\ADUser_$($user.SamAccountName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                $user | ConvertTo-Json -Depth 3 | Out-File $exportPath
                Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
            }
            "6" {
                Set-Clipboard -Value $user.DistinguishedName
                Write-Host "✓ Distinguished Name copied to clipboard" -ForegroundColor Green
            }
            "0" {
                Write-Host "Exiting..." -ForegroundColor Gray
            }
            default {
                Write-Host "No action taken" -ForegroundColor Yellow
            }
        }

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
