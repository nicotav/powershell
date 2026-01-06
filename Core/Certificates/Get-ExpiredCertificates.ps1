#Requires -Version 5.1
<#
.SYNOPSIS
    Finds and reports on expiring or expired certificates.

.DESCRIPTION
    Scans certificate stores for certificates that are expired or expiring soon.

.PARAMETER DaysToExpire
    Number of days to look ahead for expiring certificates (default: 30).

.PARAMETER StoreLocation
    Certificate store location: CurrentUser or LocalMachine (default: LocalMachine).

.EXAMPLE
    Get-ExpiredCertificates -DaysToExpire 60

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Certificates/Get-ExpiredCertificates.ps1')

    Requires: Administrator privileges for LocalMachine store
#>

function Get-ExpiredCertificates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$DaysToExpire = 30,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$StoreLocation = 'LocalMachine'
    )

    try {
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          CERTIFICATE EXPIRATION CHECK                      ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Scanning $StoreLocation certificate stores..." -ForegroundColor Yellow
        Write-Host "Looking for certificates expiring within $DaysToExpire days" -ForegroundColor Yellow
        Write-Host ""

        $expiryDate = (Get-Date).AddDays($DaysToExpire)
        $stores = @('My', 'Root', 'CA', 'TrustedPublisher', 'WebHosting')
        $expiredCerts = @()
        $expiringSoonCerts = @()

        foreach ($storeName in $stores) {
            try {
                $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, $StoreLocation)
                $store.Open('ReadOnly')
                
                foreach ($cert in $store.Certificates) {
                    if ($cert.NotAfter -lt (Get-Date)) {
                        $expiredCerts += [PSCustomObject]@{
                            Subject      = $cert.Subject
                            Issuer       = $cert.Issuer
                            Thumbprint   = $cert.Thumbprint
                            NotBefore    = $cert.NotBefore
                            NotAfter     = $cert.NotAfter
                            Store        = $storeName
                            DaysOverdue  = ((Get-Date) - $cert.NotAfter).Days
                        }
                    }
                    elseif ($cert.NotAfter -lt $expiryDate) {
                        $expiringSoonCerts += [PSCustomObject]@{
                            Subject      = $cert.Subject
                            Issuer       = $cert.Issuer
                            Thumbprint   = $cert.Thumbprint
                            NotBefore    = $cert.NotBefore
                            NotAfter     = $cert.NotAfter
                            Store        = $storeName
                            DaysRemaining = ($cert.NotAfter - (Get-Date)).Days
                        }
                    }
                }
                
                $store.Close()
            }
            catch {
                Write-Host "  ⚠ Unable to access $storeName store: $_" -ForegroundColor Yellow
            }
        }

        # Expired Certificates
        if ($expiredCerts.Count -gt 0) {
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
            Write-Host "EXPIRED CERTIFICATES: $($expiredCerts.Count)" -ForegroundColor Red
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
            Write-Host ""

            foreach ($cert in $expiredCerts | Sort-Object DaysOverdue -Descending) {
                Write-Host "Subject:           $($cert.Subject)" -ForegroundColor Red
                Write-Host "  Issuer:          $($cert.Issuer)" -ForegroundColor Gray
                Write-Host "  Expired:         $($cert.NotAfter)" -ForegroundColor Red
                Write-Host "  Days Overdue:    $($cert.DaysOverdue)" -ForegroundColor Red
                Write-Host "  Store:           $($cert.Store)" -ForegroundColor Gray
                Write-Host "  Thumbprint:      $($cert.Thumbprint)" -ForegroundColor DarkGray
                Write-Host ""
            }
        } else {
            Write-Host "✓ No expired certificates found" -ForegroundColor Green
            Write-Host ""
        }

        # Expiring Soon
        if ($expiringSoonCerts.Count -gt 0) {
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
            Write-Host "EXPIRING SOON: $($expiringSoonCerts.Count)" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
            Write-Host ""

            foreach ($cert in $expiringSoonCerts | Sort-Object DaysRemaining) {
                $warningColor = if ($cert.DaysRemaining -le 7) { 'Red' } elseif ($cert.DaysRemaining -le 14) { 'Yellow' } else { 'Gray' }
                
                Write-Host "Subject:           $($cert.Subject)" -ForegroundColor White
                Write-Host "  Issuer:          $($cert.Issuer)" -ForegroundColor Gray
                Write-Host "  Expires:         $($cert.NotAfter)" -ForegroundColor $warningColor
                Write-Host "  Days Remaining:  $($cert.DaysRemaining)" -ForegroundColor $warningColor
                Write-Host "  Store:           $($cert.Store)" -ForegroundColor Gray
                Write-Host "  Thumbprint:      $($cert.Thumbprint)" -ForegroundColor DarkGray
                Write-Host ""
            }
        } else {
            Write-Host "✓ No certificates expiring within $DaysToExpire days" -ForegroundColor Green
            Write-Host ""
        }

        # Summary
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        Write-Host "  Expired:         $($expiredCerts.Count)" -ForegroundColor Red
        Write-Host "  Expiring Soon:   $($expiringSoonCerts.Count)" -ForegroundColor Yellow
        Write-Host "  Store Location:  $StoreLocation" -ForegroundColor Gray
        Write-Host ""

        # Export option
        if ($expiredCerts.Count -gt 0 -or $expiringSoonCerts.Count -gt 0) {
            $export = Read-Host "Export results to CSV? (Y/N)"
            if ($export -eq 'Y' -or $export -eq 'y') {
                $exportPath = "$env:USERPROFILE\Desktop\CertificateReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
                $allCerts = $expiredCerts + $expiringSoonCerts
                $allCerts | Export-Csv -Path $exportPath -NoTypeInformation
                Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
            }
        }

    }
    catch {
        Write-Host "✗ Error checking certificates: $_" -ForegroundColor Red
    }
}

# Interactive mode
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          CERTIFICATE EXPIRATION CHECK                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. LocalMachine store (30 days)" -ForegroundColor Gray
Write-Host "2. LocalMachine store (60 days)" -ForegroundColor Gray
Write-Host "3. LocalMachine store (90 days)" -ForegroundColor Gray
Write-Host "4. CurrentUser store (30 days)" -ForegroundColor Gray
Write-Host "5. Custom" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Select option (1-5)"

switch ($choice) {
    "1" { Get-ExpiredCertificates -DaysToExpire 30 -StoreLocation LocalMachine }
    "2" { Get-ExpiredCertificates -DaysToExpire 60 -StoreLocation LocalMachine }
    "3" { Get-ExpiredCertificates -DaysToExpire 90 -StoreLocation LocalMachine }
    "4" { Get-ExpiredCertificates -DaysToExpire 30 -StoreLocation CurrentUser }
    "5" {
        $days = Read-Host "Enter days to look ahead"
        $location = Read-Host "Enter store location (CurrentUser/LocalMachine)"
        Get-ExpiredCertificates -DaysToExpire $days -StoreLocation $location
    }
    default {
        Get-ExpiredCertificates
    }
}
