#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive system diagnostic plan combining multiple tools.

.DESCRIPTION
    This diagnostic plan runs a series of system health checks in logical order:
    1. System information
    2. System uptime
    3. Performance snapshot
    4. Event log analysis
    5. Summary report

.EXAMPLE
    Start-SystemDiagnosticPlan

.NOTES
    This is a standalone diagnostic plan. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/System-DiagnosticPlan.ps1')
#>

# Define all functions needed for this plan
function Get-SystemInfo {
    [CmdletBinding()]
    param()

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem

    Write-Host "OS: $($os.Caption) (Build $($os.BuildNumber))" -ForegroundColor Green
    Write-Host "Computer: $($cs.Name)" -ForegroundColor Green
}

function Get-SystemUptime {
    [CmdletBinding()]
    param()

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $uptime = (Get-Date) - ([datetime]$os.LastBootUpTime)

    Write-Host "Last Boot: $($os.LastBootUpTime)" -ForegroundColor Green
    Write-Host "Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Green
}

function Get-PerformanceSnapshot {
    [CmdletBinding()]
    param()

    $cpuUsage = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty LoadPercentage
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $memPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    Write-Host "CPU: $cpuUsage%" -ForegroundColor Green
    Write-Host "Memory: $memPercent%" -ForegroundColor Green
}

function Get-EventLogErrors {
    [CmdletBinding()]
    param()

    $cutoffTime = (Get-Date).AddHours(-24)
    $errors = Get-EventLog -LogName System -After $cutoffTime -EntryType Error -ErrorAction SilentlyContinue

    Write-Host "System Errors (24h): $($errors.Count) events" -ForegroundColor $(if ($errors.Count -eq 0) { 'Green' } else { 'Yellow' })
}

# Main diagnostic plan
function Start-SystemDiagnosticPlan {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          SYSTEM DIAGNOSTIC PLAN                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "STEP 1: System Information" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    Get-SystemInfo
    Write-Host ""

    Write-Host "STEP 2: System Uptime" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    Get-SystemUptime
    Write-Host ""

    Write-Host "STEP 3: Performance Snapshot" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    Get-PerformanceSnapshot
    Write-Host ""

    Write-Host "STEP 4: Event Log Analysis" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    Get-EventLogErrors
    Write-Host ""

    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DIAGNOSTIC COMPLETE                               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Execute diagnostic plan
Start-SystemDiagnosticPlan
