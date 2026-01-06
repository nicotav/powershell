#Requires -Version 5.1
#Requires -Modules WebAdministration
<#
.SYNOPSIS
    Gets detailed information about IIS websites and application pools.

.DESCRIPTION
    Retrieves IIS site configuration, bindings, app pools, and health status.

.PARAMETER SiteName
    Name of the IIS site to analyze. If not specified, shows all sites.

.EXAMPLE
    Get-IISSiteInfo -SiteName "Default Web Site"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/IIS/Get-IISSiteInfo.ps1')

    Requires: IIS module, Administrator privileges
#>

function Get-IISSiteInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SiteName
    )

    try {
        # Check if running as admin
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "✗ This script requires Administrator privileges" -ForegroundColor Red
            return
        }

        if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
            Write-Host "✗ IIS WebAdministration module not found" -ForegroundColor Red
            Write-Host "  Install IIS Management Tools feature" -ForegroundColor Yellow
            return
        }

        Import-Module WebAdministration -ErrorAction Stop

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          IIS SITE INFORMATION                              ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        if ($SiteName) {
            $sites = @(Get-Website -Name $SiteName)
        } else {
            $sites = Get-Website
        }

        foreach ($site in $sites) {
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "Site Name:         $($site.Name)" -ForegroundColor Green
            Write-Host "State:             $($site.State)" -ForegroundColor $(if($site.State -eq 'Started'){'Green'}else{'Red'})
            Write-Host "ID:                $($site.Id)" -ForegroundColor Gray
            Write-Host "App Pool:          $($site.ApplicationPool)" -ForegroundColor Cyan
            Write-Host "Physical Path:     $($site.PhysicalPath)" -ForegroundColor Gray
            Write-Host ""

            # Bindings
            Write-Host "BINDINGS:" -ForegroundColor Yellow
            foreach ($binding in $site.Bindings.Collection) {
                Write-Host "  • $($binding.protocol)://$($binding.bindingInformation)" -ForegroundColor Yellow
            }
            Write-Host ""

            # Application Pool Info
            $appPool = Get-IISAppPool -Name $site.ApplicationPool
            Write-Host "APP POOL DETAILS:" -ForegroundColor Yellow
            Write-Host "  Status:          $($appPool.State)" -ForegroundColor $(if($appPool.State -eq 'Started'){'Green'}else{'Red'})
            Write-Host "  .NET Version:    $($appPool.ManagedRuntimeVersion)" -ForegroundColor Gray
            Write-Host "  Pipeline Mode:   $($appPool.ManagedPipelineMode)" -ForegroundColor Gray
            Write-Host "  Identity:        $($appPool.ProcessModel.IdentityType)" -ForegroundColor Gray
            Write-Host ""
        }

        # Summary
        $runningCount = ($sites | Where-Object { $_.State -eq 'Started' }).Count
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        Write-Host "  Total Sites:     $($sites.Count)" -ForegroundColor White
        Write-Host "  Running:         $runningCount" -ForegroundColor Green
        Write-Host "  Stopped:         $($sites.Count - $runningCount)" -ForegroundColor $(if($sites.Count -eq $runningCount){'Green'}else{'Red'})
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving IIS info: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          IIS SITE INFO                                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

try {
    Import-Module WebAdministration -ErrorAction Stop
    $sites = Get-Website

    Write-Host "Select a site to inspect:" -ForegroundColor Cyan
    $sites | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "  $i. $($_.Name) - $($_.State)" -ForegroundColor Gray
        $i++
    }
    Write-Host "  0. Show all sites" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option"
    if ($choice -eq "0") {
        Get-IISSiteInfo
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $sites.Count) {
        $siteName = $sites[[int]$choice - 1].Name
        Get-IISSiteInfo -SiteName $siteName
    }
}
catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Write-Host "Ensure IIS is installed and you're running as Administrator" -ForegroundColor Yellow
}
