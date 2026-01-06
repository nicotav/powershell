#Requires -Version 5.1
<#
.SYNOPSIS
    Clears temporary files from common locations.

.DESCRIPTION
    This standalone snippet safely removes temporary files from Windows
    temp folders and user temp directories.

.EXAMPLE
    Clear-TempFiles

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Storage/Clear-TempFiles.ps1')

    Requires administrator privileges.
#>

function Clear-TempFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {
        Write-Host "Clearing temporary files..." -ForegroundColor Cyan
        Write-Host ""

        $tempPaths = @(
            $env:TEMP,
            $env:TMP,
            "C:\Windows\Temp"
        )

        $totalFreed = 0

        foreach ($tempPath in $tempPaths) {
            if (Test-Path $tempPath) {
                Write-Host "Processing: $tempPath" -ForegroundColor Yellow
                
                try {
                    $files = Get-ChildItem -Path $tempPath -File -Recurse -ErrorAction SilentlyContinue
                    $itemsDeleted = 0

                    foreach ($file in $files) {
                        try {
                            if ($PSCmdlet.ShouldProcess($file.FullName, "Delete")) {
                                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                                $totalFreed += $file.Length
                                $itemsDeleted++
                            }
                        }
                        catch {
                            # File may be in use, skip it
                        }
                    }

                    Write-Host "  ✓ Deleted $itemsDeleted files" -ForegroundColor Green
                }
                catch {
                    Write-Host "  ✗ Error processing directory: $_" -ForegroundColor Red
                }
            }
        }

        Write-Host ""
        Write-Host "✓ Total space freed: $([math]::Round($totalFreed / 1MB, 2)) MB" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error clearing temp files: $_" -ForegroundColor Red
    }
}

# Execute function
Clear-TempFiles
