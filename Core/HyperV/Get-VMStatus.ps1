#Requires -Version 5.1
#Requires -Modules Hyper-V
<#
.SYNOPSIS
    Gets detailed information about Hyper-V virtual machines.

.DESCRIPTION
    Retrieves VM configuration, resource usage, snapshots, and health status.

.PARAMETER VMName
    Name of the VM to analyze. If not specified, shows all VMs.

.EXAMPLE
    Get-VMStatus -VMName "WebServer01"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/HyperV/Get-VMStatus.ps1')

    Requires: Hyper-V PowerShell module, Administrator privileges
#>

function Get-VMStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$VMName
    )

    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "✗ This script requires Administrator privileges" -ForegroundColor Red
            return
        }

        if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
            Write-Host "✗ Hyper-V module not found" -ForegroundColor Red
            Write-Host "  Install Hyper-V feature or run on Hyper-V host" -ForegroundColor Yellow
            return
        }

        Import-Module Hyper-V -ErrorAction Stop

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          HYPER-V VM STATUS                                 ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        if ($VMName) {
            $vms = @(Get-VM -Name $VMName)
        } else {
            $vms = Get-VM
        }

        foreach ($vm in $vms) {
            $stateColor = switch ($vm.State) {
                'Running' { 'Green' }
                'Off' { 'Gray' }
                'Paused' { 'Yellow' }
                default { 'Red' }
            }

            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "VM Name:           $($vm.Name)" -ForegroundColor Green
            Write-Host "State:             $($vm.State)" -ForegroundColor $stateColor
            Write-Host "Generation:        $($vm.Generation)" -ForegroundColor Gray
            Write-Host "Uptime:            $($vm.Uptime)" -ForegroundColor Gray
            Write-Host ""

            # Resources
            Write-Host "RESOURCES:" -ForegroundColor Yellow
            Write-Host "  CPU Count:       $($vm.ProcessorCount)" -ForegroundColor Gray
            Write-Host "  Memory (MB):     $($vm.MemoryAssigned / 1MB)" -ForegroundColor Gray
            Write-Host "  Memory Startup:  $($vm.MemoryStartup / 1MB) MB" -ForegroundColor Gray
            Write-Host "  Dynamic Memory:  $($vm.DynamicMemoryEnabled)" -ForegroundColor Gray
            Write-Host ""

            # Virtual Disks
            Write-Host "VIRTUAL DISKS:" -ForegroundColor Yellow
            $vhds = Get-VMHardDiskDrive -VMName $vm.Name
            foreach ($vhd in $vhds) {
                Write-Host "  • $($vhd.Path)" -ForegroundColor Cyan
                if (Test-Path $vhd.Path) {
                    $vhdInfo = Get-VHD -Path $vhd.Path
                    Write-Host "    Size: $([math]::Round($vhdInfo.FileSize / 1GB, 2)) GB" -ForegroundColor DarkGray
                }
            }
            Write-Host ""

            # Network Adapters
            Write-Host "NETWORK ADAPTERS:" -ForegroundColor Yellow
            $nics = Get-VMNetworkAdapter -VMName $vm.Name
            foreach ($nic in $nics) {
                Write-Host "  • $($nic.SwitchName)" -ForegroundColor Yellow
                Write-Host "    MAC: $($nic.MacAddress)" -ForegroundColor DarkGray
                if ($nic.IPAddresses) {
                    Write-Host "    IPs: $($nic.IPAddresses -join ', ')" -ForegroundColor DarkGray
                }
            }
            Write-Host ""

            # Snapshots
            $snapshots = Get-VMSnapshot -VMName $vm.Name
            if ($snapshots) {
                Write-Host "SNAPSHOTS: ($($snapshots.Count))" -ForegroundColor Yellow
                $snapshots | ForEach-Object {
                    Write-Host "  • $($_.Name) - $($_.CreationTime)" -ForegroundColor Cyan
                }
                Write-Host ""
            }

            # Integration Services
            Write-Host "INTEGRATION SERVICES:" -ForegroundColor Yellow
            $integrationServices = Get-VMIntegrationService -VMName $vm.Name
            foreach ($service in $integrationServices) {
                $serviceColor = if ($service.Enabled) { 'Green' } else { 'Gray' }
                Write-Host "  • $($service.Name): $($service.Enabled)" -ForegroundColor $serviceColor
            }
            Write-Host ""
        }

        # Summary
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        $running = ($vms | Where-Object { $_.State -eq 'Running' }).Count
        Write-Host "  Total VMs:       $($vms.Count)" -ForegroundColor White
        Write-Host "  Running:         $running" -ForegroundColor Green
        Write-Host "  Off:             $(($vms | Where-Object { $_.State -eq 'Off' }).Count)" -ForegroundColor Gray
        Write-Host "  Other:           $(($vms | Where-Object { $_.State -notin @('Running','Off') }).Count)" -ForegroundColor Yellow
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving VM status: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          HYPER-V VM STATUS                                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

try {
    Import-Module Hyper-V -ErrorAction Stop
    $vms = Get-VM

    if ($vms.Count -eq 0) {
        Write-Host "No virtual machines found" -ForegroundColor Yellow
        exit
    }

    Write-Host "Select a VM to inspect:" -ForegroundColor Cyan
    $vms | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "  $i. $($_.Name) - $($_.State)" -ForegroundColor Gray
        $i++
    }
    Write-Host "  0. Show all VMs" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option"
    if ($choice -eq "0") {
        Get-VMStatus
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $vms.Count) {
        $vmName = $vms[[int]$choice - 1].Name
        Get-VMStatus -VMName $vmName
    }
}
catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Write-Host "Ensure Hyper-V is installed and you're running as Administrator" -ForegroundColor Yellow
}
