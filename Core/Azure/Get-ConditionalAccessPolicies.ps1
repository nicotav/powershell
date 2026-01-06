#Requires -Version 5.1
<#
.SYNOPSIS
    Gets and analyzes Azure AD/Entra ID Conditional Access policies.

.DESCRIPTION
    This standalone snippet retrieves all Conditional Access policies and displays
    their conditions, controls, state, and affected users/groups.

.EXAMPLE
    Get-ConditionalAccessPolicies

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Get-ConditionalAccessPolicies.ps1')

    Requires: Microsoft.Graph PowerShell module
    Requires: Policy.Read.All permission
#>

function Get-ConditionalAccessPolicies {
    [CmdletBinding()]
    param()

    try {
        # Check if Microsoft Graph module is available
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
            Write-Host "✗ Microsoft.Graph.Identity.SignIns module not found" -ForegroundColor Red
            Write-Host "  Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
            return
        }

        Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction Stop

        # Check connection
        $context = Get-MgContext
        if (-not $context) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes "Policy.Read.All" -ErrorAction Stop
        }

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          CONDITIONAL ACCESS POLICIES                       ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Retrieving policies..." -ForegroundColor Yellow
        $policies = Get-MgIdentityConditionalAccessPolicy -All

        if (-not $policies) {
            Write-Host "No Conditional Access policies found" -ForegroundColor Yellow
            return
        }

        Write-Host "Found $($policies.Count) policies" -ForegroundColor Green
        Write-Host ""

        foreach ($policy in $policies) {
            $stateColor = switch ($policy.State) {
                'enabled' { 'Green' }
                'enabledForReportingButNotEnforced' { 'Yellow' }
                'disabled' { 'Red' }
                default { 'Gray' }
            }

            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "Policy: $($policy.DisplayName)" -ForegroundColor White
            Write-Host "State:  $($policy.State)" -ForegroundColor $stateColor
            Write-Host "ID:     $($policy.Id)" -ForegroundColor DarkGray
            Write-Host ""

            # Conditions
            Write-Host "CONDITIONS:" -ForegroundColor Yellow
            
            # Users
            if ($policy.Conditions.Users.IncludeUsers) {
                Write-Host "  Include Users:    $($policy.Conditions.Users.IncludeUsers -join ', ')" -ForegroundColor Gray
            }
            if ($policy.Conditions.Users.ExcludeUsers) {
                Write-Host "  Exclude Users:    $($policy.Conditions.Users.ExcludeUsers -join ', ')" -ForegroundColor Gray
            }
            if ($policy.Conditions.Users.IncludeGroups) {
                Write-Host "  Include Groups:   $($policy.Conditions.Users.IncludeGroups -join ', ')" -ForegroundColor Gray
            }
            if ($policy.Conditions.Users.ExcludeGroups) {
                Write-Host "  Exclude Groups:   $($policy.Conditions.Users.ExcludeGroups -join ', ')" -ForegroundColor Gray
            }

            # Applications
            if ($policy.Conditions.Applications.IncludeApplications) {
                Write-Host "  Applications:     $($policy.Conditions.Applications.IncludeApplications -join ', ')" -ForegroundColor Gray
            }

            # Platforms
            if ($policy.Conditions.Platforms.IncludePlatforms) {
                Write-Host "  Platforms:        $($policy.Conditions.Platforms.IncludePlatforms -join ', ')" -ForegroundColor Gray
            }

            # Locations
            if ($policy.Conditions.Locations.IncludeLocations) {
                Write-Host "  Locations:        $($policy.Conditions.Locations.IncludeLocations -join ', ')" -ForegroundColor Gray
            }

            # Client Apps
            if ($policy.Conditions.ClientAppTypes) {
                Write-Host "  Client Apps:      $($policy.Conditions.ClientAppTypes -join ', ')" -ForegroundColor Gray
            }

            Write-Host ""
            Write-Host "ACCESS CONTROLS:" -ForegroundColor Yellow

            # Grant Controls
            if ($policy.GrantControls) {
                Write-Host "  Grant Operator:   $($policy.GrantControls.Operator)" -ForegroundColor Gray
                if ($policy.GrantControls.BuiltInControls) {
                    Write-Host "  Grant Controls:   $($policy.GrantControls.BuiltInControls -join ', ')" -ForegroundColor Gray
                }
            }

            # Session Controls
            if ($policy.SessionControls) {
                if ($policy.SessionControls.SignInFrequency) {
                    Write-Host "  Sign-In Freq:     $($policy.SessionControls.SignInFrequency.Value) $($policy.SessionControls.SignInFrequency.Type)" -ForegroundColor Gray
                }
                if ($policy.SessionControls.PersistentBrowser) {
                    Write-Host "  Persistent Browser: $($policy.SessionControls.PersistentBrowser.Mode)" -ForegroundColor Gray
                }
            }

            Write-Host ""
        }

        # Summary
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        $enabled = ($policies | Where-Object { $_.State -eq 'enabled' }).Count
        $reportOnly = ($policies | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' }).Count
        $disabled = ($policies | Where-Object { $_.State -eq 'disabled' }).Count
        
        Write-Host "  Enabled:          $enabled" -ForegroundColor Green
        Write-Host "  Report-Only:      $reportOnly" -ForegroundColor Yellow
        Write-Host "  Disabled:         $disabled" -ForegroundColor Red
        Write-Host "  Total:            $($policies.Count)" -ForegroundColor White
        Write-Host ""

        # Export option
        $export = Read-Host "Export to JSON? (Y/N)"
        if ($export -eq 'Y' -or $export -eq 'y') {
            $exportPath = "$env:USERPROFILE\Desktop\ConditionalAccessPolicies_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            $policies | ConvertTo-Json -Depth 10 | Out-File $exportPath
            Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
        }

    }
    catch {
        Write-Host "✗ Error retrieving Conditional Access policies: $_" -ForegroundColor Red
    }
}

# Run the function
Get-ConditionalAccessPolicies
