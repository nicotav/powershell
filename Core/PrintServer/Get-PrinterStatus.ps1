#Requires -Version 5.1
#Requires -Modules PrintManagement
<#
.SYNOPSIS
    Gets print server and printer status information.

.DESCRIPTION
    Retrieves printer configuration, queue status, and job statistics.

.PARAMETER ComputerName
    Print server name (default: localhost).

.EXAMPLE
    Get-PrinterStatus -ComputerName "printserver01"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/PrintServer/Get-PrinterStatus.ps1')

    Requires: PrintManagement module, Administrator privileges
#>

function Get-PrinterStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "✗ This script requires Administrator privileges" -ForegroundColor Red
            return
        }

        if (-not (Get-Module -ListAvailable -Name PrintManagement)) {
            Write-Host "✗ PrintManagement module not found" -ForegroundColor Red
            Write-Host "  Install Print and Document Services management tools" -ForegroundColor Yellow
            return
        }

        Import-Module PrintManagement -ErrorAction Stop

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          PRINT SERVER STATUS                               ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Connecting to print server: $ComputerName" -ForegroundColor Yellow
        Write-Host ""

        # Get Printers
        $printers = Get-Printer -ComputerName $ComputerName

        foreach ($printer in $printers) {
            $statusColor = if ($printer.PrinterStatus -eq 'Normal') { 'Green' } else { 'Red' }
            $shareColor = if ($printer.Shared) { 'Green' } else { 'Gray' }

            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "Printer Name:      $($printer.Name)" -ForegroundColor Green
            Write-Host "Status:            $($printer.PrinterStatus)" -ForegroundColor $statusColor
            Write-Host "Driver:            $($printer.DriverName)" -ForegroundColor Gray
            Write-Host "Port:              $($printer.PortName)" -ForegroundColor Cyan
            Write-Host "Shared:            $($printer.Shared)" -ForegroundColor $shareColor
            if ($printer.Shared) {
                Write-Host "Share Name:        $($printer.ShareName)" -ForegroundColor Cyan
            }
            Write-Host "Location:          $($printer.Location)" -ForegroundColor Gray
            Write-Host "Comment:           $($printer.Comment)" -ForegroundColor DarkGray
            Write-Host ""

            # Print Queue
            $jobs = Get-PrintJob -ComputerName $ComputerName -PrinterName $printer.Name -ErrorAction SilentlyContinue
            if ($jobs) {
                Write-Host "PRINT QUEUE: ($($jobs.Count) jobs)" -ForegroundColor Yellow
                foreach ($job in $jobs | Select-Object -First 5) {
                    Write-Host "  • Job $($job.Id): $($job.DocumentName)" -ForegroundColor Cyan
                    Write-Host "    User:          $($job.UserName)" -ForegroundColor Gray
                    Write-Host "    Status:        $($job.JobStatus)" -ForegroundColor $(if($job.JobStatus -eq 'Normal'){'Green'}else{'Yellow'})
                    Write-Host "    Pages:         $($job.TotalPages)" -ForegroundColor Gray
                    Write-Host ""
                }
                if ($jobs.Count -gt 5) {
                    Write-Host "  ... and $($jobs.Count - 5) more jobs" -ForegroundColor DarkGray
                    Write-Host ""
                }
            } else {
                Write-Host "PRINT QUEUE: Empty" -ForegroundColor Green
                Write-Host ""
            }
        }

        # Summary
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        $totalJobs = (Get-PrintJob -ComputerName $ComputerName -ErrorAction SilentlyContinue).Count
        $normalPrinters = ($printers | Where-Object { $_.PrinterStatus -eq 'Normal' }).Count
        $sharedPrinters = ($printers | Where-Object { $_.Shared }).Count

        Write-Host "  Total Printers:  $($printers.Count)" -ForegroundColor White
        Write-Host "  Normal Status:   $normalPrinters" -ForegroundColor Green
        Write-Host "  Issues:          $($printers.Count - $normalPrinters)" -ForegroundColor $(if($printers.Count -eq $normalPrinters){'Green'}else{'Red'})
        Write-Host "  Shared:          $sharedPrinters" -ForegroundColor Cyan
        Write-Host "  Total Jobs:      $totalJobs" -ForegroundColor White
        Write-Host ""

        # Quick Actions
        if ($totalJobs -gt 0) {
            Write-Host "Quick Actions:" -ForegroundColor Cyan
            Write-Host "1. Clear all print jobs" -ForegroundColor Gray
            Write-Host "2. Restart print spooler" -ForegroundColor Gray
            Write-Host "0. Exit" -ForegroundColor Gray
            Write-Host ""

            $action = Read-Host "Select action (0-2)"
            
            switch ($action) {
                "1" {
                    Write-Host ""
                    $confirm = Read-Host "Clear all jobs on all printers? (Y/N)"
                    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                        foreach ($printer in $printers) {
                            Get-PrintJob -ComputerName $ComputerName -PrinterName $printer.Name | Remove-PrintJob
                        }
                        Write-Host "✓ All print jobs cleared" -ForegroundColor Green
                    }
                }
                "2" {
                    Restart-Service Spooler
                    Write-Host "✓ Print spooler restarted" -ForegroundColor Green
                }
            }
        }

    }
    catch {
        Write-Host "✗ Error retrieving printer status: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          PRINT SERVER STATUS                               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$server = Read-Host "Enter print server name (or press Enter for localhost)"
if (-not $server) {
    $server = $env:COMPUTERNAME
}

Get-PrinterStatus -ComputerName $server
