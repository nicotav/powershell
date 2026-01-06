#Requires -Version 5.1
<#
.SYNOPSIS
    Resolves DNS for a given hostname and displays results.

.DESCRIPTION
    This standalone snippet resolves DNS for a hostname using Windows DNS
    resolution. Shows all A and AAAA records found.

.PARAMETER Hostname
    The hostname to resolve.

.EXAMPLE
    Get-DNSResolution -Hostname "google.com"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Get-DNSResolution.ps1')
#>

function Get-DNSResolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Hostname
    )

    try {
        Write-Host "Resolving DNS for $Hostname..." -ForegroundColor Cyan
        Write-Host ""

        $results = Resolve-DnsName -Name $Hostname -ErrorAction Stop
        
        if ($results) {
            Write-Host "✓ DNS resolution successful" -ForegroundColor Green
            Write-Host ""
            
            foreach ($result in $results) {
                Write-Host "Type: $($result.Type)" -ForegroundColor Magenta
                if ($result.Type -eq "A" -or $result.Type -eq "AAAA") {
                    Write-Host "  IP Address: $($result.IPAddress)" -ForegroundColor Green
                } elseif ($result.Type -eq "CNAME") {
                    Write-Host "  Canonical Name: $($result.NameHost)" -ForegroundColor Green
                } elseif ($result.Type -eq "MX") {
                    Write-Host "  Mail Server: $($result.NameExchange)" -ForegroundColor Green
                }
                Write-Host "  TTL: $($result.TTL) seconds" -ForegroundColor Gray
                Write-Host ""
            }
        }
    }
    catch {
        Write-Host "✗ DNS resolution failed: $_" -ForegroundColor Red
    }
}

# Interactive mode - show common hostnames
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          DNS RESOLUTION TESTER                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Common hostnames to resolve:" -ForegroundColor Cyan
Write-Host "  1. google.com" -ForegroundColor Gray
Write-Host "  2. microsoft.com" -ForegroundColor Gray
Write-Host "  3. github.com" -ForegroundColor Gray
Write-Host "  4. $env:COMPUTERNAME (local machine)" -ForegroundColor Gray
Write-Host "  5. Custom hostname..." -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Select option (1-5)"
$Hostname = switch ($choice) {
    "1" { "google.com" }
    "2" { "microsoft.com" }
    "3" { "github.com" }
    "4" { $env:COMPUTERNAME }
    "5" { Read-Host "Enter hostname to resolve" }
    default { Read-Host "Enter hostname to resolve" }
}

if ($Hostname) {
    Write-Host ""
    Get-DNSResolution -Hostname $Hostname
} else {
    Write-Host "No hostname provided. Exiting." -ForegroundColor Yellow
}
