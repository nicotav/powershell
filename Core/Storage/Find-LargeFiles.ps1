#Requires -Version 5.1
<#
.SYNOPSIS
    Finds large files in a specified path.

.DESCRIPTION
    This standalone snippet recursively searches a directory for large files
    and displays them sorted by size.

.PARAMETER Path
    The path to search. Required.

.PARAMETER MinSizeMB
    Minimum file size in megabytes. Default: 100

.PARAMETER TopN
    Number of results to return. Default: 20

.EXAMPLE
    Find-LargeFiles -Path "C:\Users"
    Find-LargeFiles -Path "C:\Windows\Temp" -MinSizeMB 50 -TopN 10

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Storage/Find-LargeFiles.ps1')
#>

function Find-LargeFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$MinSizeMB = 100,

        [Parameter(Mandatory = $false)]
        [int]$TopN = 20
    )

    try {
        Write-Host "Searching for large files in $Path..." -ForegroundColor Cyan
        Write-Host "(Minimum size: $MinSizeMB MB)" -ForegroundColor Gray
        Write-Host ""

        if (-not (Test-Path $Path)) {
            Write-Host "✗ Path not found: $Path" -ForegroundColor Red
            return
        }

        $minBytes = $MinSizeMB * 1MB
        $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
                 Where-Object { $_.Length -gt $minBytes } |
                 Sort-Object -Property Length -Descending |
                 Select-Object -First $TopN

        if ($files) {
            Write-Host "✓ Found $($files.Count) files larger than $MinSizeMB MB" -ForegroundColor Green
            Write-Host ""

            $files | ForEach-Object {
                $sizeMB = [math]::Round($_.Length / 1MB, 2)
                $lastWrite = $_.LastWriteTime
                Write-Host "$($_.Name)" -ForegroundColor Magenta
                Write-Host "  Size: $sizeMB MB" -ForegroundColor Green
                Write-Host "  Path: $($_.FullName)" -ForegroundColor Gray
                Write-Host "  Modified: $lastWrite" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "✓ No files found larger than $MinSizeMB MB" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Error searching for large files: $_" -ForegroundColor Red
    }
}

# Interactive mode - show context first
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          LARGE FILES FINDER                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Show available drives
Write-Host "Available drives:" -ForegroundColor Yellow
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
foreach ($drive in $drives) {
    $usedGB = [math]::Round($drive.Used / 1GB, 2)
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Host "  $($drive.Name):\ - Used: $usedGB GB, Free: $freeGB GB" -ForegroundColor Gray
}
Write-Host ""

# Show common search locations
Write-Host "Common locations to search:" -ForegroundColor Cyan
Write-Host "  1. C:\Users\$env:USERNAME\Downloads" -ForegroundColor Gray
Write-Host "  2. C:\Users\$env:USERNAME" -ForegroundColor Gray
Write-Host "  3. C:\Windows\Temp" -ForegroundColor Gray
Write-Host "  4. C:\Temp" -ForegroundColor Gray
Write-Host "  5. Custom path..." -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Select option (1-5)"
$targetPath = switch ($choice) {
    "1" { "C:\Users\$env:USERNAME\Downloads" }
    "2" { "C:\Users\$env:USERNAME" }
    "3" { "C:\Windows\Temp" }
    "4" { "C:\Temp" }
    "5" { Read-Host "Enter custom path" }
    default { Read-Host "Enter path to search" }
}

if ($targetPath -and (Test-Path $targetPath)) {
    Write-Host ""
    Find-LargeFiles -Path $targetPath
} elseif ($targetPath) {
    Write-Host "Path not found: $targetPath" -ForegroundColor Red
} else {
    Write-Host "No path provided. Exiting." -ForegroundColor Yellow
}
