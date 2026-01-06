#Requires -Version 5.1
<#
.SYNOPSIS
    Analyzes SharePoint Online site permissions and access.

.DESCRIPTION
    Retrieves and analyzes permissions for SharePoint sites including
    sharing links, external users, and permission inheritance.

.PARAMETER SiteUrl
    The URL of the SharePoint site to analyze.

.EXAMPLE
    Get-SharePointSitePermissions -SiteUrl "https://contoso.sharepoint.com/sites/TeamSite"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Microsoft365/Get-SharePointSitePermissions.ps1')

    Requires: PnP.PowerShell module
    Requires: SharePoint admin permissions
#>

function Get-SharePointSitePermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SiteUrl
    )

    try {
        if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
            Write-Host "✗ PnP.PowerShell module not found" -ForegroundColor Red
            Write-Host "  Install with: Install-Module PnP.PowerShell -Scope CurrentUser" -ForegroundColor Yellow
            return
        }

        Import-Module PnP.PowerShell -ErrorAction Stop

        Write-Host "Connecting to SharePoint site..." -ForegroundColor Yellow
        Connect-PnPOnline -Url $SiteUrl -Interactive

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SHAREPOINT SITE PERMISSIONS                       ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $site = Get-PnPSite -Includes Owner
        $web = Get-PnPWeb

        Write-Host "Site Title:        $($web.Title)" -ForegroundColor Green
        Write-Host "Site URL:          $($web.Url)" -ForegroundColor Cyan
        Write-Host "Owner:             $($site.Owner.Email)" -ForegroundColor Gray
        Write-Host ""

        # Site Permissions
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SITE PERMISSIONS                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $roleAssignments = Get-PnPProperty -ClientObject $web -Property RoleAssignments
        Get-PnPProperty -ClientObject $roleAssignments -Property Member, RoleDefinitionBindings

        foreach ($assignment in $roleAssignments) {
            $member = $assignment.Member
            $roles = $assignment.RoleDefinitionBindings

            Write-Host "Principal:         $($member.Title)" -ForegroundColor Yellow
            Write-Host "  Type:            $($member.PrincipalType)" -ForegroundColor Gray
            Write-Host "  Permissions:     $($roles.Name -join ', ')" -ForegroundColor Gray
            Write-Host ""
        }

        # External Sharing
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          EXTERNAL SHARING                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $sharingCapability = $site.SharingCapability
        $sharingColor = switch ($sharingCapability) {
            'Disabled' { 'Green' }
            'ExternalUserSharingOnly' { 'Yellow' }
            'ExternalUserAndGuestSharing' { 'Red' }
            'ExistingExternalUserSharingOnly' { 'Yellow' }
            default { 'Gray' }
        }

        Write-Host "Sharing Capability: $sharingCapability" -ForegroundColor $sharingColor
        Write-Host ""

        # Sharing Links
        Write-Host "Analyzing sharing links..." -ForegroundColor Yellow
        $lists = Get-PnPList
        $externalLinks = @()

        foreach ($list in $lists) {
            try {
                $items = Get-PnPListItem -List $list -PageSize 500 -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    $links = Get-PnPFileSharingLink -Identity $item -ErrorAction SilentlyContinue
                    if ($links) {
                        $externalLinks += $links
                    }
                }
            } catch {}
        }

        if ($externalLinks) {
            Write-Host "Found $($externalLinks.Count) sharing links" -ForegroundColor Yellow
        } else {
            Write-Host "No sharing links found" -ForegroundColor Green
        }
        Write-Host ""

        # Export option
        $export = Read-Host "Export permissions to CSV? (Y/N)"
        if ($export -eq 'Y' -or $export -eq 'y') {
            $exportPath = "$env:USERPROFILE\Desktop\SPO_Permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            $roleAssignments | Select-Object @{N='Principal';E={$_.Member.Title}}, 
                                              @{N='Type';E={$_.Member.PrincipalType}},
                                              @{N='Roles';E={$_.RoleDefinitionBindings.Name -join '; '}} |
                Export-Csv -Path $exportPath -NoTypeInformation
            Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
        }

        Disconnect-PnPOnline

    }
    catch {
        Write-Host "✗ Error retrieving SharePoint permissions: $_" -ForegroundColor Red
    }
}

# Interactive mode
$siteUrl = Read-Host "Enter SharePoint site URL"
if ($siteUrl) {
    Get-SharePointSitePermissions -SiteUrl $siteUrl
}
