#Requires -Version 5.1
<#
.SYNOPSIS
    Examples and usage guide for PowerShell Troubleshooting Scripts.

.DESCRIPTION
    This script demonstrates how to use individual snippet files from the
    PowerShell troubleshooting repository.

.NOTES
    All snippet files are completely standalone and ready to execute.
    Copy any URL and run: iex (irm 'url')
#>

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     PowerShell Troubleshooting Scripts - Usage Guide        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "NETWORK TROUBLESHOOTING" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Individual Tools:" -ForegroundColor Cyan
Write-Host "  Test-NetworkConnectivity.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Test-NetworkConnectivity.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-DNSResolution.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Get-DNSResolution.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-FirewallStatus.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Get-FirewallStatus.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "Diagnostic Plan (runs all together):" -ForegroundColor Cyan
Write-Host "  Network-DiagnosticPlan.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Network/Network-DiagnosticPlan.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "SYSTEM DIAGNOSTICS" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Individual Tools:" -ForegroundColor Cyan
Write-Host "  Get-SystemInfo.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Get-SystemInfo.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-EventLogErrors.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Get-EventLogErrors.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-SystemUptime.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Get-SystemUptime.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-PerformanceSnapshot.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Get-PerformanceSnapshot.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Invoke-ComputerMaintenance.ps1 ⚡ NEW!" -ForegroundColor Magenta
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/Invoke-ComputerMaintenance.ps1')" -ForegroundColor Gray
Write-Host "    (Complete maintenance: DISM, SFC, Updates, Drivers, Cleanup)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Diagnostic Plan (runs all together):" -ForegroundColor Cyan
Write-Host "  System-DiagnosticPlan.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/System/System-DiagnosticPlan.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "STORAGE UTILITIES" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Individual Tools:" -ForegroundColor Cyan
Write-Host "  Get-DiskSpaceReport.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Storage/Get-DiskSpaceReport.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Find-LargeFiles.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Storage/Find-LargeFiles.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Clear-TempFiles.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Storage/Clear-TempFiles.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "Diagnostic Plan (runs all together):" -ForegroundColor Cyan
Write-Host "  Storage-DiagnosticPlan.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Storage/Storage-DiagnosticPlan.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "SERVICES MANAGEMENT" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Individual Tools:" -ForegroundColor Cyan
Write-Host "  Get-ServiceStatus.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Get-ServiceStatus.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-FailedServices.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Get-FailedServices.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-ServiceDependencies.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Get-ServiceDependencies.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Restart-ServiceSafely.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Restart-ServiceSafely.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "Diagnostic Plan (runs all together):" -ForegroundColor Cyan
Write-Host "  Services-DiagnosticPlan.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Services/Services-DiagnosticPlan.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "SECURITY HELPERS" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Individual Tools:" -ForegroundColor Cyan
Write-Host "  Get-UserPermissions.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Get-UserPermissions.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-LocalAdminMembers.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Get-LocalAdminMembers.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-SecurityAuditReport.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Get-SecurityAuditReport.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Test-PasswordPolicy.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Test-PasswordPolicy.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Invoke-SecurityInspection.ps1 ⚡ NEW!" -ForegroundColor Magenta
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Invoke-SecurityInspection.ps1')" -ForegroundColor Gray
Write-Host "    (Complete security snapshot + anomaly detection + HTML report)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Diagnostic Plan (runs all together):" -ForegroundColor Cyan
Write-Host "  Security-DiagnosticPlan.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Security/Security-DiagnosticPlan.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "ACTIVE DIRECTORY" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Individual Tools:" -ForegroundColor Cyan
Write-Host "  Get-ADUserInfo.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/Get-ADUserInfo.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-ADGroupMembers.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/Get-ADGroupMembers.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-ADComputerStatus.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/Get-ADComputerStatus.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Test-ADReplication.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/Test-ADReplication.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "Diagnostic Plan (runs all together):" -ForegroundColor Cyan
Write-Host "  ActiveDirectory-DiagnosticPlan.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ActiveDirectory/ActiveDirectory-DiagnosticPlan.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "EXCHANGE ONLINE" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Individual Tools:" -ForegroundColor Cyan
Write-Host "  Get-MailboxInfo.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/Get-MailboxInfo.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-MailboxPermissions.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/Get-MailboxPermissions.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-DistributionGroupMembers.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/Get-DistributionGroupMembers.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-MailFlowRules.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/Get-MailFlowRules.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "Diagnostic Plan (runs all together):" -ForegroundColor Cyan
Write-Host "  ExchangeOnline-DiagnosticPlan.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/ExchangeOnline-DiagnosticPlan.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AZURE / ENTRA ID TOOLS                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-EntraUserInfo.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Get-EntraUserInfo.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-ConditionalAccessPolicies.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Get-ConditionalAccessPolicies.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-MFAStatus.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Get-MFAStatus.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-AzureSignInLogs.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Get-AzureSignInLogs.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "Diagnostic Plan (runs all together):" -ForegroundColor Cyan
Write-Host "  Azure-DiagnosticPlan.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Azure/Azure-DiagnosticPlan.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          MICROSOFT 365 / TEAMS TOOLS                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-TeamsUserInfo.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Microsoft365/Get-TeamsUserInfo.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get-SharePointSitePermissions.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Microsoft365/Get-SharePointSitePermissions.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          SQL SERVER TOOLS                                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-SQLDatabaseInfo.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/SQL/Get-SQLDatabaseInfo.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          IIS / WEB SERVER TOOLS                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-IISSiteInfo.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/IIS/Get-IISSiteInfo.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          HYPER-V TOOLS                                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-VMStatus.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/HyperV/Get-VMStatus.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          CERTIFICATE MANAGEMENT TOOLS                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-ExpiredCertificates.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Certificates/Get-ExpiredCertificates.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          GROUP POLICY TOOLS                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-GPOReport.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/GroupPolicy/Get-GPOReport.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          BACKUP & RECOVERY TOOLS                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-WindowsBackupStatus.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/Backup/Get-WindowsBackupStatus.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          NETWORK SERVICES TOOLS (DHCP/DNS)                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-DHCPScopes.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/NetworkServices/Get-DHCPScopes.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          PRINT SERVER TOOLS                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Get-PrinterStatus.ps1" -ForegroundColor Green
Write-Host "    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/PrintServer/Get-PrinterStatus.ps1')" -ForegroundColor Gray
Write-Host ""
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      HOW TO USE                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Step 1: Copy any URL from above" -ForegroundColor Green
Write-Host "Step 2: Open PowerShell" -ForegroundColor Green
Write-Host "Step 3: Paste the command:" -ForegroundColor Green
Write-Host "  iex (irm 'full-url-here')" -ForegroundColor Magenta
Write-Host "Step 4: The script will execute immediately" -ForegroundColor Green
Write-Host ""
Write-Host "Tips:" -ForegroundColor Cyan
Write-Host "  • All files are standalone - no dependencies required" -ForegroundColor Gray
Write-Host "  • Diagnostic Plans run multiple checks for complete analysis" -ForegroundColor Gray
Write-Host "  • Individual tools let you focus on specific troubleshooting" -ForegroundColor Gray
Write-Host "  • AD scripts require RSAT tools installed" -ForegroundColor Gray
Write-Host "  • Exchange scripts require ExchangeOnlineManagement module" -ForegroundColor Gray
Write-Host "  • Azure scripts require Microsoft.Graph module" -ForegroundColor Gray
Write-Host "  • Teams scripts require MicrosoftTeams module" -ForegroundColor Gray
Write-Host "  • SQL scripts require SqlServer module" -ForegroundColor Gray
Write-Host ""
