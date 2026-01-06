#Requires -Version 5.1
<#
.SYNOPSIS
    Lists all members of an Active Directory group.

.DESCRIPTION
    This standalone snippet displays all members of an AD group including
    nested group memberships.

.PARAMETER GroupName
    The name of the AD group to query.

.PARAMETER Recursive
    Include members from nested groups.

.EXAMPLE
    Get-ADGroupMembers -GroupName "Domain Admins"
    Get-ADGroupMembers -GroupName "IT Team" -Recursive

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/Get-ADGroupMembers.ps1')

    Requires: Active Directory PowerShell module
    Requires: Appropriate AD permissions
#>

function Get-ADGroupMembers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupName,

        [Parameter(Mandatory = $false)]
        [switch]$Recursive
    )

    try {
        # Check if AD module is available
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Host "✗ Active Directory module not found" -ForegroundColor Red
            Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
            return
        }

        Import-Module ActiveDirectory -ErrorAction Stop

        Write-Host "Retrieving members of group: $GroupName..." -ForegroundColor Cyan
        Write-Host ""

        # Get group object
        $group = Get-ADGroup -Identity $GroupName -Properties * -ErrorAction Stop

        # Group Information
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GROUP INFORMATION                                 ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Group Name:        $($group.Name)" -ForegroundColor Green
        Write-Host "Description:       $($group.Description)" -ForegroundColor Gray
        Write-Host "Group Scope:       $($group.GroupScope)" -ForegroundColor Gray
        Write-Host "Group Category:    $($group.GroupCategory)" -ForegroundColor Gray
        Write-Host "Created:           $($group.Created)" -ForegroundColor Gray
        Write-Host ""

        # Get members
        if ($Recursive) {
            $members = Get-ADGroupMember -Identity $GroupName -Recursive | Sort-Object Name
        } else {
            $members = Get-ADGroupMember -Identity $GroupName | Sort-Object Name
        }

        # Display members
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          GROUP MEMBERS ($($members.Count))                              " -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        if ($members) {
            $users = @()
            $groups = @()
            $computers = @()

            foreach ($member in $members) {
                switch ($member.objectClass) {
                    'user' { $users += $member }
                    'group' { $groups += $member }
                    'computer' { $computers += $member }
                }
            }

            if ($users) {
                Write-Host "USERS ($($users.Count)):" -ForegroundColor Yellow
                foreach ($user in $users) {
                    Write-Host "  • $($user.Name) ($($user.SamAccountName))" -ForegroundColor Green
                }
                Write-Host ""
            }

            if ($groups) {
                Write-Host "NESTED GROUPS ($($groups.Count)):" -ForegroundColor Yellow
                foreach ($grp in $groups) {
                    Write-Host "  • $($grp.Name)" -ForegroundColor Cyan
                }
                Write-Host ""
            }

            if ($computers) {
                Write-Host "COMPUTERS ($($computers.Count)):" -ForegroundColor Yellow
                foreach ($comp in $computers) {
                    Write-Host "  • $($comp.Name)" -ForegroundColor Magenta
                }
                Write-Host ""
            }
        } else {
            Write-Host "No members found in this group." -ForegroundColor Gray
            Write-Host ""
        }

    }
    catch {
        Write-Host "✗ Error retrieving group members: $_" -ForegroundColor Red
    }
}

# Interactive mode - show available groups
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          ACTIVE DIRECTORY GROUP MEMBERS                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if AD module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "✗ Active Directory module not found" -ForegroundColor Red
    Write-Host "  Install RSAT tools to use this script" -ForegroundColor Yellow
    exit
}

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

Write-Host "Fetching AD groups..." -ForegroundColor Yellow
try {
    # Show common groups first
    Write-Host ""
    Write-Host "Common groups to inspect:" -ForegroundColor Cyan
    Write-Host "  1. Domain Admins" -ForegroundColor Gray
    Write-Host "  2. Enterprise Admins" -ForegroundColor Gray
    Write-Host "  3. Domain Users" -ForegroundColor Gray
    Write-Host "  4. Domain Computers" -ForegroundColor Gray
    Write-Host "  5. List all groups..." -ForegroundColor Gray
    Write-Host "  0. Enter custom group name..." -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option (0-5)"
    
    if ($choice -eq "0") {
        $groupName = Read-Host "Enter group name"
    } elseif ($choice -eq "5") {
        $allGroups = Get-ADGroup -Filter * | Sort-Object Name | Select-Object -First 30
        Write-Host ""
        Write-Host "Select a group (showing first 30):" -ForegroundColor Cyan
        $allGroups | ForEach-Object -Begin { $i = 1 } -Process {
            Write-Host "  $i. $($_.Name)" -ForegroundColor Gray
            $i++
        }
        Write-Host ""
        $groupChoice = Read-Host "Select group number"
        if ($groupChoice -match '^\d+$' -and [int]$groupChoice -ge 1 -and [int]$groupChoice -le 30) {
            $groupName = ($allGroups)[[int]$groupChoice - 1].Name
        } else {
            $groupName = $groupChoice
        }
    } else {
        $groupName = switch ($choice) {
            "1" { "Domain Admins" }
            "2" { "Enterprise Admins" }
            "3" { "Domain Users" }
            "4" { "Domain Computers" }
            default { Read-Host "Enter group name" }
        }
    }

    if ($groupName) {
        Write-Host ""
        $recursive = Read-Host "Include nested groups? (y/n)"
        if ($recursive -eq 'y') {
            Get-ADGroupMembers -GroupName $groupName -Recursive
        } else {
            Get-ADGroupMembers -GroupName $groupName
        }
    } else {
        Write-Host "No group name provided. Exiting." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
}
