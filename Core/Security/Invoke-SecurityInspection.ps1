#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Comprehensive security inspection and system snapshot tool for anomaly detection.

.DESCRIPTION
    This standalone script captures a complete security snapshot of the system including:
    - System information and configuration
    - Network connections and listening ports
    - Running processes and services
    - Startup items and scheduled tasks
    - User accounts and group memberships
    - Installed software and drivers
    - Security settings and policies
    - Recent system events and errors
    - File system permissions and shares
    - Registry security settings

.EXAMPLE
    Invoke-SecurityInspection

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Invoke-SecurityInspection.ps1')

    Requires: Administrator privileges
    Output: Console + HTML report
#>

function Invoke-SecurityInspection {
    [CmdletBinding()]
    param()

    $startTime = Get-Date
    $reportPath = "$env:USERPROFILE\Desktop\SecurityInspection_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $findings = @()
    $anomalies = @()

    function Add-Finding {
        param(
            [string]$Category,
            [string]$Item,
            [string]$Status,
            [string]$Details,
            [string]$Risk = "Info"
        )
        
        $script:findings += [PSCustomObject]@{
            Category = $Category
            Item = $Item
            Status = $Status
            Details = $Details
            Risk = $Risk
        }
    }

    function Add-Anomaly {
        param(
            [string]$Type,
            [string]$Description,
            [string]$Severity = "Medium"
        )
        
        $script:anomalies += [PSCustomObject]@{
            Type = $Type
            Description = $Description
            Severity = $Severity
        }
    }

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          SECURITY INSPECTION & FIRST AID                   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Starting comprehensive security snapshot..." -ForegroundColor Yellow
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 1: System Information
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ System Information" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $bios = Get-CimInstance -ClassName Win32_BIOS
        
        Write-Host "  Computer Name:     $($computerSystem.Name)" -ForegroundColor White
        Write-Host "  Domain:            $($computerSystem.Domain)" -ForegroundColor White
        Write-Host "  OS:                $($os.Caption) $($os.Version)" -ForegroundColor White
        Write-Host "  Build:             $($os.BuildNumber)" -ForegroundColor White
        Write-Host "  Install Date:      $($os.InstallDate)" -ForegroundColor White
        Write-Host "  Last Boot:         $($os.LastBootUpTime)" -ForegroundColor White
        Write-Host "  BIOS Version:      $($bios.SMBIOSBIOSVersion)" -ForegroundColor White
        Write-Host "  Secure Boot:       $(if ((Confirm-SecureBootUEFI -ErrorAction SilentlyContinue)) { '✓ Enabled' } else { '✗ Disabled' })" -ForegroundColor $(if ((Confirm-SecureBootUEFI -ErrorAction SilentlyContinue)) { 'Green' } else { 'Yellow' })
        
        Add-Finding -Category "System" -Item "Computer Name" -Status "OK" -Details $computerSystem.Name
        Add-Finding -Category "System" -Item "Operating System" -Status "OK" -Details "$($os.Caption) $($os.Version)"
        
        # Check for suspicious system names
        if ($computerSystem.Name -match "^(PC|DESKTOP|WIN|LAPTOP)-[A-Z0-9]{6,}$") {
            Add-Anomaly -Type "System" -Description "Computer has default/generic name: $($computerSystem.Name)" -Severity "Low"
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving system info: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 2: Security Software Status
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Security Software Status" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        
        if ($defender) {
            $avEnabled = $defender.AntivirusEnabled
            $rtpEnabled = $defender.RealTimeProtectionEnabled
            $definitionAge = (Get-Date) - $defender.AntivirusSignatureLastUpdated
            
            Write-Host "  Windows Defender:  $(if ($avEnabled) { '✓ Enabled' } else { '✗ Disabled' })" -ForegroundColor $(if ($avEnabled) { 'Green' } else { 'Red' })
            Write-Host "  Real-Time:         $(if ($rtpEnabled) { '✓ Enabled' } else { '✗ Disabled' })" -ForegroundColor $(if ($rtpEnabled) { 'Green' } else { 'Red' })
            Write-Host "  Definitions:       $($defender.AntivirusSignatureLastUpdated) (Age: $($definitionAge.Days) days)" -ForegroundColor $(if ($definitionAge.Days -lt 7) { 'Green' } else { 'Yellow' })
            Write-Host "  Last Scan:         $($defender.LastQuickScanEndTime)" -ForegroundColor White
            
            Add-Finding -Category "Security" -Item "Windows Defender" -Status $(if ($avEnabled) { "Enabled" } else { "Disabled" }) -Details "RT: $rtpEnabled, Defs: $($definitionAge.Days) days old"
            
            if (-not $avEnabled) {
                Add-Anomaly -Type "Security" -Description "Windows Defender is disabled" -Severity "High"
            }
            if (-not $rtpEnabled) {
                Add-Anomaly -Type "Security" -Description "Real-time protection is disabled" -Severity "High"
            }
            if ($definitionAge.Days -gt 7) {
                Add-Anomaly -Type "Security" -Description "Antivirus definitions are outdated ($($definitionAge.Days) days)" -Severity "Medium"
            }
        }
        
        # Firewall Status
        $firewallProfiles = Get-NetFirewallProfile
        foreach ($profile in $firewallProfiles) {
            $status = if ($profile.Enabled) { '✓ Enabled' } else { '✗ Disabled' }
            $color = if ($profile.Enabled) { 'Green' } else { 'Red' }
            Write-Host "  Firewall ($($profile.Name)):$((' ' * (11 - $profile.Name.Length)))$status" -ForegroundColor $color
            
            Add-Finding -Category "Security" -Item "Firewall $($profile.Name)" -Status $(if ($profile.Enabled) { "Enabled" } else { "Disabled" })
            
            if (-not $profile.Enabled) {
                Add-Anomaly -Type "Security" -Description "Firewall profile '$($profile.Name)' is disabled" -Severity "High"
            }
        }
        
        # UAC Status
        $uacValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA).EnableLUA
        Write-Host "  UAC:               $(if ($uacValue -eq 1) { '✓ Enabled' } else { '✗ Disabled' })" -ForegroundColor $(if ($uacValue -eq 1) { 'Green' } else { 'Red' })
        
        if ($uacValue -ne 1) {
            Add-Anomaly -Type "Security" -Description "User Account Control (UAC) is disabled" -Severity "High"
        }
    }
    catch {
        Write-Host "  ⚠ Error checking security software: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 3: Network Connections
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Active Network Connections" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $connections = Get-NetTCPConnection -State Established, Listen | 
                       Where-Object { $_.LocalAddress -ne '::1' -and $_.LocalAddress -ne '127.0.0.1' } |
                       Select-Object -First 20
        
        Write-Host "  Total Active Connections: $($connections.Count)" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($conn in $connections) {
            try {
                $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                $processName = if ($process) { $process.Name } else { "Unknown" }
                
                $statusColor = if ($conn.State -eq 'Listen') { 'Yellow' } else { 'White' }
                Write-Host "  [$($conn.State)] $($conn.LocalAddress):$($conn.LocalPort) → $($conn.RemoteAddress):$($conn.RemotePort) [$processName]" -ForegroundColor $statusColor
                
                Add-Finding -Category "Network" -Item "Connection" -Status $conn.State -Details "$($conn.LocalAddress):$($conn.LocalPort) → $($conn.RemoteAddress):$($conn.RemotePort) [$processName]"
                
                # Check for suspicious connections
                if ($conn.RemotePort -in @(4444, 5555, 6666, 31337) -and $conn.State -eq 'Established') {
                    Add-Anomaly -Type "Network" -Description "Suspicious connection to uncommon port $($conn.RemotePort) by $processName" -Severity "High"
                }
            }
            catch { }
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving network connections: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 4: Running Processes
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Running Processes (Top 20 by Memory)" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $processes = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 20
        
        foreach ($proc in $processes) {
            $memMB = [math]::Round($proc.WorkingSet / 1MB, 2)
            $company = if ($proc.Company) { $proc.Company } else { "Unknown" }
            
            $color = 'White'
            if ($company -eq "Unknown" -and $memMB -gt 100) {
                $color = 'Yellow'
                Add-Anomaly -Type "Process" -Description "Process '$($proc.Name)' has no company info and uses $memMB MB" -Severity "Low"
            }
            
            Write-Host "  $($proc.Name.PadRight(30)) | PID: $($proc.Id.ToString().PadRight(6)) | Mem: $($memMB.ToString().PadLeft(8)) MB | $company" -ForegroundColor $color
            
            Add-Finding -Category "Process" -Item $proc.Name -Status "Running" -Details "PID: $($proc.Id), Mem: $memMB MB, Company: $company"
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving processes: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 5: Services (Non-Standard Running)
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Non-Standard Running Services" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $services = Get-Service | Where-Object { 
            $_.Status -eq 'Running' -and 
            $_.DisplayName -notmatch '^(Windows|Microsoft|Defender|Security)' 
        } | Sort-Object DisplayName | Select-Object -First 20
        
        foreach ($svc in $services) {
            Write-Host "  • $($svc.DisplayName) ($($svc.Name))" -ForegroundColor White
            Add-Finding -Category "Service" -Item $svc.Name -Status "Running" -Details $svc.DisplayName
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving services: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 6: Startup Items
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Startup Items" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $startupLocations = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
        )
        
        foreach ($location in $startupLocations) {
            try {
                $items = Get-ItemProperty -Path $location -ErrorAction SilentlyContinue
                if ($items) {
                    $items.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                        Write-Host "  • $($_.Name): $($_.Value)" -ForegroundColor White
                        Add-Finding -Category "Startup" -Item $_.Name -Status "Enabled" -Details $_.Value
                        
                        # Check for suspicious startup items
                        if ($_.Value -match '(temp|appdata\\local\\temp|public\\)' -or $_.Value -match '\.(bat|cmd|vbs|ps1)$') {
                            Add-Anomaly -Type "Startup" -Description "Suspicious startup item: $($_.Name) → $($_.Value)" -Severity "Medium"
                        }
                    }
                }
            }
            catch { }
        }
        
        # Check Startup folder
        $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        if (Test-Path $startupFolder) {
            $startupFiles = Get-ChildItem -Path $startupFolder -ErrorAction SilentlyContinue
            foreach ($file in $startupFiles) {
                Write-Host "  • [Startup Folder] $($file.Name)" -ForegroundColor White
                Add-Finding -Category "Startup" -Item $file.Name -Status "Enabled" -Details "Startup folder"
            }
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving startup items: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 7: Scheduled Tasks (User-Created)
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ User-Created Scheduled Tasks" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $tasks = Get-ScheduledTask | Where-Object { 
            $_.TaskPath -notmatch '^\\Microsoft\\' -and 
            $_.State -ne 'Disabled' 
        } | Select-Object -First 15
        
        foreach ($task in $tasks) {
            $actions = $task.Actions | Select-Object -First 1
            Write-Host "  • $($task.TaskName) [$($task.State)]" -ForegroundColor White
            Write-Host "    Path: $($task.TaskPath)" -ForegroundColor Gray
            if ($actions.Execute) {
                Write-Host "    Exec: $($actions.Execute) $($actions.Arguments)" -ForegroundColor Gray
                
                # Check for suspicious tasks
                if ($actions.Execute -match '(powershell|cmd|wscript|cscript)' -and $actions.Arguments -match '(hidden|bypass|encoded)') {
                    Add-Anomaly -Type "Task" -Description "Suspicious scheduled task: $($task.TaskName) executes $($actions.Execute) $($actions.Arguments)" -Severity "High"
                }
            }
            
            Add-Finding -Category "Task" -Item $task.TaskName -Status $task.State -Details "Path: $($task.TaskPath), Exec: $($actions.Execute)"
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving scheduled tasks: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 8: User Accounts
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Local User Accounts" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $users = Get-LocalUser
        
        foreach ($user in $users) {
            $statusColor = if ($user.Enabled) { 'Green' } else { 'Gray' }
            $status = if ($user.Enabled) { '✓' } else { '✗' }
            
            Write-Host "  $status $($user.Name.PadRight(25)) | Enabled: $($user.Enabled) | Last Logon: $($user.LastLogon)" -ForegroundColor $statusColor
            
            Add-Finding -Category "User" -Item $user.Name -Status $(if ($user.Enabled) { "Enabled" } else { "Disabled" }) -Details "Last Logon: $($user.LastLogon)"
            
            # Check for suspicious accounts
            if ($user.Enabled -and $user.Name -match '^(admin|root|test|guest)' -and $user.Name -ne 'Administrator') {
                Add-Anomaly -Type "User" -Description "Suspicious enabled user account: $($user.Name)" -Severity "Medium"
            }
        }
        
        # Local Administrators
        Write-Host ""
        Write-Host "  Local Administrators:" -ForegroundColor Yellow
        $admins = Get-LocalGroupMember -Group "Administrators"
        foreach ($admin in $admins) {
            Write-Host "    • $($admin.Name)" -ForegroundColor White
            Add-Finding -Category "User" -Item "Admin: $($admin.Name)" -Status "Member" -Details "Local Administrators group"
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving user accounts: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 9: Installed Software
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Recently Installed Software (Last 30 days)" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $cutoffDate = (Get-Date).AddDays(-30)
        
        $software = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -and $_.InstallDate } |
                    ForEach-Object {
                        try {
                            $installDate = [datetime]::ParseExact($_.InstallDate, 'yyyyMMdd', $null)
                            if ($installDate -gt $cutoffDate) {
                                [PSCustomObject]@{
                                    Name = $_.DisplayName
                                    Version = $_.DisplayVersion
                                    Publisher = $_.Publisher
                                    InstallDate = $installDate
                                }
                            }
                        } catch { }
                    } | Sort-Object InstallDate -Descending | Select-Object -First 15
        
        foreach ($app in $software) {
            Write-Host "  • $($app.Name) v$($app.Version)" -ForegroundColor White
            Write-Host "    Publisher: $($app.Publisher) | Installed: $($app.InstallDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
            
            Add-Finding -Category "Software" -Item $app.Name -Status "Installed" -Details "Version: $($app.Version), Publisher: $($app.Publisher), Date: $($app.InstallDate)"
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving software: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 10: Network Shares
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Network Shares" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $shares = Get-SmbShare | Where-Object { $_.Name -notmatch '^(ADMIN\$|C\$|IPC\$)' }
        
        if ($shares) {
            foreach ($share in $shares) {
                Write-Host "  • $($share.Name) → $($share.Path)" -ForegroundColor White
                Add-Finding -Category "Share" -Item $share.Name -Status "Shared" -Details "Path: $($share.Path)"
                
                # Check for risky shares
                if ($share.Name -match '^C$' -or $share.Path -match '^C:\\$') {
                    Add-Anomaly -Type "Share" -Description "Risky share detected: $($share.Name) shares entire drive" -Severity "High"
                }
            }
        } else {
            Write-Host "  No custom shares found" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving shares: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 11: Recent Security Events
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Recent Security Events (Last 24 hours)" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $startDate = (Get-Date).AddDays(-1)
        
        # Failed logon attempts
        $failedLogons = Get-WinEvent -FilterHashtable @{
            LogName='Security'
            ID=4625
            StartTime=$startDate
        } -MaxEvents 10 -ErrorAction SilentlyContinue
        
        if ($failedLogons) {
            Write-Host "  Failed Logon Attempts: $($failedLogons.Count)" -ForegroundColor Yellow
            foreach ($event in $failedLogons) {
                Write-Host "    • $($event.TimeCreated) - $($event.Message.Split("`n")[0])" -ForegroundColor Gray
            }
            
            if ($failedLogons.Count -gt 5) {
                Add-Anomaly -Type "Event" -Description "Multiple failed logon attempts detected ($($failedLogons.Count) in 24h)" -Severity "High"
            }
        } else {
            Write-Host "  No failed logon attempts" -ForegroundColor Green
        }
        
        # Account lockouts
        $lockouts = Get-WinEvent -FilterHashtable @{
            LogName='Security'
            ID=4740
            StartTime=$startDate
        } -MaxEvents 5 -ErrorAction SilentlyContinue
        
        if ($lockouts) {
            Write-Host "  Account Lockouts: $($lockouts.Count)" -ForegroundColor Red
            Add-Anomaly -Type "Event" -Description "Account lockouts detected ($($lockouts.Count) in 24h)" -Severity "High"
        }
    }
    catch {
        Write-Host "  ⚠ Error retrieving security events: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # SECTION 12: Browser Extensions (Chrome)
    # ═══════════════════════════════════════════════════════════
    Write-Host "▼ Browser Extensions (Chrome)" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    try {
        $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
        
        if (Test-Path $chromePath) {
            $extensions = Get-ChildItem -Path $chromePath -Directory | Select-Object -First 15
            
            foreach ($ext in $extensions) {
                Write-Host "  • Extension ID: $($ext.Name)" -ForegroundColor White
                Add-Finding -Category "Browser" -Item "Chrome Extension" -Status "Installed" -Details $ext.Name
            }
        } else {
            Write-Host "  Chrome not installed or no extensions found" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  ⚠ Error checking extensions: $_" -ForegroundColor Red
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # ANOMALY SUMMARY
    # ═══════════════════════════════════════════════════════════
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║          DETECTED ANOMALIES                                ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    
    if ($anomalies.Count -gt 0) {
        $highRisk = ($anomalies | Where-Object { $_.Severity -eq 'High' }).Count
        $mediumRisk = ($anomalies | Where-Object { $_.Severity -eq 'Medium' }).Count
        $lowRisk = ($anomalies | Where-Object { $_.Severity -eq 'Low' }).Count
        
        Write-Host "  Total Anomalies: $($anomalies.Count)" -ForegroundColor Yellow
        Write-Host "    High:   $highRisk" -ForegroundColor Red
        Write-Host "    Medium: $mediumRisk" -ForegroundColor Yellow
        Write-Host "    Low:    $lowRisk" -ForegroundColor White
        Write-Host ""
        
        foreach ($anomaly in $anomalies) {
            $color = switch ($anomaly.Severity) {
                'High' { 'Red' }
                'Medium' { 'Yellow' }
                'Low' { 'White' }
            }
            Write-Host "  [$($anomaly.Severity)] $($anomaly.Type): $($anomaly.Description)" -ForegroundColor $color
        }
    } else {
        Write-Host "  ✓ No anomalies detected" -ForegroundColor Green
    }
    Write-Host ""

    # ═══════════════════════════════════════════════════════════
    # GENERATE HTML REPORT
    # ═══════════════════════════════════════════════════════════
    Write-Host "Generating HTML report..." -ForegroundColor Cyan
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Security Inspection Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        h1 { color: #0078d4; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #2d7d9a; margin-top: 30px; }
        table { width: 100%; border-collapse: collapse; background: white; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background: #0078d4; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f9f9f9; }
        .anomaly-high { background: #ffebee; color: #c62828; font-weight: bold; }
        .anomaly-medium { background: #fff3e0; color: #ef6c00; }
        .anomaly-low { background: #e8f5e9; color: #2e7d32; }
        .summary { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 32px; font-weight: bold; color: #0078d4; }
        .metric-label { color: #666; }
    </style>
</head>
<body>
    <h1>Security Inspection Report</h1>
    <div class="summary">
        <strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>
        <strong>Computer:</strong> $($computerSystem.Name)<br>
        <strong>Duration:</strong> $((Get-Date) - $startTime | Select-Object -ExpandProperty TotalSeconds) seconds<br><br>
        
        <div class="metric">
            <div class="metric-value">$($findings.Count)</div>
            <div class="metric-label">Total Findings</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($anomalies.Count)</div>
            <div class="metric-label">Anomalies</div>
        </div>
    </div>
    
    <h2>Detected Anomalies</h2>
    <table>
        <tr><th>Severity</th><th>Type</th><th>Description</th></tr>
        $(foreach ($anomaly in $anomalies) {
            $class = "anomaly-$($anomaly.Severity.ToLower())"
            "<tr class='$class'><td>$($anomaly.Severity)</td><td>$($anomaly.Type)</td><td>$($anomaly.Description)</td></tr>"
        })
    </table>
    
    <h2>All Findings</h2>
    <table>
        <tr><th>Category</th><th>Item</th><th>Status</th><th>Details</th></tr>
        $(foreach ($finding in $findings) {
            "<tr><td>$($finding.Category)</td><td>$($finding.Item)</td><td>$($finding.Status)</td><td>$($finding.Details)</td></tr>"
        })
    </table>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          INSPECTION COMPLETE                               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Report saved to:" -ForegroundColor Green
    Write-Host "  $reportPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Total Findings: $($findings.Count)" -ForegroundColor Yellow
    Write-Host "Anomalies Detected: $($anomalies.Count)" -ForegroundColor Yellow
    Write-Host ""
    
    $openReport = Read-Host "Open HTML report in browser? (y/n)"
    if ($openReport -eq 'y') {
        Start-Process $reportPath
    }
}

# Execute inspection
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          SECURITY INSPECTION & FIRST AID                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will perform comprehensive security inspection:" -ForegroundColor Yellow
Write-Host "  • System configuration and security status" -ForegroundColor Gray
Write-Host "  • Network connections and listening ports" -ForegroundColor Gray
Write-Host "  • Running processes and services" -ForegroundColor Gray
Write-Host "  • Startup items and scheduled tasks" -ForegroundColor Gray
Write-Host "  • User accounts and group memberships" -ForegroundColor Gray
Write-Host "  • Installed software and recent changes" -ForegroundColor Gray
Write-Host "  • Network shares and permissions" -ForegroundColor Gray
Write-Host "  • Recent security events" -ForegroundColor Gray
Write-Host "  • Anomaly detection and reporting" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠ Administrator privileges required" -ForegroundColor Yellow
Write-Host "⏱ Duration: 2-5 minutes" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Start security inspection? (y/n)"

if ($confirm -eq 'y') {
    Write-Host ""
    Invoke-SecurityInspection
} else {
    Write-Host "Inspection cancelled." -ForegroundColor Yellow
}
