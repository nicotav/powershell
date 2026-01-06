#Requires -Version 5.1
<#
.SYNOPSIS
    Gets detailed information about an Azure AD/Entra ID user.

.DESCRIPTION
    This standalone snippet retrieves comprehensive Entra ID user information including
    authentication methods, MFA status, sign-in activity, licenses, and group memberships.

.PARAMETER UserPrincipalName
    The UPN or object ID of the user to query.

.EXAMPLE
    Get-EntraUserInfo -UserPrincipalName "user@contoso.com"
    Get-EntraUserInfo -UserPrincipalName "12345678-1234-1234-1234-123456789012"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Get-EntraUserInfo.ps1')

    Requires: Microsoft.Graph PowerShell module
    Requires: Appropriate Azure AD permissions
#>

function Get-EntraUserInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName
    )

    try {
        # Check if Microsoft Graph module is available
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
            Write-Host "✗ Microsoft.Graph.Users module not found" -ForegroundColor Red
            Write-Host "  Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
            return
        }

        Import-Module Microsoft.Graph.Users -ErrorAction Stop
        Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction SilentlyContinue

        # Check connection
        $context = Get-MgContext
        if (-not $context) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All", "AuditLog.Read.All" -ErrorAction Stop
        }

        Write-Host "Retrieving Entra ID information for: $UserPrincipalName..." -ForegroundColor Cyan
        Write-Host ""

        # Get user object
        $user = Get-MgUser -UserId $UserPrincipalName -Property * -ErrorAction Stop

        # Basic Information
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          USER INFORMATION                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Display Name:      $($user.DisplayName)" -ForegroundColor Green
        Write-Host "User Principal:    $($user.UserPrincipalName)" -ForegroundColor Green
        Write-Host "Mail:              $($user.Mail)" -ForegroundColor Green
        Write-Host "Job Title:         $($user.JobTitle)" -ForegroundColor Gray
        Write-Host "Department:        $($user.Department)" -ForegroundColor Gray
        Write-Host "Office Location:   $($user.OfficeLocation)" -ForegroundColor Gray
        Write-Host "Mobile:            $($user.MobilePhone)" -ForegroundColor Gray
        Write-Host "Object ID:         $($user.Id)" -ForegroundColor DarkGray
        Write-Host ""

        # Account Status
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          ACCOUNT STATUS                                    ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $enabledColor = if ($user.AccountEnabled) { 'Green' } else { 'Red' }
        $enabledStatus = if ($user.AccountEnabled) { "✓ Enabled" } else { "✗ Disabled" }
        Write-Host "Status:            $enabledStatus" -ForegroundColor $enabledColor
        
        Write-Host "Account Type:      $($user.UserType)" -ForegroundColor Gray
        Write-Host "Created:           $($user.CreatedDateTime)" -ForegroundColor Gray
        Write-Host "Last Modified:     $($user.OnPremisesLastSyncDateTime)" -ForegroundColor Gray
        
        if ($user.OnPremisesSyncEnabled) {
            Write-Host "Sync Source:       On-Premises AD (Hybrid)" -ForegroundColor Yellow
            Write-Host "On-Prem SAM:       $($user.OnPremisesSamAccountName)" -ForegroundColor Gray
        } else {
            Write-Host "Sync Source:       Cloud-Only" -ForegroundColor Cyan
        }
        Write-Host ""

        # Authentication Methods
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          AUTHENTICATION METHODS                            ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        try {
            $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue
            if ($authMethods) {
                foreach ($method in $authMethods) {
                    $methodType = $method.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''
                    Write-Host "  • $methodType" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  No authentication methods found" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  Unable to retrieve auth methods (requires UserAuthenticationMethod.Read.All)" -ForegroundColor DarkGray
        }
        Write-Host ""

        # Sign-In Activity
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SIGN-IN ACTIVITY                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        if ($user.SignInActivity) {
            Write-Host "Last Sign-In:      $($user.SignInActivity.LastSignInDateTime)" -ForegroundColor Gray
            Write-Host "Last Interactive:  $($user.SignInActivity.LastNonInteractiveSignInDateTime)" -ForegroundColor Gray
        } else {
            Write-Host "No sign-in activity recorded" -ForegroundColor DarkGray
        }
        Write-Host ""

        # Licenses
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          LICENSES                                          ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        if ($user.AssignedLicenses) {
            Write-Host "Assigned Licenses:" -ForegroundColor Green
            foreach ($license in $user.AssignedLicenses) {
                Write-Host "  • SKU: $($license.SkuId)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "No licenses assigned" -ForegroundColor Gray
        }
        Write-Host ""

        # Group Memberships
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GROUP MEMBERSHIPS                                 ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $groups = Get-MgUserMemberOf -UserId $user.Id
        if ($groups) {
            foreach ($group in $groups) {
                $groupName = $group.AdditionalProperties.displayName
                Write-Host "  • $groupName" -ForegroundColor Yellow
            }
        } else {
            Write-Host "No group memberships" -ForegroundColor Gray
        }
        Write-Host ""

        # Manager
        if ($user.Manager) {
            Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║          MANAGER                                           ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            $manager = Get-MgUserManager -UserId $user.Id
            Write-Host "Manager:           $($manager.AdditionalProperties.displayName)" -ForegroundColor Green
            Write-Host ""
        }

        # Quick Actions Menu
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          QUICK ACTIONS                                     ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Enable/Disable Account" -ForegroundColor Gray
        Write-Host "2. Reset Password" -ForegroundColor Gray
        Write-Host "3. Revoke Sign-In Sessions" -ForegroundColor Gray
        Write-Host "4. Export to JSON" -ForegroundColor Gray
        Write-Host "5. Copy Object ID to Clipboard" -ForegroundColor Gray
        Write-Host "0. Exit" -ForegroundColor Gray
        Write-Host ""
        
        $action = Read-Host "Select action (0-5)"
        
        switch ($action) {
            "1" {
                $newStatus = -not $user.AccountEnabled
                Update-MgUser -UserId $user.Id -AccountEnabled $newStatus
                $statusText = if ($newStatus) { "enabled" } else { "disabled" }
                Write-Host "✓ Account $statusText successfully" -ForegroundColor Green
            }
            "2" {
                Write-Host ""
                $tempPwd = Read-Host "Enter temporary password" -AsSecureString
                $params = @{
                    PasswordProfile = @{
                        Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($tempPwd))
                        ForceChangePasswordNextSignIn = $true
                    }
                }
                Update-MgUser -UserId $user.Id -BodyParameter $params
                Write-Host "✓ Password reset. User must change at next sign-in." -ForegroundColor Green
            }
            "3" {
                Revoke-MgUserSign -UserId $user.Id
                Write-Host "✓ All sign-in sessions revoked" -ForegroundColor Green
            }
            "4" {
                $exportPath = "$env:USERPROFILE\Desktop\EntraUser_$($user.UserPrincipalName -replace '@','_')_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                $user | ConvertTo-Json -Depth 5 | Out-File $exportPath
                Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
            }
            "5" {
                Set-Clipboard -Value $user.Id
                Write-Host "✓ Object ID copied to clipboard" -ForegroundColor Green
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

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          ENTRA ID USER INFO                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if module is available
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Host "✗ Microsoft.Graph module not found" -ForegroundColor Red
    Write-Host "  Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
    exit
}

# Ensure connection
$context = Get-MgContext
if (-not $context) {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    try {
        Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All" -ErrorAction Stop
        Write-Host "✓ Connected successfully" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "✗ Failed to connect: $_" -ForegroundColor Red
        exit
    }
}

Write-Host "Fetching recent users..." -ForegroundColor Yellow
try {
    $recentUsers = Get-MgUser -Top 20 -Property DisplayName,UserPrincipalName,Mail | Sort-Object DisplayName

    Write-Host ""
    Write-Host "Select a user to inspect:" -ForegroundColor Cyan
    $recentUsers | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "  $i. $($_.DisplayName) ($($_.UserPrincipalName))" -ForegroundColor Gray
        $i++
    }
    Write-Host "  0. Enter custom UPN/Object ID..." -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option (0-20)"
    if ($choice -eq "0") {
        $upn = Read-Host "Enter UPN or Object ID"
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 20) {
        $upn = ($recentUsers)[[int]$choice - 1].UserPrincipalName
    } else {
        $upn = $choice
    }

    if ($upn) {
        Write-Host ""
        Get-EntraUserInfo -UserPrincipalName $upn
    } else {
        Write-Host "No user specified. Exiting." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error fetching users: $_" -ForegroundColor Red
    Write-Host ""
    $upn = Read-Host "Enter UPN or Object ID directly"
    if ($upn) {
        Get-EntraUserInfo -UserPrincipalName $upn
    }
}
