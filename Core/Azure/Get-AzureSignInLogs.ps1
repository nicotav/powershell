#Requires -Version 5.1
<#
.SYNOPSIS
    Retrieves and analyzes Azure AD/Entra ID sign-in logs.

.DESCRIPTION
    This standalone snippet retrieves recent sign-in logs with filtering options
    for failed sign-ins, specific users, or suspicious activity.

.PARAMETER Days
    Number of days to look back (default: 7)

.PARAMETER UserPrincipalName
    Optional. Filter by specific user.

.PARAMETER FailedOnly
    Only show failed sign-ins.

.EXAMPLE
    Get-AzureSignInLogs -Days 7
    Get-AzureSignInLogs -UserPrincipalName "user@contoso.com" -Days 30
    Get-AzureSignInLogs -FailedOnly -Days 1

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Get-AzureSignInLogs.ps1')

    Requires: Microsoft.Graph PowerShell module
    Requires: AuditLog.Read.All permission
#>

function Get-AzureSignInLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Days = 7,

        [Parameter(Mandatory = $false)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory = $false)]
        [switch]$FailedOnly
    )

    try {
        # Check if Microsoft Graph module is available
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Reports)) {
            Write-Host "✗ Microsoft.Graph.Reports module not found" -ForegroundColor Red
            Write-Host "  Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
            return
        }

        Import-Module Microsoft.Graph.Reports -ErrorAction Stop
        Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction Stop

        # Check connection
        $context = Get-MgContext
        if (-not $context) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes "AuditLog.Read.All" -ErrorAction Stop
        }

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SIGN-IN LOGS ANALYSIS                             ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $startDate = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-ddTHH:mm:ssZ")
        Write-Host "Retrieving sign-in logs from last $Days days..." -ForegroundColor Yellow
        
        # Build filter
        $filter = "createdDateTime ge $startDate"
        if ($UserPrincipalName) {
            $filter += " and userPrincipalName eq '$UserPrincipalName'"
        }

        $signIns = Get-MgAuditLogSignIn -Filter $filter -All

        if ($FailedOnly) {
            $signIns = $signIns | Where-Object { $_.Status.ErrorCode -ne 0 }
        }

        if (-not $signIns) {
            Write-Host "No sign-in logs found for the specified criteria" -ForegroundColor Yellow
            return
        }

        Write-Host "Found $($signIns.Count) sign-in events" -ForegroundColor Green
        Write-Host ""

        # Display recent sign-ins
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "RECENT SIGN-INS:" -ForegroundColor Yellow
        Write-Host ""

        $signIns | Select-Object -First 20 | ForEach-Object {
            $statusColor = if ($_.Status.ErrorCode -eq 0) { 'Green' } else { 'Red' }
            $statusText = if ($_.Status.ErrorCode -eq 0) { "✓ Success" } else { "✗ Failed ($($_.Status.ErrorCode))" }

            Write-Host "Time:     $($_.CreatedDateTime)" -ForegroundColor Gray
            Write-Host "User:     $($_.UserPrincipalName)" -ForegroundColor White
            Write-Host "App:      $($_.AppDisplayName)" -ForegroundColor Cyan
            Write-Host "Status:   $statusText" -ForegroundColor $statusColor
            if ($_.Status.ErrorCode -ne 0) {
                Write-Host "Reason:   $($_.Status.FailureReason)" -ForegroundColor Yellow
            }
            Write-Host "IP:       $($_.IpAddress)" -ForegroundColor Gray
            Write-Host "Location: $($_.Location.City), $($_.Location.CountryOrRegion)" -ForegroundColor Gray
            Write-Host "Device:   $($_.DeviceDetail.OperatingSystem) - $($_.DeviceDetail.Browser)" -ForegroundColor Gray
            Write-Host ""
        }

        # Analytics
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "ANALYTICS:" -ForegroundColor Yellow
        Write-Host ""

        $totalSignIns = $signIns.Count
        $successfulSignIns = ($signIns | Where-Object { $_.Status.ErrorCode -eq 0 }).Count
        $failedSignIns = $totalSignIns - $successfulSignIns
        $uniqueUsers = ($signIns | Select-Object -ExpandProperty UserPrincipalName -Unique).Count
        $uniqueApps = ($signIns | Select-Object -ExpandProperty AppDisplayName -Unique).Count
        $uniqueIPs = ($signIns | Select-Object -ExpandProperty IpAddress -Unique).Count

        Write-Host "Total Sign-Ins:       $totalSignIns" -ForegroundColor White
        Write-Host "Successful:           $successfulSignIns" -ForegroundColor Green
        Write-Host "Failed:               $failedSignIns" -ForegroundColor $(if ($failedSignIns -gt 0) { 'Red' } else { 'Green' })
        Write-Host "Success Rate:         $([math]::Round(($successfulSignIns / $totalSignIns) * 100, 2))%" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Unique Users:         $uniqueUsers" -ForegroundColor White
        Write-Host "Unique Apps:          $uniqueApps" -ForegroundColor White
        Write-Host "Unique IP Addresses:  $uniqueIPs" -ForegroundColor White
        Write-Host ""

        # Top Failed Sign-Ins
        if ($failedSignIns -gt 0) {
            Write-Host "TOP FAILURE REASONS:" -ForegroundColor Red
            $signIns | Where-Object { $_.Status.ErrorCode -ne 0 } | 
                Group-Object -Property { $_.Status.FailureReason } | 
                Sort-Object Count -Descending | 
                Select-Object -First 10 | 
                ForEach-Object {
                    Write-Host "  • $($_.Name): $($_.Count) occurrences" -ForegroundColor Yellow
                }
            Write-Host ""
        }

        # Suspicious Activity Detection
        Write-Host "SUSPICIOUS ACTIVITY DETECTION:" -ForegroundColor Red
        Write-Host ""

        # Multiple IPs per user
        $userIPs = $signIns | Group-Object UserPrincipalName | Where-Object { 
            ($_.Group | Select-Object -ExpandProperty IpAddress -Unique).Count -gt 5 
        }
        if ($userIPs) {
            Write-Host "⚠ Users with multiple IPs (>5):" -ForegroundColor Yellow
            $userIPs | ForEach-Object {
                $ipCount = ($_.Group | Select-Object -ExpandProperty IpAddress -Unique).Count
                Write-Host "  • $($_.Name): $ipCount different IPs" -ForegroundColor Red
            }
            Write-Host ""
        }

        # High failure rates
        $highFailureUsers = $signIns | Group-Object UserPrincipalName | Where-Object {
            $failed = ($_.Group | Where-Object { $_.Status.ErrorCode -ne 0 }).Count
            $total = $_.Count
            ($failed / $total) -gt 0.5 -and $total -gt 5
        }
        if ($highFailureUsers) {
            Write-Host "⚠ Users with high failure rates (>50%):" -ForegroundColor Yellow
            $highFailureUsers | ForEach-Object {
                $failed = ($_.Group | Where-Object { $_.Status.ErrorCode -ne 0 }).Count
                $failRate = [math]::Round(($failed / $_.Count) * 100, 2)
                Write-Host "  • $($_.Name): $failRate% failures ($failed/$($_.Count))" -ForegroundColor Red
            }
            Write-Host ""
        }

        # Export option
        $export = Read-Host "Export results to CSV? (Y/N)"
        if ($export -eq 'Y' -or $export -eq 'y') {
            $exportPath = "$env:USERPROFILE\Desktop\SignInLogs_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            $signIns | Select-Object CreatedDateTime, UserPrincipalName, AppDisplayName, 
                @{N='Status';E={if($_.Status.ErrorCode -eq 0){'Success'}else{'Failed'}}},
                @{N='ErrorCode';E={$_.Status.ErrorCode}},
                @{N='FailureReason';E={$_.Status.FailureReason}},
                IpAddress,
                @{N='City';E={$_.Location.City}},
                @{N='Country';E={$_.Location.CountryOrRegion}},
                @{N='OS';E={$_.DeviceDetail.OperatingSystem}},
                @{N='Browser';E={$_.DeviceDetail.Browser}} |
                Export-Csv -Path $exportPath -NoTypeInformation
            Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
        }

    }
    catch {
        Write-Host "✗ Error retrieving sign-in logs: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AZURE SIGN-IN LOGS                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. All sign-ins (last 7 days)" -ForegroundColor Gray
Write-Host "2. Failed sign-ins only (last 7 days)" -ForegroundColor Gray
Write-Host "3. Specific user (last 30 days)" -ForegroundColor Gray
Write-Host "4. Custom query" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Select option (1-4)"

switch ($choice) {
    "1" { Get-AzureSignInLogs -Days 7 }
    "2" { Get-AzureSignInLogs -Days 7 -FailedOnly }
    "3" {
        $upn = Read-Host "Enter User Principal Name"
        Get-AzureSignInLogs -UserPrincipalName $upn -Days 30
    }
    "4" {
        $days = Read-Host "Enter number of days to look back"
        $upn = Read-Host "Enter User Principal Name (or press Enter for all users)"
        $failedOnly = Read-Host "Failed sign-ins only? (Y/N)"
        
        if ($upn) {
            if ($failedOnly -eq 'Y' -or $failedOnly -eq 'y') {
                Get-AzureSignInLogs -Days $days -UserPrincipalName $upn -FailedOnly
            } else {
                Get-AzureSignInLogs -Days $days -UserPrincipalName $upn
            }
        } else {
            if ($failedOnly -eq 'Y' -or $failedOnly -eq 'y') {
                Get-AzureSignInLogs -Days $days -FailedOnly
            } else {
                Get-AzureSignInLogs -Days $days
            }
        }
    }
    default {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Yellow
    }
}
