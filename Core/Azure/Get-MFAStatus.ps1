#Requires -Version 5.1
<#
.SYNOPSIS
    Gets MFA registration status for all users in Entra ID.

.DESCRIPTION
    This standalone snippet retrieves MFA registration status, authentication methods,
    and enforcement state for all users or specific users.

.PARAMETER UserPrincipalName
    Optional. Specific user to check. If not provided, checks all users.

.EXAMPLE
    Get-MFAStatus
    Get-MFAStatus -UserPrincipalName "user@contoso.com"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Get-MFAStatus.ps1')

    Requires: Microsoft.Graph PowerShell module
    Requires: UserAuthenticationMethod.Read.All permission
#>

function Get-MFAStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
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
        Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction Stop

        # Check connection
        $context = Get-MgContext
        if (-not $context) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All", "User.Read.All" -ErrorAction Stop
        }

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          MFA STATUS REPORT                                 ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        # Get users
        if ($UserPrincipalName) {
            $users = @(Get-MgUser -UserId $UserPrincipalName -Property DisplayName,UserPrincipalName,Id,AccountEnabled)
        } else {
            Write-Host "Retrieving all users..." -ForegroundColor Yellow
            $users = Get-MgUser -All -Property DisplayName,UserPrincipalName,Id,AccountEnabled
        }

        Write-Host "Analyzing MFA status for $($users.Count) user(s)..." -ForegroundColor Yellow
        Write-Host ""

        $results = @()
        $i = 0

        foreach ($user in $users) {
            $i++
            Write-Progress -Activity "Checking MFA Status" -Status "$i of $($users.Count)" -PercentComplete (($i / $users.Count) * 100)

            try {
                $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue
                
                $hasMFA = $false
                $methods = @()
                
                if ($authMethods) {
                    foreach ($method in $authMethods) {
                        $methodType = $method.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''
                        $methods += $methodType
                        
                        # Consider these as MFA methods
                        if ($methodType -in @('phoneAuthenticationMethod', 'microsoftAuthenticatorAuthenticationMethod', 
                                               'softwareOathAuthenticationMethod', 'fido2AuthenticationMethod')) {
                            $hasMFA = $true
                        }
                    }
                }

                $status = if ($hasMFA) { "✓ Enabled" } else { "✗ Not Configured" }
                $statusColor = if ($hasMFA) { "Green" } else { "Red" }

                Write-Host "User: $($user.DisplayName)" -ForegroundColor White
                Write-Host "  UPN:     $($user.UserPrincipalName)" -ForegroundColor Gray
                Write-Host "  Status:  $status" -ForegroundColor $statusColor
                Write-Host "  Methods: $($methods -join ', ')" -ForegroundColor Yellow
                Write-Host ""

                $results += [PSCustomObject]@{
                    DisplayName       = $user.DisplayName
                    UserPrincipalName = $user.UserPrincipalName
                    AccountEnabled    = $user.AccountEnabled
                    MFAStatus         = if ($hasMFA) { "Enabled" } else { "Not Configured" }
                    AuthMethods       = $methods -join ', '
                    MethodCount       = $methods.Count
                }

            } catch {
                Write-Host "  ⚠ Error checking user: $_" -ForegroundColor Yellow
                Write-Host ""
            }
        }

        Write-Progress -Activity "Checking MFA Status" -Completed

        # Summary
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        $mfaEnabled = ($results | Where-Object { $_.MFAStatus -eq "Enabled" }).Count
        $mfaDisabled = ($results | Where-Object { $_.MFAStatus -eq "Not Configured" }).Count
        
        Write-Host "  MFA Enabled:      $mfaEnabled" -ForegroundColor Green
        Write-Host "  MFA Disabled:     $mfaDisabled" -ForegroundColor Red
        Write-Host "  Total Users:      $($results.Count)" -ForegroundColor White
        Write-Host "  Compliance Rate:  $([math]::Round(($mfaEnabled / $results.Count) * 100, 2))%" -ForegroundColor Cyan
        Write-Host ""

        # Export options
        Write-Host "Export Options:" -ForegroundColor Cyan
        Write-Host "1. Export to CSV" -ForegroundColor Gray
        Write-Host "2. Export to JSON" -ForegroundColor Gray
        Write-Host "3. Show users without MFA" -ForegroundColor Gray
        Write-Host "0. Exit" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host "Select option (0-3)"
        
        switch ($choice) {
            "1" {
                $exportPath = "$env:USERPROFILE\Desktop\MFA_Status_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
                $results | Export-Csv -Path $exportPath -NoTypeInformation
                Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
            }
            "2" {
                $exportPath = "$env:USERPROFILE\Desktop\MFA_Status_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                $results | ConvertTo-Json -Depth 3 | Out-File $exportPath
                Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
            }
            "3" {
                Write-Host ""
                Write-Host "USERS WITHOUT MFA:" -ForegroundColor Red
                $results | Where-Object { $_.MFAStatus -eq "Not Configured" } | ForEach-Object {
                    Write-Host "  • $($_.DisplayName) ($($_.UserPrincipalName))" -ForegroundColor Yellow
                }
            }
            default {
                Write-Host "Exiting..." -ForegroundColor Gray
            }
        }

    }
    catch {
        Write-Host "✗ Error retrieving MFA status: $_" -ForegroundColor Red
    }
}

# Run the function
$upn = Read-Host "Enter UPN to check specific user (or press Enter for all users)"
if ($upn) {
    Get-MFAStatus -UserPrincipalName $upn
} else {
    Get-MFAStatus
}
