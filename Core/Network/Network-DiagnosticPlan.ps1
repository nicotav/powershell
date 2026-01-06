#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive network diagnostic plan combining multiple tools.

.DESCRIPTION
    This diagnostic plan runs a series of network tests in logical order:
    1. Basic connectivity test to common hosts
    2. DNS resolution checks
    3. Firewall status verification
    4. Summary report

.PARAMETER TestTarget
    Optional target host to test. Defaults to google.com

.EXAMPLE
    Network-DiagnosticPlan
    Network-DiagnosticPlan -TestTarget "192.168.1.1"

.NOTES
    This is a standalone diagnostic plan. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Network-DiagnosticPlan.ps1')
#>

# Define all functions needed for this plan
function Test-NetworkConnectivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $false)]
        [int]$Port
    )

    try {
        $ping = Test-Connection -ComputerName $Target -Count 1 -ErrorAction Stop
        Write-Host "✓ $Target - Response: $($ping.ResponseTime)ms" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ $Target - No response" -ForegroundColor Red
        return $false
    }
}

function Get-DNSResolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Hostname
    )

    try {
        $results = Resolve-DnsName -Name $Hostname -ErrorAction Stop
        foreach ($result in $results) {
            if ($result.Type -eq "A" -or $result.Type -eq "AAAA") {
                Write-Host "✓ $Hostname resolves to $($result.IPAddress)" -ForegroundColor Green
                return $true
            }
        }
    }
    catch {
        Write-Host "✗ $Hostname - DNS resolution failed" -ForegroundColor Red
        return $false
    }
}

function Get-FirewallStatus {
    [CmdletBinding()]
    param()

    try {
        $profiles = Get-NetFirewallProfile
        $allEnabled = $true

        foreach ($fwProfile in $profiles) {
            if ($fwProfile.Enabled) {
                Write-Host "✓ $($fwProfile.Name) profile - ENABLED" -ForegroundColor Green
            } else {
                Write-Host "⚠ $($fwProfile.Name) profile - DISABLED" -ForegroundColor Yellow
                $allEnabled = $false
            }
        }
        return $allEnabled
    }
    catch {
        Write-Host "✗ Error checking firewall" -ForegroundColor Red
        return $false
    }
}

# Main diagnostic plan
function Network-DiagnosticPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TestTarget = "google.com"
    )

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          NETWORK DIAGNOSTIC PLAN                           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Basic connectivity
    Write-Host "STEP 1: Testing Basic Connectivity" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    $localTest = Test-NetworkConnectivity -Target "127.0.0.1"
    $externalTest = Test-NetworkConnectivity -Target $TestTarget
    Write-Host ""

    # Step 2: DNS Resolution
    Write-Host "STEP 2: Testing DNS Resolution" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    $dnsTest = Get-DNSResolution -Hostname $TestTarget
    Write-Host ""

    # Step 3: Firewall Status
    Write-Host "STEP 3: Checking Firewall Status" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Yellow
    $firewallTest = Get-FirewallStatus
    Write-Host ""

    # Summary
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DIAGNOSTIC SUMMARY                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Local Connectivity:        $(if ($localTest) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($localTest) { 'Green' } else { 'Red' })
    Write-Host "External Connectivity:     $(if ($externalTest) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($externalTest) { 'Green' } else { 'Red' })
    Write-Host "DNS Resolution:            $(if ($dnsTest) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($dnsTest) { 'Green' } else { 'Red' })
    Write-Host "Firewall Status:           $(if ($firewallTest) { '✓ PASS' } else { '⚠ WARN' })" -ForegroundColor $(if ($firewallTest) { 'Green' } else { 'Yellow' })
    Write-Host ""
}

# Execute diagnostic plan
Network-DiagnosticPlan
