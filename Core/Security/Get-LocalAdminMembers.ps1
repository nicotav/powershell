#Requires -Version 5.1
<#
.SYNOPSIS
    Lists all members of the local Administrators group.

.DESCRIPTION
    This standalone snippet displays all user accounts and groups that are
    members of the local Administrators group.

.EXAMPLE
    Get-LocalAdminMembers

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Get-LocalAdminMembers.ps1')
#>

function Get-LocalAdminMembers {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Enumerating local Administrators group..." -ForegroundColor Cyan
        Write-Host ""

        $adminGroup = [ADSI]"WinNT://./Administrators"
        $members = @()

        foreach ($member in $adminGroup.psbase.Invoke("Members")) {
            $name = $member.GetType().InvokeMember("Name", 'GetProperty', $null, $member, $null)
            $members += $name
        }

        Write-Host "✓ Found $($members.Count) local administrator accounts:" -ForegroundColor Green
        Write-Host ""

        foreach ($member in $members) {
            Write-Host "  • $member" -ForegroundColor Magenta
        }

        Write-Host ""
        if ($members.Count -gt 5) {
            Write-Host "⚠ Large number of administrators detected" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "✗ Error enumerating administrators: $_" -ForegroundColor Red
    }
}

# Execute function
Get-LocalAdminMembers
