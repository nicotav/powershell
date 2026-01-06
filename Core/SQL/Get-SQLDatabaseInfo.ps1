#Requires -Version 5.1
<#
.SYNOPSIS
    Gets detailed information about a SQL Server database.

.DESCRIPTION
    Retrieves database properties, size, files, backup history, and performance metrics.

.PARAMETER ServerInstance
    SQL Server instance name.

.PARAMETER DatabaseName
    Database name to analyze.

.EXAMPLE
    Get-SQLDatabaseInfo -ServerInstance "localhost" -DatabaseName "AdventureWorks"

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/SQL/Get-SQLDatabaseInfo.ps1')

    Requires: SqlServer PowerShell module
#>

function Get-SQLDatabaseInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseName
    )

    try {
        if (-not (Get-Module -ListAvailable -Name SqlServer)) {
            Write-Host "✗ SqlServer module not found" -ForegroundColor Red
            Write-Host "  Install with: Install-Module SqlServer -Scope CurrentUser" -ForegroundColor Yellow
            return
        }

        Import-Module SqlServer -ErrorAction Stop

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SQL DATABASE INFORMATION                          ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        # Database Info
        $db = Get-SqlDatabase -ServerInstance $ServerInstance -Name $DatabaseName

        Write-Host "Database Name:     $($db.Name)" -ForegroundColor Green
        Write-Host "Server:            $ServerInstance" -ForegroundColor Cyan
        Write-Host "Status:            $($db.Status)" -ForegroundColor $(if($db.Status -eq 'Normal'){'Green'}else{'Yellow'})
        Write-Host "Recovery Model:    $($db.RecoveryModel)" -ForegroundColor Gray
        Write-Host "Compatibility:     $($db.CompatibilityLevel)" -ForegroundColor Gray
        Write-Host "Owner:             $($db.Owner)" -ForegroundColor Gray
        Write-Host "Created:           $($db.CreateDate)" -ForegroundColor DarkGray
        Write-Host ""

        # Size Information
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SIZE INFORMATION                                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $sizeQuery = "SELECT 
            SUM(size) * 8 / 1024 AS TotalSizeMB,
            SUM(CASE WHEN type = 0 THEN size ELSE 0 END) * 8 / 1024 AS DataSizeMB,
            SUM(CASE WHEN type = 1 THEN size ELSE 0 END) * 8 / 1024 AS LogSizeMB
            FROM sys.database_files"
        
        $sizeInfo = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $sizeQuery

        Write-Host "Total Size:        $($sizeInfo.TotalSizeMB) MB" -ForegroundColor White
        Write-Host "Data Size:         $($sizeInfo.DataSizeMB) MB" -ForegroundColor Yellow
        Write-Host "Log Size:          $($sizeInfo.LogSizeMB) MB" -ForegroundColor Yellow
        Write-Host ""

        # Backup History
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          BACKUP HISTORY                                    ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""

        $backupQuery = "SELECT TOP 5
            type, backup_start_date, backup_finish_date,
            backup_size/1024/1024 AS BackupSizeMB
            FROM msdb.dbo.backupset
            WHERE database_name = '$DatabaseName'
            ORDER BY backup_start_date DESC"
        
        $backups = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database "msdb" -Query $backupQuery

        if ($backups) {
            foreach ($backup in $backups) {
                $backupType = switch ($backup.type) {
                    'D' { 'Full' }
                    'I' { 'Differential' }
                    'L' { 'Log' }
                    default { $backup.type }
                }
                Write-Host "Type:              $backupType" -ForegroundColor Yellow
                Write-Host "  Start:           $($backup.backup_start_date)" -ForegroundColor Gray
                Write-Host "  Size:            $([math]::Round($backup.BackupSizeMB, 2)) MB" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "⚠ No backup history found!" -ForegroundColor Red
        }

        # Table Count
        $tableQuery = "SELECT COUNT(*) AS TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'"
        $tableCount = (Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $tableQuery).TableCount
        Write-Host "Total Tables:      $tableCount" -ForegroundColor White
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving database info: $_" -ForegroundColor Red
    }
}

# Interactive mode
$server = Read-Host "Enter SQL Server instance (e.g., localhost or localhost\SQLEXPRESS)"
$database = Read-Host "Enter database name"

if ($server -and $database) {
    Get-SQLDatabaseInfo -ServerInstance $server -DatabaseName $database
}
