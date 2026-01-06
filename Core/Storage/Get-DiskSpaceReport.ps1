#Requires -Version 5.1
<#
.SYNOPSIS
    Generates a disk space usage report for all drives.

.DESCRIPTION
    This standalone snippet displays disk usage information for all drives
    and highlights those exceeding a warning threshold.

.PARAMETER ThresholdPercent
    Warning threshold percentage for low disk space. Default: 20

.EXAMPLE
    Get-DiskSpaceReport
    Get-DiskSpaceReport -ThresholdPercent 10

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Storage/Get-DiskSpaceReport.ps1')
#>

function Get-DiskSpaceReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$ThresholdPercent = 20
    )

    try {
        Write-Host "Generating disk space report..." -ForegroundColor Cyan
        Write-Host ""

        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:' }

        foreach ($drive in $drives) {
            $total = $drive.Used + $drive.Free
            $percent = [math]::Round(($drive.Used / $total) * 100, 2)
            $freeGB = [math]::Round($drive.Free / 1GB, 2)

            $color = if ($percent -gt (100 - $ThresholdPercent)) { 'Red' } elseif ($percent -gt 80) { 'Yellow' } else { 'Green' }

            Write-Host "Drive $($drive.Name): $percent% used ($freeGB GB free)" -ForegroundColor $color

            # Create progress bar
            $barLength = 30
            $filledLength = [int]($barLength * $percent / 100)
            $bar = "█" * $filledLength + "░" * ($barLength - $filledLength)
            Write-Host "  [$bar]" -ForegroundColor $color
            Write-Host ""
        }
    }
    catch {
        Write-Host "✗ Error generating disk report: $_" -ForegroundColor Red
    }
}

# Execute function
Get-DiskSpaceReport
