#Requires -Version 5.1
<#
.SYNOPSIS
    Retrieves recent error events from Windows Event Logs.

.DESCRIPTION
    This standalone snippet fetches and displays error events from specified
    Windows Event Log within a given timeframe.

.PARAMETER LogName
    The event log name (System, Application, Security). Default: System

.PARAMETER Hours
    Number of hours to look back. Default: 24

.EXAMPLE
    Get-EventLogErrors
    Get-EventLogErrors -LogName "Application" -Hours 48

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Get-EventLogErrors.ps1')
#>

function Get-EventLogErrors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("System", "Application", "Security")]
        [string]$LogName = "System",

        [Parameter(Mandatory = $false)]
        [int]$Hours = 24
    )

    try {
        Write-Host "Retrieving errors from $LogName log (last $Hours hours)..." -ForegroundColor Cyan
        Write-Host ""

        $cutoffTime = (Get-Date).AddHours(-$Hours)
        $errors = Get-EventLog -LogName $LogName -After $cutoffTime -EntryType Error -ErrorAction Stop

        if ($errors) {
            Write-Host "✓ Found $($errors.Count) error events" -ForegroundColor Green
            Write-Host ""

            $errors | Select-Object -First 20 | ForEach-Object {
                Write-Host "Time: $($_.TimeGenerated)" -ForegroundColor Magenta
                Write-Host "  Source: $($_.Source)" -ForegroundColor Gray
                Write-Host "  EventID: $($_.EventID)" -ForegroundColor Gray
                Write-Host "  Message: $($_.Message.Substring(0, [math]::Min(100, $_.Message.Length)))..." -ForegroundColor Yellow
                Write-Host ""
            }

            if ($errors.Count -gt 20) {
                Write-Host "... and $($errors.Count - 20) more errors" -ForegroundColor Gray
            }
        } else {
            Write-Host "✓ No errors found in the last $Hours hours" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Error retrieving event logs: $_" -ForegroundColor Red
    }
}

# Execute function
Get-EventLogErrors
