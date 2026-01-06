#Requires -Version 5.1
<#
.SYNOPSIS
    Checks the current password policy settings.

.DESCRIPTION
    This standalone snippet displays password policy settings for the local
    system or domain.

.EXAMPLE
    Test-PasswordPolicy

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Test-PasswordPolicy.ps1')
#>

function Test-PasswordPolicy {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Checking password policy..." -ForegroundColor Cyan
        Write-Host ""

        # Try to get domain policy first
        $isDomain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
        
        if ($isDomain) {
            Write-Host "Domain Password Policy:" -ForegroundColor Yellow
            try {
                $domainPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop
                Write-Host "  Minimum Password Length: $($domainPolicy.MinPasswordLength) characters" -ForegroundColor Green
                Write-Host "  Password History: $($domainPolicy.PasswordHistoryCount) previous passwords" -ForegroundColor Green
                Write-Host "  Maximum Password Age: $($domainPolicy.MaxPasswordAge.Days) days" -ForegroundColor Green
                Write-Host "  Account Lockout Duration: $($domainPolicy.LockoutDuration.Minutes) minutes" -ForegroundColor Green
            }
            catch {
                Write-Host "  Unable to retrieve domain policy" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Local Password Policy:" -ForegroundColor Yellow
            try {
                $policy = Get-LocalUser
                Write-Host "  Local User Accounts: $($policy.Count)" -ForegroundColor Green
                
                $expiredAccounts = $policy | Where-Object { $_.PasswordExpires -lt (Get-Date) }
                if ($expiredAccounts) {
                    Write-Host "  ✗ Accounts with expired passwords: $($expiredAccounts.Count)" -ForegroundColor Red
                } else {
                    Write-Host "  ✓ No accounts with expired passwords" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  Unable to retrieve policy" -ForegroundColor Yellow
            }
        }

        Write-Host ""
    }
    catch {
        Write-Host "✗ Error checking password policy: $_" -ForegroundColor Red
    }
}

# Execute function
Test-PasswordPolicy
