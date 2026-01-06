#Requires -Version 5.1
<#
.SYNOPSIS
    Tests basic network connectivity to a target host.

.DESCRIPTION
    This standalone snippet tests connectivity to a specified target host
    and optional port. Perfect for quick network diagnostics.

.PARAMETER Target
    The hostname or IP address to test.

.PARAMETER Port
    Optional port number to test TCP connectivity.

.EXAMPLE
    Test-NetworkConnectivity -Target "google.com"
    Test-NetworkConnectivity -Target "192.168.1.1" -Port 443

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Test-NetworkConnectivity.ps1')
#>

function Test-NetworkConnectivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $false)]
        [int]$Port
    )

    try {
        Write-Host "Testing connectivity to $Target..." -ForegroundColor Cyan

        # Test ICMP ping
        $ping = Test-Connection -ComputerName $Target -Count 1 -ErrorAction Stop
        Write-Host "✓ ICMP ping successful" -ForegroundColor Green
        Write-Host "  Response time: $($ping.ResponseTime)ms" -ForegroundColor Green

        # Test TCP port if specified
        if ($Port) {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $result = $tcpClient.BeginConnect($Target, $Port, $null, $null)
            $success = $result.AsyncWaitHandle.WaitOne(3000, $false)

            if ($success) {
                Write-Host "✓ TCP port $Port is open" -ForegroundColor Green
            } else {
                Write-Host "✗ TCP port $Port is closed or unreachable" -ForegroundColor Red
            }

            $tcpClient.Close()
        }
    }
    catch {
        Write-Host "✗ Connection failed: $_" -ForegroundColor Red
    }
}

# Interactive mode - show common targets
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          NETWORK CONNECTIVITY TEST                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Common targets to test:" -ForegroundColor Cyan
Write-Host "  1. google.com (Internet connectivity)" -ForegroundColor Gray
Write-Host "  2. 8.8.8.8 (Google DNS)" -ForegroundColor Gray
Write-Host "  3. 1.1.1.1 (Cloudflare DNS)" -ForegroundColor Gray
Write-Host "  4. 127.0.0.1 (Localhost)" -ForegroundColor Gray
Write-Host "  5. Default gateway" -ForegroundColor Gray
Write-Host "  6. Custom target..." -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Select option (1-6)"
$Target = switch ($choice) {
    "1" { "google.com" }
    "2" { "8.8.8.8" }
    "3" { "1.1.1.1" }
    "4" { "127.0.0.1" }
    "5" { 
        $gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object -First 1).NextHop
        if ($gw) { $gw } else { Read-Host "No gateway found. Enter target" }
    }
    "6" { Read-Host "Enter target host (hostname or IP)" }
    default { Read-Host "Enter target host (hostname or IP)" }
}

Write-Host ""
$portInput = Read-Host "Enter port number (leave blank for ping only)"

if ($Target) {
    Write-Host ""
    if ($portInput) {
        Test-NetworkConnectivity -Target $Target -Port ([int]$portInput)
    } else {
        Test-NetworkConnectivity -Target $Target
    }
} else {
    Write-Host "No target provided. Exiting." -ForegroundColor Yellow
}
