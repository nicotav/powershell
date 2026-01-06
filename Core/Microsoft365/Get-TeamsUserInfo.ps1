#Requires -Version 5.1
<#
.SYNOPSIS
    Gets detailed Microsoft Teams information for a user.

.DESCRIPTION
    This standalone snippet retrieves Teams presence, chat status, team memberships,
    and calling/meeting configurations for a specific user.

.PARAMETER UserPrincipalName
    The UPN of the user to query.

.EXAMPLE
    Get-TeamsUserInfo -UserPrincipalName "user@contoso.com"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Microsoft365/Get-TeamsUserInfo.ps1')

    Requires: Microsoft.Graph PowerShell module, MicrosoftTeams module
    Requires: Appropriate permissions
#>

function Get-TeamsUserInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName
    )

    try {
        # Check modules
        if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
            Write-Host "✗ MicrosoftTeams module not found" -ForegroundColor Red
            Write-Host "  Install with: Install-Module MicrosoftTeams -Scope CurrentUser" -ForegroundColor Yellow
            return
        }

        Import-Module MicrosoftTeams -ErrorAction Stop
        Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue
        Import-Module Microsoft.Graph.CloudCommunications -ErrorAction SilentlyContinue

        # Check Teams connection
        try {
            $null = Get-CsTenant -ErrorAction Stop
        } catch {
            Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Yellow
            Connect-MicrosoftTeams
        }

        # Check Graph connection
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph -Scopes "User.Read.All", "Presence.Read.All" -ErrorAction Stop
        }

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          TEAMS USER INFORMATION                            ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        # Get user info
        $user = Get-CsOnlineUser -Identity $UserPrincipalName -ErrorAction Stop

        # Basic Information
        Write-Host "Display Name:      $($user.DisplayName)" -ForegroundColor Green
        Write-Host "UPN:               $($user.UserPrincipalName)" -ForegroundColor Green
        Write-Host "SIP Address:       $($user.SipAddress)" -ForegroundColor Cyan
        Write-Host "Hosted Provider:   $($user.HostingProvider)" -ForegroundColor Gray
        Write-Host ""

        # Teams Status
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          TEAMS STATUS                                      ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $enabledColor = if ($user.Enabled) { 'Green' } else { 'Red' }
        Write-Host "Teams Enabled:     $($user.Enabled)" -ForegroundColor $enabledColor
        Write-Host "Enterprise Voice:  $($user.EnterpriseVoiceEnabled)" -ForegroundColor $(if($user.EnterpriseVoiceEnabled){'Green'}else{'Gray'})
        Write-Host "Online Voice:      $($user.OnlineVoiceRoutingPolicy)" -ForegroundColor Gray
        Write-Host ""

        # Presence
        try {
            $presence = Get-MgUserPresence -UserId $UserPrincipalName -ErrorAction SilentlyContinue
            if ($presence) {
                $presenceColor = switch ($presence.Availability) {
                    'Available' { 'Green' }
                    'Busy' { 'Red' }
                    'Away' { 'Yellow' }
                    'BeRightBack' { 'Yellow' }
                    'DoNotDisturb' { 'Red' }
                    default { 'Gray' }
                }
                Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
                Write-Host "║          PRESENCE                                          ║" -ForegroundColor Cyan
                Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Status:            $($presence.Availability)" -ForegroundColor $presenceColor
                Write-Host "Activity:          $($presence.Activity)" -ForegroundColor Gray
                Write-Host ""
            }
        } catch {
            Write-Host "Unable to retrieve presence (requires Presence.Read.All permission)" -ForegroundColor DarkGray
            Write-Host ""
        }

        # Phone System
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          PHONE SYSTEM                                      ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Phone Number:      $($user.LineURI)" -ForegroundColor $(if($user.LineURI){'Green'}else{'Gray'})
        Write-Host "Phone System:      $($user.FeatureTypes -contains 'PhoneSystem')" -ForegroundColor Gray
        Write-Host "Calling Plan:      $($user.FeatureTypes -contains 'CallingPlan')" -ForegroundColor Gray
        Write-Host "Audio Conferencing: $($user.FeatureTypes -contains 'AudioConferencing')" -ForegroundColor Gray
        Write-Host ""

        # Meeting Policies
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          POLICIES                                          ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Teams Policy:      $($user.TeamsUpgradeEffectiveMode)" -ForegroundColor Gray
        Write-Host "Meeting Policy:    $($user.TeamsMeetingPolicy)" -ForegroundColor Gray
        Write-Host "Messaging Policy:  $($user.TeamsMessagingPolicy)" -ForegroundColor Gray
        Write-Host "Calling Policy:    $($user.TeamsCallingPolicy)" -ForegroundColor Gray
        Write-Host "App Setup Policy:  $($user.TeamsAppSetupPolicy)" -ForegroundColor Gray
        Write-Host ""

        # Team Memberships
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          TEAM MEMBERSHIPS                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        try {
            $teams = Get-Team -User $UserPrincipalName -ErrorAction SilentlyContinue
            if ($teams) {
                foreach ($team in $teams) {
                    Write-Host "  • $($team.DisplayName)" -ForegroundColor Yellow
                    Write-Host "    Visibility: $($team.Visibility)" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  No team memberships found" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  Unable to retrieve team memberships" -ForegroundColor DarkGray
        }
        Write-Host ""

        # Quick Actions
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          QUICK ACTIONS                                     ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Enable/Disable Teams" -ForegroundColor Gray
        Write-Host "2. Assign Phone Number" -ForegroundColor Gray
        Write-Host "3. Export to JSON" -ForegroundColor Gray
        Write-Host "0. Exit" -ForegroundColor Gray
        Write-Host ""

        $action = Read-Host "Select action (0-3)"
        
        switch ($action) {
            "1" {
                $newStatus = -not $user.Enabled
                Set-CsUser -Identity $UserPrincipalName -Enabled $newStatus
                $statusText = if ($newStatus) { "enabled" } else { "disabled" }
                Write-Host "✓ Teams $statusText for user" -ForegroundColor Green
            }
            "2" {
                $phoneNumber = Read-Host "Enter phone number (E.164 format: +1234567890)"
                Set-CsUser -Identity $UserPrincipalName -EnterpriseVoiceEnabled $true -HostedVoiceMail $true
                Set-CsPhoneNumberAssignment -Identity $UserPrincipalName -PhoneNumber $phoneNumber -PhoneNumberType DirectRouting
                Write-Host "✓ Phone number assigned" -ForegroundColor Green
            }
            "3" {
                $exportPath = "$env:USERPROFILE\Desktop\TeamsUser_$($UserPrincipalName -replace '@','_')_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                $user | ConvertTo-Json -Depth 5 | Out-File $exportPath
                Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
            }
            default {
                Write-Host "Exiting..." -ForegroundColor Gray
            }
        }

    }
    catch {
        Write-Host "✗ Error retrieving Teams user info: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          TEAMS USER INFO                                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$upn = Read-Host "Enter User Principal Name"
if ($upn) {
    Get-TeamsUserInfo -UserPrincipalName $upn
} else {
    Write-Host "No user specified. Exiting." -ForegroundColor Yellow
}
