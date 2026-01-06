#Requires -Version 5.1
<#
.SYNOPSIS
    Gets effective permissions for a user on a specified path.

.DESCRIPTION
    This standalone snippet displays effective NTFS permissions for a user
    on a specified file or folder.

.PARAMETER Path
    The file or folder path to check. Required.

.PARAMETER Username
    The username to check permissions for. Defaults to current user.

.EXAMPLE
    Get-UserPermissions -Path "C:\Program Files"
    Get-UserPermissions -Path "C:\Shared" -Username "DOMAIN\User"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Get-UserPermissions.ps1')
#>

function Get-UserPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Username = $env:USERNAME
    )

    try {
        Write-Host "Checking permissions for $Username on $Path..." -ForegroundColor Cyan
        Write-Host ""

        if (-not (Test-Path $Path)) {
            Write-Host "✗ Path not found: $Path" -ForegroundColor Red
            return
        }

        $acl = Get-Acl -Path $Path
        $access = $acl.Access | Where-Object { $_.IdentityReference -match $Username }

        if ($access) {
            Write-Host "✓ Found permissions for $($Username):" -ForegroundColor Green
            Write-Host ""

            foreach ($rule in $access) {
                Write-Host "Permission: $($rule.FileSystemRights)" -ForegroundColor Magenta
                Write-Host "  Access Type: $($rule.AccessControlType)" -ForegroundColor Gray
                Write-Host "  Inheritance: $($rule.IsInherited)" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "⚠ No explicit permissions found for $Username" -ForegroundColor Yellow
            Write-Host "User may have inherited permissions from parent directories." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "✗ Error checking permissions: $_" -ForegroundColor Red
    }
}

# Interactive mode - show context first
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          USER PERMISSIONS CHECK                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Show current user
Write-Host "Current User: $env:USERDOMAIN\$env:USERNAME" -ForegroundColor Yellow
Write-Host ""

# Show common paths to check
Write-Host "Common paths to check:" -ForegroundColor Cyan
Write-Host "  1. C:\Program Files" -ForegroundColor Gray
Write-Host "  2. C:\Windows" -ForegroundColor Gray
Write-Host "  3. C:\Users\$env:USERNAME" -ForegroundColor Gray
Write-Host "  4. C:\ProgramData" -ForegroundColor Gray
Write-Host "  5. Custom path..." -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Select option (1-5)"
$path = switch ($choice) {
    "1" { "C:\Program Files" }
    "2" { "C:\Windows" }
    "3" { "C:\Users\$env:USERNAME" }
    "4" { "C:\ProgramData" }
    "5" { Read-Host "Enter custom path" }
    default { Read-Host "Enter path to check" }
}

if ($path -and (Test-Path $path)) {
    Write-Host ""
    Get-UserPermissions -Path $path
} elseif ($path) {
    Write-Host "Path not found: $path" -ForegroundColor Red
} else {
    Write-Host "No path provided. Exiting." -ForegroundColor Yellow
}
