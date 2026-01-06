#Requires -Version 5.1
<#
.SYNOPSIS
    Tests Active Directory replication health.

.DESCRIPTION
    This standalone snippet checks AD replication status across domain controllers
    and reports any replication issues.

.EXAMPLE
    Test-ADReplication

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/Test-ADReplication.ps1')

    Requires: Active Directory PowerShell module
    Requires: Domain Controller or RSAT tools
    Requires: Appropriate AD permissions (Domain Admin or equivalent)
#>

function Test-ADReplication {
    [CmdletBinding()]
    param()

    try {
        # Check if AD module is available
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Host "✗ Active Directory module not found" -ForegroundColor Red
            Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
            return
        }

        Import-Module ActiveDirectory -ErrorAction Stop

        Write-Host "Testing Active Directory Replication..." -ForegroundColor Cyan
        Write-Host ""

        # Get all domain controllers
        $dcs = Get-ADDomainController -Filter * | Sort-Object Name

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          DOMAIN CONTROLLERS                                ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Found $($dcs.Count) domain controller(s):" -ForegroundColor Yellow
        foreach ($dc in $dcs) {
            Write-Host "  • $($dc.Name) - $($dc.Site)" -ForegroundColor Green
        }
        Write-Host ""

        # Check replication status for each DC
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          REPLICATION STATUS                                ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $allHealthy = $true

        foreach ($dc in $dcs) {
            Write-Host "Checking $($dc.Name)..." -ForegroundColor Yellow
            
            # Test connectivity
            $online = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue
            
            if ($online) {
                Write-Host "  ✓ Online" -ForegroundColor Green
                
                # Get replication metadata
                try {
                    $replStatus = Get-ADReplicationPartnerMetadata -Target $dc.Name -ErrorAction Stop
                    
                    $hasFailures = $false
                    foreach ($partner in $replStatus) {
                        if ($partner.LastReplicationResult -ne 0) {
                            Write-Host "  ✗ Replication failure from $($partner.Partner)" -ForegroundColor Red
                            Write-Host "    Error: $($partner.LastReplicationResult)" -ForegroundColor Red
                            $hasFailures = $true
                            $allHealthy = $false
                        }
                    }
                    
                    if (-not $hasFailures) {
                        Write-Host "  ✓ All replications successful" -ForegroundColor Green
                        Write-Host "  Last sync: $($replStatus[0].LastReplicationSuccess)" -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Host "  ⚠ Could not retrieve replication status: $_" -ForegroundColor Yellow
                    $allHealthy = $false
                }
            } else {
                Write-Host "  ✗ Offline or unreachable" -ForegroundColor Red
                $allHealthy = $false
            }
            Write-Host ""
        }

        # Summary
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SUMMARY                                           ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        if ($allHealthy) {
            Write-Host "✓ All domain controllers are replicating successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Replication issues detected - review details above" -ForegroundColor Red
        }
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error testing replication: $_" -ForegroundColor Red
    }
}

# Execute the function
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AD REPLICATION HEALTH CHECK                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if AD module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "✗ Active Directory module not found" -ForegroundColor Red
    Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
    exit
}

Write-Host "This script will test replication health across all domain controllers." -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Continue? (y/n)"

if ($confirm -eq 'y') {
    Write-Host ""
    Test-ADReplication
} else {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
}
