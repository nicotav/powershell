#Requires -Version 5.1
<#
.SYNOPSIS
    Gets the dependency tree for a Windows service.

.DESCRIPTION
    This standalone snippet displays all services that depend on a specified
    service, and all services it depends on.

.PARAMETER ServiceName
    The name of the service to analyze. Required.

.EXAMPLE
    Get-ServiceDependencies -ServiceName "Spooler"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Get-ServiceDependencies.ps1')
#>

function Get-ServiceDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )

    try {
        Write-Host "Analyzing dependencies for: $ServiceName..." -ForegroundColor Cyan
        Write-Host ""

        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        
        Write-Host "SERVICE DETAILS" -ForegroundColor Yellow
        Write-Host "  Display Name: $($service.DisplayName)" -ForegroundColor Green
        Write-Host "  Status: $($service.Status)" -ForegroundColor Green
        Write-Host ""

        # Services it depends on
        $dependencies = Get-Service -Name $ServiceName -DependentServices
        if ($dependencies) {
            Write-Host "SERVICES THAT DEPEND ON THIS:" -ForegroundColor Yellow
            foreach ($dep in $dependencies) {
                $statusColor = if ($dep.Status -eq 'Running') { 'Green' } else { 'Red' }
                Write-Host "  • $($dep.DisplayName) ($($dep.Status))" -ForegroundColor $statusColor
            }
        } else {
            Write-Host "SERVICES THAT DEPEND ON THIS:" -ForegroundColor Yellow
            Write-Host "  None" -ForegroundColor Gray
        }
        Write-Host ""

        # Services it depends on
        $serviceObj = Get-Service -Name $ServiceName
        $requiredServices = $serviceObj.RequiredServices
        if ($requiredServices) {
            Write-Host "SERVICES THIS ONE DEPENDS ON:" -ForegroundColor Yellow
            foreach ($req in $requiredServices) {
                $statusColor = if ($req.Status -eq 'Running') { 'Green' } else { 'Red' }
                Write-Host "  • $($req.DisplayName) ($($req.Status))" -ForegroundColor $statusColor
            }
        } else {
            Write-Host "SERVICES THIS ONE DEPENDS ON:" -ForegroundColor Yellow
            Write-Host "  None" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "✗ Error analyzing dependencies: $_" -ForegroundColor Red
    }
}

# Get service name from user
$serviceName = Read-Host "Enter service name"
if ($serviceName) {
    Get-ServiceDependencies -ServiceName $serviceName
}
