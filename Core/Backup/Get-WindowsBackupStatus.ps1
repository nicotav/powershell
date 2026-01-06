#Requires -Version 5.1
<#
.SYNOPSIS
    Gets Windows Backup status and history.

.DESCRIPTION
    Retrieves Windows Server Backup configuration, schedule, and recent backup history.

.EXAMPLE
    Get-WindowsBackupStatus

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Backup/Get-WindowsBackupStatus.ps1')

    Requires: Windows Server Backup feature, Administrator privileges
#>

function Get-WindowsBackupStatus {
    [CmdletBinding()]
    param()

    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "✗ This script requires Administrator privileges" -ForegroundColor Red
            return
        }

        if (-not (Get-Module -ListAvailable -Name Windows.ServerBackup)) {
            Write-Host "✗ Windows.ServerBackup module not found" -ForegroundColor Red
            Write-Host "  Install Windows Server Backup feature" -ForegroundColor Yellow
            return
        }

        Import-Module Windows.ServerBackup -ErrorAction Stop

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          WINDOWS BACKUP STATUS                             ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        # Backup Policy
        $policy = Get-WBPolicy -Editable -ErrorAction SilentlyContinue
        
        if ($policy) {
            Write-Host "BACKUP POLICY:" -ForegroundColor Yellow
            $schedule = Get-WBSchedule -Policy $policy
            Write-Host "  Schedule:        $($schedule -join ', ')" -ForegroundColor Gray
            
            $volumes = Get-WBVolume -Policy $policy
            Write-Host "  Volumes:         $($volumes.Count)" -ForegroundColor Gray
            
            $target = Get-WBBackupTarget -Policy $policy
            Write-Host "  Target:          $($target.Path)" -ForegroundColor Cyan
            Write-Host ""
        } else {
            Write-Host "⚠ No backup policy configured" -ForegroundColor Yellow
            Write-Host ""
        }

        # Recent Backups
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          RECENT BACKUP HISTORY                             ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $backups = Get-WBSummary
        
        if ($backups) {
            Write-Host "Last Backup:" -ForegroundColor Green
            Write-Host "  Time:            $($backups.LastBackupTime)" -ForegroundColor Gray
            Write-Host "  Result:          $($backups.LastBackupResultHR)" -ForegroundColor $(if($backups.LastBackupResultHR -eq 0){'Green'}else{'Red'})
            Write-Host "  Next Scheduled:  $($backups.NextBackupTime)" -ForegroundColor Cyan
            Write-Host ""
            
            Write-Host "Statistics:" -ForegroundColor Yellow
            Write-Host "  Success Count:   $($backups.NumberOfSuccessfulBackups)" -ForegroundColor Green
            Write-Host "  Failed Count:    $($backups.NumberOfFailedBackups)" -ForegroundColor $(if($backups.NumberOfFailedBackups -gt 0){'Red'}else{'Green'})
            Write-Host ""
        } else {
            Write-Host "⚠ No backup history available" -ForegroundColor Yellow
            Write-Host ""
        }

        # Backup Jobs
        Write-Host "BACKUP JOBS:" -ForegroundColor Yellow
        $jobs = Get-WBJob -Previous 5
        
        if ($jobs) {
            foreach ($job in $jobs) {
                $statusColor = switch ($job.JobState) {
                    'Completed' { 'Green' }
                    'Failed' { 'Red' }
                    'Running' { 'Cyan' }
                    default { 'Yellow' }
                }
                
                Write-Host "Job ID:            $($job.JobId)" -ForegroundColor White
                Write-Host "  Status:          $($job.JobState)" -ForegroundColor $statusColor
                Write-Host "  Start:           $($job.StartTime)" -ForegroundColor Gray
                Write-Host "  End:             $($job.EndTime)" -ForegroundColor Gray
                if ($job.HResult -ne 0) {
                    Write-Host "  Error:           $($job.HResult)" -ForegroundColor Red
                }
                Write-Host ""
            }
        } else {
            Write-Host "  No recent jobs found" -ForegroundColor DarkGray
            Write-Host ""
        }

        # VSS Status
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          VOLUME SHADOW COPY STATUS                         ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $vssWriters = vssadmin list writers
        $writerCount = ($vssWriters | Select-String "Writer name:").Count
        $stableWriters = ($vssWriters | Select-String "State: \[1\] Stable").Count
        
        Write-Host "VSS Writers:" -ForegroundColor Yellow
        Write-Host "  Total:           $writerCount" -ForegroundColor White
        Write-Host "  Stable:          $stableWriters" -ForegroundColor Green
        Write-Host "  Unstable:        $($writerCount - $stableWriters)" -ForegroundColor $(if($writerCount -eq $stableWriters){'Green'}else{'Red'})
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving backup status: $_" -ForegroundColor Red
    }
}

# Run the function
Get-WindowsBackupStatus
