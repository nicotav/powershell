#Requires -Version 5.1
<#
.SYNOPSIS
    Takes a snapshot of current system performance metrics.

.DESCRIPTION
    This standalone snippet captures current CPU, memory, and disk usage
    to provide a quick performance overview.

.EXAMPLE
    Get-PerformanceSnapshot

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Get-PerformanceSnapshot.ps1')
#>

function Get-PerformanceSnapshot {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Taking performance snapshot..." -ForegroundColor Cyan
        Write-Host ""

        # CPU Usage
        Write-Host "CPU PERFORMANCE" -ForegroundColor Yellow
        $cpuUsage = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty LoadPercentage
        $cpuColor = if ($cpuUsage -gt 80) { 'Red' } elseif ($cpuUsage -gt 50) { 'Yellow' } else { 'Green' }
        Write-Host "  Current Usage: $cpuUsage%" -ForegroundColor $cpuColor
        Write-Host ""

        # Memory Usage
        Write-Host "MEMORY PERFORMANCE" -ForegroundColor Yellow
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalMemory = $os.TotalVisibleMemorySize
        $freeMemory = $os.FreePhysicalMemory
        $usedMemory = $totalMemory - $freeMemory
        $memoryPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 2)
        $memColor = if ($memoryPercent -gt 80) { 'Red' } elseif ($memoryPercent -gt 50) { 'Yellow' } else { 'Green' }

        Write-Host "  Total: $([math]::Round($totalMemory / 1MB, 2)) GB" -ForegroundColor Gray
        Write-Host "  Used: $([math]::Round($usedMemory / 1MB, 2)) GB" -ForegroundColor Gray
        Write-Host "  Free: $([math]::Round($freeMemory / 1MB, 2)) GB" -ForegroundColor Gray
        Write-Host "  Usage: $memoryPercent%" -ForegroundColor $memColor
        Write-Host ""

        # Disk Usage
        Write-Host "DISK PERFORMANCE" -ForegroundColor Yellow
        Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:' } | ForEach-Object {
            $diskPercent = [math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 2)
            $diskColor = if ($diskPercent -gt 80) { 'Red' } elseif ($diskPercent -gt 50) { 'Yellow' } else { 'Green' }
            Write-Host "  $($_.Name): $diskPercent% used ($([math]::Round($_.Free / 1GB, 2)) GB free)" -ForegroundColor $diskColor
        }
    }
    catch {
        Write-Host "✗ Error taking performance snapshot: $_" -ForegroundColor Red
    }
}

# Execute function
Get-PerformanceSnapshot
