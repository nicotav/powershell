#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Comprehensive computer maintenance and health restoration script.

.DESCRIPTION
    This standalone script performs complete system maintenance including:
    - Time synchronization with Microsoft time server
    - Windows component repair (DISM and SFC)
    - Windows Update installation
    - Driver updates via Windows Update
    - Microsoft Store app updates
    - Winget package updates
    - Temp file cleanup
    - System restart prompt

.EXAMPLE
    Invoke-ComputerMaintenance

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Invoke-ComputerMaintenance.ps1')

    Requires: Administrator privileges
    Requires: Internet connection
    Duration: 15-60 minutes depending on system state
#>

function Invoke-ComputerMaintenance {
    [CmdletBinding()]
    param()

    $startTime = Get-Date
    $logFile = "$env:TEMP\MaintenanceLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    function Write-Log {
        param([string]$Message, [string]$Color = 'White')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] $Message"
        Add-Content -Path $logFile -Value $logMessage
        Write-Host $Message -ForegroundColor $Color
    }

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          COMPREHENSIVE COMPUTER MAINTENANCE                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Maintenance started. Log file: $logFile" -Color Yellow
    Write-Host ""

    # STEP 1: Time Synchronization
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 1: Time Synchronization" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $currentTime = Get-Date
        Write-Log "Current system time: $currentTime" -Color Gray
        
        # Configure Windows Time service
        Write-Log "Configuring Windows Time service..." -Color Cyan
        Set-Service -Name W32Time -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name W32Time -ErrorAction SilentlyContinue
        
        # Set time server to Microsoft
        w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update | Out-Null
        
        # Force sync
        Write-Log "Synchronizing with time.windows.com..." -Color Cyan
        $syncResult = w32tm /resync /force 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $newTime = Get-Date
            $timeDiff = ($newTime - $currentTime).TotalSeconds
            Write-Log "✓ Time synchronized successfully" -Color Green
            Write-Log "  Time adjustment: $([math]::Round($timeDiff, 2)) seconds" -Color Gray
        } else {
            Write-Log "⚠ Time sync completed with warnings" -Color Yellow
        }
    }
    catch {
        Write-Log "✗ Time synchronization failed: $_" -Color Red
    }
    Write-Host ""

    # STEP 2: Windows Component Repair (DISM)
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 2: Windows Component Health (DISM)" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Write-Log "Scanning component store health..." -Color Cyan
        Write-Host "This may take several minutes..." -ForegroundColor Gray
        
        $dismScan = DISM /Online /Cleanup-Image /ScanHealth 2>&1
        
        Write-Log "Checking for component store corruption..." -Color Cyan
        $dismCheck = DISM /Online /Cleanup-Image /CheckHealth 2>&1
        
        if ($dismCheck -match "No component store corruption detected") {
            Write-Log "✓ Component store is healthy" -Color Green
        } else {
            Write-Log "⚠ Component store issues detected, attempting repair..." -Color Yellow
            Write-Host "Repairing component store (this may take 10-20 minutes)..." -ForegroundColor Yellow
            
            $dismRepair = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "✓ Component store repair completed successfully" -Color Green
            } else {
                Write-Log "⚠ Component store repair completed with warnings" -Color Yellow
            }
        }
        
        # Cleanup component store
        Write-Log "Cleaning up component store..." -Color Cyan
        DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
        Write-Log "✓ Component store cleanup completed" -Color Green
    }
    catch {
        Write-Log "✗ DISM operations failed: $_" -Color Red
    }
    Write-Host ""

    # STEP 3: System File Check (SFC)
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 3: System File Integrity Check (SFC)" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Write-Log "Scanning system files for corruption..." -Color Cyan
        Write-Host "This may take 10-15 minutes..." -ForegroundColor Gray
        
        $sfcResult = sfc /scannow 2>&1
        
        if ($sfcResult -match "did not find any integrity violations") {
            Write-Log "✓ No system file corruption detected" -Color Green
        } elseif ($sfcResult -match "found corrupt files and successfully repaired them") {
            Write-Log "✓ System file corruption detected and repaired" -Color Green
        } elseif ($sfcResult -match "found corrupt files but was unable to fix") {
            Write-Log "⚠ System file corruption detected but cannot be repaired automatically" -Color Yellow
            Write-Log "  Review C:\Windows\Logs\CBS\CBS.log for details" -Color Gray
        } else {
            Write-Log "✓ System file check completed" -Color Green
        }
    }
    catch {
        Write-Log "✗ SFC scan failed: $_" -Color Red
    }
    Write-Host ""

    # STEP 4: Windows Update
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 4: Windows Update" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Write-Log "Checking for Windows updates..." -Color Cyan
        
        # Check if PSWindowsUpdate module is available
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Log "Installing PSWindowsUpdate module..." -Color Yellow
            Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck -ErrorAction Stop
        }
        
        Import-Module PSWindowsUpdate -ErrorAction Stop
        
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
        
        if ($updates) {
            Write-Log "Found $($updates.Count) update(s) available" -Color Yellow
            Write-Log "Installing updates (this may take a while)..." -Color Cyan
            
            Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop | ForEach-Object {
                Write-Log "  • $($_.Title)" -Color Gray
            }
            
            Write-Log "✓ Windows updates installed successfully" -Color Green
        } else {
            Write-Log "✓ Windows is up to date" -Color Green
        }
    }
    catch {
        Write-Log "⚠ Windows Update check failed: $_" -Color Yellow
        Write-Log "  Try running Windows Update manually" -Color Gray
    }
    Write-Host ""

    # STEP 5: Driver Updates
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 5: Driver Updates" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Write-Log "Checking for driver updates..." -Color Cyan
        
        if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
            $drivers = Get-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -ErrorAction SilentlyContinue
            
            if ($drivers) {
                Write-Log "Found $($drivers.Count) driver update(s) available" -Color Yellow
                Write-Log "Installing driver updates..." -Color Cyan
                
                Install-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -AcceptAll -IgnoreReboot -ErrorAction Stop | ForEach-Object {
                    Write-Log "  • $($_.Title)" -Color Gray
                }
                
                Write-Log "✓ Driver updates installed successfully" -Color Green
            } else {
                Write-Log "✓ All drivers are up to date" -Color Green
            }
        } else {
            Write-Log "⚠ Unable to check driver updates (PSWindowsUpdate not available)" -Color Yellow
        }
    }
    catch {
        Write-Log "⚠ Driver update check failed: $_" -Color Yellow
    }
    Write-Host ""

    # STEP 6: Microsoft Store Apps Update
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 6: Microsoft Store Apps Update" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Write-Log "Checking Microsoft Store for app updates..." -Color Cyan
        
        # Trigger Store updates
        Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" -ErrorAction SilentlyContinue | 
            Invoke-CimMethod -MethodName UpdateScanMethod -ErrorAction SilentlyContinue | Out-Null
        
        Write-Log "✓ Microsoft Store update check triggered" -Color Green
        Write-Log "  Store apps will update in the background" -Color Gray
    }
    catch {
        Write-Log "⚠ Could not trigger Store updates automatically" -Color Yellow
        Write-Log "  Open Microsoft Store and click 'Get updates' manually" -Color Gray
    }
    Write-Host ""

    # STEP 7: Winget Package Updates
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 7: Winget Package Updates" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
        
        if ($wingetPath) {
            Write-Log "Checking for Winget package updates..." -Color Cyan
            
            $upgradable = winget upgrade --accept-source-agreements 2>&1 | Out-String
            
            if ($upgradable -match "upgrades available") {
                Write-Log "Found upgradable packages" -Color Yellow
                Write-Log "Upgrading all packages..." -Color Cyan
                
                winget upgrade --all --silent --accept-package-agreements --accept-source-agreements 2>&1 | ForEach-Object {
                    if ($_ -match "Successfully installed") {
                        Write-Log "  ✓ $_" -Color Gray
                    }
                }
                
                Write-Log "✓ Winget packages updated" -Color Green
            } else {
                Write-Log "✓ All Winget packages are up to date" -Color Green
            }
        } else {
            Write-Log "⚠ Winget is not installed" -Color Yellow
            Write-Log "  Install from: https://aka.ms/getwinget" -Color Gray
        }
    }
    catch {
        Write-Log "⚠ Winget update failed: $_" -Color Yellow
    }
    Write-Host ""

    # STEP 8: Temp File Cleanup
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 8: Temporary Files Cleanup" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $beforeSize = 0
        $afterSize = 0
        
        $tempPaths = @(
            "$env:TEMP",
            "C:\Windows\Temp",
            "C:\Windows\Prefetch",
            "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
        )
        
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                try {
                    $before = (Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    $beforeSize += $before
                    
                    Write-Log "Cleaning: $path" -Color Cyan
                    Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    
                    $after = (Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    $afterSize += $after
                }
                catch {
                    Write-Log "  ⚠ Some files could not be deleted (in use)" -Color Yellow
                }
            }
        }
        
        # Run Disk Cleanup
        Write-Log "Running Disk Cleanup utility..." -Color Cyan
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
        
        $freedSpace = [math]::Round(($beforeSize - $afterSize) / 1GB, 2)
        Write-Log "✓ Cleanup completed. Freed approximately $freedSpace GB" -Color Green
    }
    catch {
        Write-Log "⚠ Cleanup encountered errors: $_" -Color Yellow
    }
    Write-Host ""

    # STEP 9: Security Hardening
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 9: Security Hardening Checks" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Windows Defender status
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus) {
            if ($defenderStatus.AntivirusEnabled) {
                Write-Log "✓ Windows Defender is enabled" -Color Green
            } else {
                Write-Log "⚠ Windows Defender is disabled" -Color Yellow
            }
            
            if ($defenderStatus.RealTimeProtectionEnabled) {
                Write-Log "✓ Real-time protection is enabled" -Color Green
            } else {
                Write-Log "⚠ Real-time protection is disabled" -Color Yellow
            }
        }
        
        # Windows Firewall status
        $firewallProfiles = Get-NetFirewallProfile
        foreach ($profile in $firewallProfiles) {
            if ($profile.Enabled) {
                Write-Log "✓ Firewall ($($profile.Name)) is enabled" -Color Green
            } else {
                Write-Log "⚠ Firewall ($($profile.Name)) is disabled" -Color Yellow
            }
        }
        
        # UAC status
        $uacValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA).EnableLUA
        if ($uacValue -eq 1) {
            Write-Log "✓ User Account Control (UAC) is enabled" -Color Green
        } else {
            Write-Log "⚠ User Account Control (UAC) is disabled" -Color Yellow
        }
    }
    catch {
        Write-Log "⚠ Security check encountered errors: $_" -Color Yellow
    }
    Write-Host ""

    # Summary
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          MAINTENANCE COMPLETE                              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Total duration: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -Color Yellow
    Write-Log "Log file saved: $logFile" -Color Gray
    Write-Host ""
    
    Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
    Write-Host "  • Review the maintenance log for any errors" -ForegroundColor Gray
    Write-Host "  • Restart your computer to complete updates" -ForegroundColor Gray
    Write-Host "  • Run this maintenance monthly for best performance" -ForegroundColor Gray
    Write-Host "  • Keep Windows Defender and Firewall enabled" -ForegroundColor Gray
    Write-Host ""
    
    # Restart prompt
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
    $restart = Read-Host "Restart computer now to complete updates? (y/n)"
    
    if ($restart -eq 'y') {
        Write-Log "Initiating system restart in 60 seconds..." -Color Yellow
        Write-Host ""
        Write-Host "Restarting in 60 seconds... (Press Ctrl+C to cancel)" -ForegroundColor Yellow
        shutdown /r /t 60 /c "System maintenance completed. Restart required to complete updates."
    } else {
        Write-Log "Restart postponed by user" -Color Yellow
        Write-Host "Please restart your computer at your earliest convenience." -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Execute maintenance
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          COMPREHENSIVE COMPUTER MAINTENANCE                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will perform complete system maintenance:" -ForegroundColor Yellow
Write-Host "  • Time synchronization" -ForegroundColor Gray
Write-Host "  • Windows component repair (DISM)" -ForegroundColor Gray
Write-Host "  • System file integrity check (SFC)" -ForegroundColor Gray
Write-Host "  • Windows updates" -ForegroundColor Gray
Write-Host "  • Driver updates" -ForegroundColor Gray
Write-Host "  • Microsoft Store app updates" -ForegroundColor Gray
Write-Host "  • Winget package updates" -ForegroundColor Gray
Write-Host "  • Temporary file cleanup" -ForegroundColor Gray
Write-Host "  • Security hardening checks" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠ This will take 15-60 minutes depending on your system" -ForegroundColor Yellow
Write-Host "⚠ Administrator privileges required" -ForegroundColor Yellow
Write-Host "⚠ Internet connection required" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Continue with maintenance? (y/n)"

if ($confirm -eq 'y') {
    Write-Host ""
    Invoke-ComputerMaintenance
} else {
    Write-Host "Maintenance cancelled." -ForegroundColor Yellow
}
