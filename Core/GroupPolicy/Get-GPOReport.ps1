#Requires -Version 5.1
#Requires -Modules GroupPolicy
<#
.SYNOPSIS
    Gets detailed Group Policy Object (GPO) information and generates reports.

.DESCRIPTION
    Retrieves GPO settings, links, status, and can generate HTML or XML reports.

.PARAMETER GPOName
    Name of the GPO to analyze. If not specified, shows all GPOs.

.EXAMPLE
    Get-GPOReport -GPOName "Default Domain Policy"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/GroupPolicy/Get-GPOReport.ps1')

    Requires: GroupPolicy module, Domain membership
#>

function Get-GPOReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$GPOName
    )

    try {
        if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
            Write-Host "✗ GroupPolicy module not found" -ForegroundColor Red
            Write-Host "  Install RSAT Group Policy Management Tools" -ForegroundColor Yellow
            return
        }

        Import-Module GroupPolicy -ErrorAction Stop

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GROUP POLICY REPORT                               ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        if ($GPOName) {
            $gpos = @(Get-GPO -Name $GPOName)
        } else {
            Write-Host "Retrieving all GPOs..." -ForegroundColor Yellow
            $gpos = Get-GPO -All
        }

        Write-Host "Found $($gpos.Count) GPO(s)" -ForegroundColor Green
        Write-Host ""

        foreach ($gpo in $gpos) {
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "GPO Name:          $($gpo.DisplayName)" -ForegroundColor Green
            Write-Host "Status:            $($gpo.GpoStatus)" -ForegroundColor $(if($gpo.GpoStatus -eq 'AllSettingsEnabled'){'Green'}else{'Yellow'})
            Write-Host "Created:           $($gpo.CreationTime)" -ForegroundColor Gray
            Write-Host "Modified:          $($gpo.ModificationTime)" -ForegroundColor Gray
            Write-Host "GUID:              $($gpo.Id)" -ForegroundColor DarkGray
            Write-Host "Owner:             $($gpo.Owner)" -ForegroundColor Gray
            Write-Host ""

            # Computer/User Settings
            Write-Host "SETTINGS:" -ForegroundColor Yellow
            Write-Host "  Computer:        $($gpo.Computer.Enabled)" -ForegroundColor Gray
            Write-Host "  User:            $($gpo.User.Enabled)" -ForegroundColor Gray
            Write-Host "  Computer Ver:    $($gpo.Computer.DSVersion)" -ForegroundColor DarkGray
            Write-Host "  User Ver:        $($gpo.User.DSVersion)" -ForegroundColor DarkGray
            Write-Host ""

            # WMI Filters
            if ($gpo.WmiFilter) {
                Write-Host "WMI Filter:        $($gpo.WmiFilter.Name)" -ForegroundColor Yellow
            }

            # GPO Links
            Write-Host "LINKS:" -ForegroundColor Yellow
            try {
                $links = Get-GPInheritance -Target "DC=$((Get-ADDomain).DistinguishedName)" -ErrorAction SilentlyContinue |
                         Select-Object -ExpandProperty GpoLinks |
                         Where-Object { $_.GpoId -eq $gpo.Id }
                
                if ($links) {
                    foreach ($link in $links) {
                        Write-Host "  • $($link.Target)" -ForegroundColor Cyan
                        Write-Host "    Enabled: $($link.Enabled)" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "  Not linked" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "  Unable to retrieve links" -ForegroundColor DarkGray
            }
            Write-Host ""
        }

        # Summary
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        $enabledGPOs = ($gpos | Where-Object { $_.GpoStatus -eq 'AllSettingsEnabled' }).Count
        Write-Host "  Total GPOs:      $($gpos.Count)" -ForegroundColor White
        Write-Host "  Enabled:         $enabledGPOs" -ForegroundColor Green
        Write-Host "  Disabled:        $(($gpos | Where-Object { $_.GpoStatus -eq 'AllSettingsDisabled' }).Count)" -ForegroundColor Red
        Write-Host ""

        # Export options
        if ($gpos.Count -eq 1) {
            Write-Host "Export Options:" -ForegroundColor Cyan
            Write-Host "1. Generate HTML Report" -ForegroundColor Gray
            Write-Host "2. Generate XML Report" -ForegroundColor Gray
            Write-Host "3. Copy GPO GUID" -ForegroundColor Gray
            Write-Host "0. Exit" -ForegroundColor Gray
            Write-Host ""
            
            $action = Read-Host "Select option (0-3)"
            
            switch ($action) {
                "1" {
                    $exportPath = "$env:USERPROFILE\Desktop\GPO_$($gpo.DisplayName -replace ' ','_')_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
                    Get-GPOReport -Name $gpo.DisplayName -ReportType Html -Path $exportPath
                    Write-Host "✓ HTML report generated: $exportPath" -ForegroundColor Green
                }
                "2" {
                    $exportPath = "$env:USERPROFILE\Desktop\GPO_$($gpo.DisplayName -replace ' ','_')_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
                    Get-GPOReport -Name $gpo.DisplayName -ReportType Xml -Path $exportPath
                    Write-Host "✓ XML report generated: $exportPath" -ForegroundColor Green
                }
                "3" {
                    Set-Clipboard -Value $gpo.Id.Guid
                    Write-Host "✓ GPO GUID copied to clipboard" -ForegroundColor Green
                }
            }
        }

    }
    catch {
        Write-Host "✗ Error retrieving GPO information: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          GROUP POLICY REPORT                               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

try {
    Import-Module GroupPolicy -ErrorAction Stop
    $gpos = Get-GPO -All | Sort-Object DisplayName

    Write-Host "Select a GPO to inspect:" -ForegroundColor Cyan
    $gpos | Select-Object -First 20 | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "  $i. $($_.DisplayName)" -ForegroundColor Gray
        $i++
    }
    Write-Host "  0. Show all GPOs" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option"
    if ($choice -eq "0") {
        Get-GPOReport
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 20) {
        $gpoName = ($gpos | Select-Object -First 20)[[int]$choice - 1].DisplayName
        Get-GPOReport -GPOName $gpoName
    }
}
catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Write-Host "Ensure you're on a domain-joined machine with RSAT tools installed" -ForegroundColor Yellow
}
