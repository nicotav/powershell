#Requires -Version 5.1
<#
.SYNOPSIS
    Lists Exchange Online mail flow rules (transport rules).

.DESCRIPTION
    This standalone snippet displays all mail flow rules with their conditions,
    actions, and status.

.EXAMPLE
    Get-MailFlowRules

.NOTES
    This is a standalone snippet. Copy and paste or use:
    iex (irm 'https://raw.githubusercontent.com/nicotav/powershell/main/Core/ExchangeOnline/Get-MailFlowRules.ps1')

    Requires: ExchangeOnlineManagement module
    Requires: Exchange Online administrator permissions
#>

function Get-MailFlowRules {
    [CmdletBinding()]
    param()

    try {
        # Check if connected
        try {
            $null = Get-OrganizationConfig -ErrorAction Stop
        }
        catch {
            Write-Host "✗ Not connected to Exchange Online" -ForegroundColor Red
            Write-Host "  Run: Connect-ExchangeOnline" -ForegroundColor Yellow
            return
        }

        Write-Host "Retrieving mail flow rules..." -ForegroundColor Cyan
        Write-Host ""

        # Get all transport rules
        $rules = Get-TransportRule | Sort-Object Priority

        if (-not $rules) {
            Write-Host "No mail flow rules found." -ForegroundColor Yellow
            return
        }

        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          MAIL FLOW RULES                                   ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Found $($rules.Count) rule(s)" -ForegroundColor Yellow
        Write-Host ""

        foreach ($rule in $rules) {
            # Rule header
            $stateColor = if ($rule.State -eq 'Enabled') { 'Green' } else { 'Yellow' }
            $stateIcon = if ($rule.State -eq 'Enabled') { '✓' } else { '○' }
            
            Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
            Write-Host "$stateIcon $($rule.Name)" -ForegroundColor $stateColor
            Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
            
            if ($rule.Description) {
                Write-Host "  Description: $($rule.Description)" -ForegroundColor Gray
            }
            Write-Host "  Priority: $($rule.Priority)" -ForegroundColor Gray
            Write-Host "  State: $($rule.State)" -ForegroundColor $stateColor
            Write-Host ""

            # Conditions
            Write-Host "  CONDITIONS:" -ForegroundColor Cyan
            $hasConditions = $false

            if ($rule.From) {
                Write-Host "    • From: $($rule.From -join ', ')" -ForegroundColor White
                $hasConditions = $true
            }
            if ($rule.SentTo) {
                Write-Host "    • Sent To: $($rule.SentTo -join ', ')" -ForegroundColor White
                $hasConditions = $true
            }
            if ($rule.SubjectContainsWords) {
                Write-Host "    • Subject Contains: $($rule.SubjectContainsWords -join ', ')" -ForegroundColor White
                $hasConditions = $true
            }
            if ($rule.FromScope) {
                Write-Host "    • From Scope: $($rule.FromScope)" -ForegroundColor White
                $hasConditions = $true
            }
            if ($rule.SentToScope) {
                Write-Host "    • Sent To Scope: $($rule.SentToScope)" -ForegroundColor White
                $hasConditions = $true
            }

            if (-not $hasConditions) {
                Write-Host "    • (All messages)" -ForegroundColor Gray
            }
            Write-Host ""

            # Actions
            Write-Host "  ACTIONS:" -ForegroundColor Yellow
            $hasActions = $false

            if ($rule.RedirectMessageTo) {
                Write-Host "    • Redirect to: $($rule.RedirectMessageTo -join ', ')" -ForegroundColor White
                $hasActions = $true
            }
            if ($rule.BlindCopyTo) {
                Write-Host "    • BCC to: $($rule.BlindCopyTo -join ', ')" -ForegroundColor White
                $hasActions = $true
            }
            if ($rule.DeleteMessage) {
                Write-Host "    • Delete message" -ForegroundColor Red
                $hasActions = $true
            }
            if ($rule.Quarantine) {
                Write-Host "    • Quarantine message" -ForegroundColor Red
                $hasActions = $true
            }
            if ($rule.SetSCL) {
                Write-Host "    • Set SCL to: $($rule.SetSCL)" -ForegroundColor White
                $hasActions = $true
            }
            if ($rule.PrependSubject) {
                Write-Host "    • Prepend subject: $($rule.PrependSubject)" -ForegroundColor White
                $hasActions = $true
            }
            if ($rule.ApplyHtmlDisclaimerText) {
                Write-Host "    • Apply disclaimer" -ForegroundColor White
                $hasActions = $true
            }

            if (-not $hasActions) {
                Write-Host "    • (No actions configured)" -ForegroundColor Gray
            }
            Write-Host ""
        }

        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

    }
    catch {
        Write-Host "✗ Error retrieving mail flow rules: $_" -ForegroundColor Red
    }
}

# Execute the function
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          EXCHANGE ONLINE MAIL FLOW RULES                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if module is available
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "✗ ExchangeOnlineManagement module not found" -ForegroundColor Red
    Write-Host "  Run: Install-Module ExchangeOnlineManagement -Force" -ForegroundColor Yellow
    exit
}

# Check if connected
try {
    $null = Get-OrganizationConfig -ErrorAction Stop
    Write-Host "✓ Connected to Exchange Online" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "✗ Not connected to Exchange Online" -ForegroundColor Red
    Write-Host ""
    $connect = Read-Host "Connect now? (y/n)"
    if ($connect -eq 'y') {
        Connect-ExchangeOnline
        Write-Host ""
    } else {
        exit
    }
}

Get-MailFlowRules
