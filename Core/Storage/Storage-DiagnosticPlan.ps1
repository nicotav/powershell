#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive storage diagnostic plan combining multiple tools.

.DESCRIPTION
    This diagnostic plan runs a series of storage health checks in logical order:
    1. Disk space report
    2. Large files identification
    3. Summary and recommendations

.EXAMPLE
    Invoke-StorageDiagnosticPlan

.NOTES
    This is a standalone diagnostic plan. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Storage/Storage-DiagnosticPlan.ps1')
#>

# Define all functions needed for this plan
function Get-DiskSpaceReport {
    [CmdletBinding()]
    param()

    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:' }

    foreach ($drive in $drives) {
        $total = $drive.Used + $drive.Free
        $percent = [math]::Round(($drive.Used / $total) * 100, 2)
        $freeGB = [math]::Round($drive.Free / 1GB, 2)

        $color = if ($percent -gt 80) { 'Red' } elseif ($percent -gt 60) { 'Yellow' } else { 'Green' }

        Write-Host "Drive $($drive.Name): $percent% used ($freeGB GB free)" -ForegroundColor $color
    }
}

function Find-LargestFiles {
    [CmdletBinding()]
    param(
        [string]$Path = $env:TEMP
    )

    try {
        $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
                 Sort-Object -Property Length -Descending |
                 Select-Object -First 5

        Write-Host "Largest files in $($Path):\" -ForegroundColor Green
        foreach ($file in $files) {
            $sizeMB = [math]::Round($file.Length / 1MB, 2)
            Write-Host "  $($file.Name) - $sizeMB MB" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "Could not scan directory" -ForegroundColor Yellow
    }
}

# Main diagnostic plan
function Invoke-StorageDiagnosticPlan {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          STORAGE DIAGNOSTIC PLAN                           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "STEP 1: Disk Space Report" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    Get-DiskSpaceReport
    Write-Host ""

    Write-Host "STEP 2: Largest Files (Temp Directory)" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    Find-LargestFiles -Path $env:TEMP
    Write-Host ""

    Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
    Write-Host "  • Check for large old files in user directories" -ForegroundColor Gray
    Write-Host "  • Consider cleanup if any drive exceeds 80% capacity" -ForegroundColor Gray
    Write-Host "  • Run Storage-Cleanup for safe temp file removal" -ForegroundColor Gray
    Write-Host ""

    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DIAGNOSTIC COMPLETE                               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Execute diagnostic plan
Invoke-StorageDiagnosticPlan
