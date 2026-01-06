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

# Execute function with user input
$Target = Read-Host "Enter target host (hostname or IP)"
$portInput = Read-Host "Enter port number (leave blank to skip)"

if ($portInput) {
    Test-NetworkConnectivity -Target $Target -Port ([int]$portInput)
} else {
    Test-NetworkConnectivity -Target $Target
}
