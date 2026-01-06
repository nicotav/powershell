#Requires -Version 5.1
#Requires -Modules DhcpServer
<#
.SYNOPSIS
    Gets DHCP server scope information and lease statistics.

.DESCRIPTION
    Retrieves DHCP scope configuration, active leases, and utilization metrics.

.PARAMETER ComputerName
    DHCP server name (default: localhost).

.EXAMPLE
    Get-DHCPScopes -ComputerName "dhcp01.contoso.com"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/NetworkServices/Get-DHCPScopes.ps1')

    Requires: DhcpServer module, Administrator privileges
#>

function Get-DHCPScopes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "✗ This script requires Administrator privileges" -ForegroundColor Red
            return
        }

        if (-not (Get-Module -ListAvailable -Name DhcpServer)) {
            Write-Host "✗ DhcpServer module not found" -ForegroundColor Red
            Write-Host "  Install DHCP Server Management Tools" -ForegroundColor Yellow
            return
        }

        Import-Module DhcpServer -ErrorAction Stop

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          DHCP SCOPES INFORMATION                           ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Connecting to DHCP server: $ComputerName" -ForegroundColor Yellow
        Write-Host ""

        # Server Statistics
        $serverStats = Get-DhcpServerv4Statistics -ComputerName $ComputerName

        Write-Host "SERVER STATISTICS:" -ForegroundColor Yellow
        Write-Host "  Total Scopes:    $($serverStats.TotalScopes)" -ForegroundColor White
        Write-Host "  Active Leases:   $($serverStats.InUse)" -ForegroundColor Green
        Write-Host "  Available:       $($serverStats.Available)" -ForegroundColor Gray
        Write-Host "  Total Addresses: $($serverStats.TotalAddresses)" -ForegroundColor White
        Write-Host "  Utilization:     $([math]::Round(($serverStats.PercentageInUse), 2))%" -ForegroundColor Cyan
        Write-Host ""

        # Scopes
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          DHCP SCOPES                                       ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $scopes = Get-DhcpServerv4Scope -ComputerName $ComputerName

        foreach ($scope in $scopes) {
            $scopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $ComputerName -ScopeId $scope.ScopeId
            
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "Scope Name:        $($scope.Name)" -ForegroundColor Green
            Write-Host "Scope ID:          $($scope.ScopeId)" -ForegroundColor Cyan
            Write-Host "State:             $($scope.State)" -ForegroundColor $(if($scope.State -eq 'Active'){'Green'}else{'Red'})
            Write-Host ""
            
            Write-Host "RANGE:" -ForegroundColor Yellow
            Write-Host "  Start:           $($scope.StartRange)" -ForegroundColor Gray
            Write-Host "  End:             $($scope.EndRange)" -ForegroundColor Gray
            Write-Host "  Subnet Mask:     $($scope.SubnetMask)" -ForegroundColor Gray
            Write-Host "  Lease Duration:  $($scope.LeaseDuration)" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "STATISTICS:" -ForegroundColor Yellow
            Write-Host "  In Use:          $($scopeStats.InUse)" -ForegroundColor Green
            Write-Host "  Available:       $($scopeStats.Available)" -ForegroundColor Gray
            Write-Host "  Reserved:        $($scopeStats.Reserved)" -ForegroundColor Cyan
            Write-Host "  Utilization:     $([math]::Round($scopeStats.PercentageInUse, 2))%" -ForegroundColor $(if($scopeStats.PercentageInUse -gt 90){'Red'}elseif($scopeStats.PercentageInUse -gt 75){'Yellow'}else{'Green'})
            
            if ($scopeStats.PercentageInUse -gt 90) {
                Write-Host "  ⚠ WARNING: High utilization!" -ForegroundColor Red
            }
            Write-Host ""

            # Scope Options
            $options = Get-DhcpServerv4OptionValue -ComputerName $ComputerName -ScopeId $scope.ScopeId -ErrorAction SilentlyContinue
            if ($options) {
                Write-Host "OPTIONS:" -ForegroundColor Yellow
                $options | ForEach-Object {
                    Write-Host "  • Option $($_.OptionId): $($_.Value)" -ForegroundColor DarkGray
                }
                Write-Host ""
            }
        }

        # Summary
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        $activeScopes = ($scopes | Where-Object { $_.State -eq 'Active' }).Count
        Write-Host "  Total Scopes:    $($scopes.Count)" -ForegroundColor White
        Write-Host "  Active:          $activeScopes" -ForegroundColor Green
        Write-Host "  Inactive:        $($scopes.Count - $activeScopes)" -ForegroundColor $(if($scopes.Count -eq $activeScopes){'Green'}else{'Yellow'})
        Write-Host ""

        # Export option
        $export = Read-Host "Export scope details to CSV? (Y/N)"
        if ($export -eq 'Y' -or $export -eq 'y') {
            $exportPath = "$env:USERPROFILE\Desktop\DHCP_Scopes_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            $scopes | Select-Object Name, ScopeId, State, StartRange, EndRange, SubnetMask, LeaseDuration |
                Export-Csv -Path $exportPath -NoTypeInformation
            Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
        }

    }
    catch {
        Write-Host "✗ Error retrieving DHCP information: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          DHCP SCOPES INFO                                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$server = Read-Host "Enter DHCP server name (or press Enter for localhost)"
if (-not $server) {
    $server = $env:COMPUTERNAME
}

Get-DHCPScopes -ComputerName $server
