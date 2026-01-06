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

# Get path from user if not provided
$targetPath = Read-Host "Enter path to search"
if ($targetPath) {
    Find-LargeFiles -Path $targetPath
}
