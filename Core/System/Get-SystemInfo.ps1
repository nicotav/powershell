#Requires -Version 5.1
<#
.SYNOPSIS
    Retrieves comprehensive system information.

.DESCRIPTION
    This standalone snippet gathers and displays key system information
    including OS, hardware, and network configuration.

.EXAMPLE
    Get-SystemInfo

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Get-SystemInfo.ps1')
#>

function Get-SystemInfo {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Gathering system information..." -ForegroundColor Cyan
        Write-Host ""

        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        $proc = Get-CimInstance -ClassName Win32_Processor
        $ram = Get-CimInstance -ClassName Win32_PhysicalMemory

        Write-Host "OPERATING SYSTEM" -ForegroundColor Yellow
        Write-Host "  Name: $($os.Caption)" -ForegroundColor Green
        Write-Host "  Version: $($os.Version)" -ForegroundColor Green
        Write-Host "  Build: $($os.BuildNumber)" -ForegroundColor Green
        Write-Host "  Installation Date: $([datetime]::ParseExact($os.InstallDate.Substring(0,8), 'yyyyMMdd', $null))" -ForegroundColor Green
        Write-Host ""

        Write-Host "COMPUTER" -ForegroundColor Yellow
        Write-Host "  Name: $($cs.Name)" -ForegroundColor Green
        Write-Host "  Domain: $($cs.Domain)" -ForegroundColor Green
        Write-Host "  Manufacturer: $($cs.Manufacturer)" -ForegroundColor Green
        Write-Host "  Model: $($cs.Model)" -ForegroundColor Green
        Write-Host ""

        Write-Host "PROCESSOR" -ForegroundColor Yellow
        Write-Host "  Name: $($proc[0].Name)" -ForegroundColor Green
        Write-Host "  Cores: $($proc[0].NumberOfCores)" -ForegroundColor Green
        Write-Host "  Logical Processors: $($proc[0].NumberOfLogicalProcessors)" -ForegroundColor Green
        Write-Host ""

        Write-Host "MEMORY" -ForegroundColor Yellow
        $totalRAM = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
        Write-Host "  Total RAM: $([math]::Round($totalRAM, 2)) GB" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "✗ Error gathering system info: $_" -ForegroundColor Red
    }
}

# Execute function
Get-SystemInfo
