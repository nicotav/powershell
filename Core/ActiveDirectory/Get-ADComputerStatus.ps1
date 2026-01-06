#Requires -Version 5.1
<#
.SYNOPSIS
    Gets status information for Active Directory computer accounts.

.DESCRIPTION
    This standalone snippet retrieves computer account information including
    online status, OS version, last logon, and location.

.PARAMETER ComputerName
    The name of the computer to query. If not specified, shows recent computers.

.EXAMPLE
    Get-ADComputerStatus -ComputerName "WKS-001"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/Get-ADComputerStatus.ps1')

    Requires: Active Directory PowerShell module
    Requires: Appropriate AD permissions
#>

function Get-ADComputerStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    try {
        # Check if AD module is available
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Host "✗ Active Directory module not found" -ForegroundColor Red
            Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
            return
        }

        Import-Module ActiveDirectory -ErrorAction Stop

        Write-Host "Retrieving information for computer: $ComputerName..." -ForegroundColor Cyan
        Write-Host ""

        # Get computer object
        $computer = Get-ADComputer -Identity $ComputerName -Properties * -ErrorAction Stop

        # Basic Information
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          COMPUTER INFORMATION                              ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Computer Name:     $($computer.Name)" -ForegroundColor Green
        Write-Host "DNS Name:          $($computer.DNSHostName)" -ForegroundColor Green
        Write-Host "Operating System:  $($computer.OperatingSystem)" -ForegroundColor Gray
        Write-Host "OS Version:        $($computer.OperatingSystemVersion)" -ForegroundColor Gray
        Write-Host "Description:       $($computer.Description)" -ForegroundColor Gray
        Write-Host ""

        # Account Status
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          ACCOUNT STATUS                                    ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $enabledColor = if ($computer.Enabled) { 'Green' } else { 'Red' }
        $enabledStatus = if ($computer.Enabled) { "✓ Enabled" } else { "✗ Disabled" }
        Write-Host "Status:            $enabledStatus" -ForegroundColor $enabledColor
        
        Write-Host "Created:           $($computer.Created)" -ForegroundColor Gray
        Write-Host "Modified:          $($computer.Modified)" -ForegroundColor Gray
        Write-Host "Last Logon:        $($computer.LastLogonDate)" -ForegroundColor Gray
        Write-Host "Password Last Set: $($computer.PasswordLastSet)" -ForegroundColor Gray
        Write-Host ""

        # Test online status
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          CONNECTIVITY STATUS                               ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Testing connectivity..." -ForegroundColor Yellow
        
        $ping = Test-Connection -ComputerName $computer.DNSHostName -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($ping) {
            Write-Host "✓ Computer is ONLINE" -ForegroundColor Green
        } else {
            Write-Host "✗ Computer is OFFLINE or unreachable" -ForegroundColor Red
        }
        Write-Host ""

        # Location Information
        if ($computer.Location) {
            Write-Host "Location:          $($computer.Location)" -ForegroundColor Gray
        }

    }
    catch {
        Write-Host "✗ Error retrieving computer information: $_" -ForegroundColor Red
    }
}

# Interactive mode - show available computers
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          ACTIVE DIRECTORY COMPUTER STATUS                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if AD module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "✗ Active Directory module not found" -ForegroundColor Red
    Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
    exit
}

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

Write-Host "Fetching AD computers..." -ForegroundColor Yellow
try {
    $recentComputers = Get-ADComputer -Filter * -Properties LastLogonDate, OperatingSystem | 
                       Where-Object { $_.LastLogonDate } | 
                       Sort-Object LastLogonDate -Descending | 
                       Select-Object -First 20

    Write-Host ""
    Write-Host "Select a computer to inspect (showing 20 most recently logged on):" -ForegroundColor Cyan
    $recentComputers | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "  $i. $($_.Name) - $($_.OperatingSystem)" -ForegroundColor Gray
        $i++
    }
    Write-Host "  0. Enter custom computer name..." -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option (0-20)"
    if ($choice -eq "0") {
        $computerName = Read-Host "Enter computer name"
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 20) {
        $computerName = ($recentComputers)[[int]$choice - 1].Name
    } else {
        $computerName = $choice
    }

    if ($computerName) {
        Write-Host ""
        Get-ADComputerStatus -ComputerName $computerName
    } else {
        Write-Host "No computer name provided. Exiting." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error fetching computers: $_" -ForegroundColor Red
    Write-Host ""
    $computerName = Read-Host "Enter computer name directly"
    if ($computerName) {
        Get-ADComputerStatus -ComputerName $computerName
    }
}
